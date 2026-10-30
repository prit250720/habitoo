import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../services/alarm_service.dart';

/// Wraps [FirebaseAuth], [FirebaseFirestore], and [FirebaseDatabase] to
/// provide a clean auth API.
///
/// All [FirebaseAuthException] codes are caught and converted into
/// human-readable messages suitable for display in the UI.
class AuthRepository {
  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseDatabase? database,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       // Always use the explicit URL — FirebaseDatabase.instance does NOT
       // reliably pick up databaseURL from google-services.json on all SDK
       // versions, which causes writes to silently go to the wrong endpoint.
       _database =
           database ??
           FirebaseDatabase.instanceFor(
             app: FirebaseAuth.instance.app,
             databaseURL: 'https://habitoo-fb165-default-rtdb.firebaseio.com',
           );

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseDatabase _database;

  // ---------------------------------------------------------------------------
  // Auth state
  // ---------------------------------------------------------------------------

  /// Emits the current [User] on subscription and again on every sign-in /
  /// sign-out event. Emits `null` when no user is authenticated.
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  // ---------------------------------------------------------------------------
  // Sign-up
  // ---------------------------------------------------------------------------

  /// Creates a new Firebase Auth user, a matching Firestore document at
  /// `users/{uid}`, and a Realtime Database record at `users/{uid}`.
  ///
  /// The Auth + Firestore steps are atomic from the caller's perspective —
  /// failure throws a human-readable [String].
  /// The RTDB write runs after those succeed; its failure is logged but does
  /// NOT prevent the sign-up from completing (so the user is never left in
  /// a broken state).
  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    // ── Step 1: Create Firebase Auth account ─────────────────────────────
    late UserCredential credential;
    try {
      credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _authErrorMessage(e.code);
    } catch (e) {
      throw 'Sign-up failed. Please try again.';
    }

    final uid = credential.user!.uid;

    // Set displayName on the Auth profile so signIn can read it back.
    try {
      await credential.user!.updateDisplayName(name);
    } catch (_) {}

    // ── Step 2: Write Firestore user profile ─────────────────────────────
    try {
      await _firestore.collection('users').doc(uid).set({
        'name': name,
        'email': email,
        'avatarUrl': '',
        'level': 1,
        'xp': 0,
        'badges': <String>[],
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Non-fatal — auth succeeded, continue.
    }

    // ── Step 3: Write Realtime Database record ────────────────────────────
    await _writeRtdbRecord(
      uid: uid,
      email: email,
      name: name,
      photoUrl: credential.user?.photoURL,
      phoneNumber: credential.user?.phoneNumber,
      isNewUser: true,
      user:
          credential.user, // pass directly — _auth.currentUser may be null here
    );

    return credential;
  }

  // ---------------------------------------------------------------------------
  // Sign-in
  // ---------------------------------------------------------------------------

  /// Signs in an existing user with email and password and updates lastLogin
  /// in Realtime Database.
  ///
  /// Throws a [String] with a human-readable message on failure.
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    late UserCredential credential;
    try {
      credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _authErrorMessage(e.code);
    } catch (e) {
      throw 'Sign-in failed. Please try again.';
    }

    final uid = credential.user!.uid;

    // Update last-login in RTDB. On first login after an old sign-up that
    // missed the RTDB write, this will create the full record instead of
    // just updating four fields.
    await _writeRtdbRecord(
      uid: uid,
      email: email,
      name: credential.user?.displayName ?? '',
      photoUrl: credential.user?.photoURL,
      phoneNumber: credential.user?.phoneNumber,
      isNewUser: false,
    );

    return credential;
  }

  // ---------------------------------------------------------------------------
  // Sign-out
  // ---------------------------------------------------------------------------

  /// Signs out the current user.
  Future<void> signOut() async {
    try {
      await AlarmService.cancelAll();
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      throw _authErrorMessage(e.code);
    } catch (e) {
      throw 'Something went wrong. Please try again.';
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Writes or updates a user record in the Realtime Database under
  /// `users/{uid}`.
  ///
  /// When [isNewUser] is `true` (sign-up), the full profile is written with
  /// `.set()` so no field is missing.
  ///
  /// When [isNewUser] is `false` (sign-in), the node is read first:
  /// - If it does not exist yet (e.g. old account missing RTDB record), the
  ///   full profile is created.
  /// - If it exists, only mutable fields (`lastLogin`, `deviceId`,
  ///   `appVersion`, `status`) are updated so immutable fields like
  ///   `createdAt` and `role` are never overwritten.
  ///
  /// Errors are logged and never rethrown — a RTDB failure must not block
  /// the auth flow.
  Future<void> _writeRtdbRecord({
    required String uid,
    required String email,
    required String name,
    String? photoUrl,
    String? phoneNumber,
    bool isNewUser = false,
    User?
    user, // pass credential.user directly on sign-up so token refresh works
  }) async {
    try {
      final appVersion = await _getAppVersion();
      final deviceId = await _getDeviceId();
      final ref = _database.ref('users/$uid');

      // Use the user object passed in (from credential.user) — on sign-up
      // _auth.currentUser may still be null when this runs, so we must use
      // the credential's user directly to get a valid ID token.
      final authUser = user ?? _auth.currentUser;
      try {
        await authUser?.getIdToken(true);
      } catch (_) {}

      if (isNewUser) {
        // Full write on sign-up — every field present from day one.
        final newRecord = <String, Object?>{
          'uid': uid,
          'name': name,
          'email': email,
          'phoneNumber': phoneNumber ?? '',
          'photoUrl': photoUrl ?? '',
          'role': 'user',
          'status': 'active',
          'deviceId': deviceId,
          'appVersion': appVersion,
          'createdAt': ServerValue.timestamp,
          'lastLogin': ServerValue.timestamp,
        };
        await ref.set(newRecord);
      } else {
        // Sign-in path: create the record if missing, otherwise update.
        final snapshot = await ref.get();
        if (!snapshot.exists) {
          await ref.set(<String, Object?>{
            'uid': uid,
            'name': name,
            'email': email,
            'phoneNumber': phoneNumber ?? '',
            'photoUrl': photoUrl ?? '',
            'role': 'user',
            'status': 'active',
            'deviceId': deviceId,
            'appVersion': appVersion,
            'createdAt': ServerValue.timestamp,
            'lastLogin': ServerValue.timestamp,
          });
        } else {
          // Record exists — update only the mutable session fields.
          await ref.update(
            <String, Object?>{
              'lastLogin': ServerValue.timestamp,
              'deviceId': deviceId,
              'appVersion': appVersion,
              'status': 'active',
              'name': name.isNotEmpty ? name : null,
              'email': email.isNotEmpty ? email : null,
              'phoneNumber': phoneNumber ?? '',
              'photoUrl': photoUrl ?? '',
            }..removeWhere((_, v) => v == null),
          );
        }
      }
    } catch (e, _) {
      // Error logged but never rethrown so auth is never blocked.
    }
  }

  /// Maps a [FirebaseAuthException.code] to a UI-friendly message.
  String _authErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'user-not-found':
        return 'No account found for this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }

  Future<String> _getAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return info.version;
    } catch (_) {
      return '0.0.0';
    }
  }

  Future<String> _getDeviceId() async {
    try {
      if (kIsWeb) return 'web';
      final plugin = DeviceInfoPlugin();
      if (defaultTargetPlatform == TargetPlatform.android) {
        final info = await plugin.androidInfo;
        return info.id;
      }
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final info = await plugin.iosInfo;
        return info.identifierForVendor ?? 'ios-unknown';
      }
      return 'unknown';
    } catch (_) {
      return 'unknown';
    }
  }
}
