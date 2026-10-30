import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

/// Wraps [FirebaseDatabase] to manage the `users/{phone}` node.
class RealtimeDbService {
  RealtimeDbService({FirebaseDatabase? database})
      : _db = database ??
            FirebaseDatabase.instanceFor(
              app: FirebaseAuth.instance.app,
              databaseURL:
                  'https://habitoo-fb165-default-rtdb.firebaseio.com',
            );

  final FirebaseDatabase _db;

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  /// Strips the leading '+' and any spaces from a phone number to use as key.
  /// e.g. "+91 9876543210" → "919876543210"
  static String phoneToKey(String phone) =>
      phone.replaceAll('+', '').replaceAll(' ', '').trim();

  DatabaseReference _userRef(String phone) =>
      _db.ref('users/${phoneToKey(phone)}');

  // ---------------------------------------------------------------------------
  // Check duplicate
  // ---------------------------------------------------------------------------

  /// Returns `true` when a record for [phone] already exists in the DB.
  Future<bool> userExists(String phone) async {
    try {
      final snapshot = await _userRef(phone).get();
      return snapshot.exists;
    } catch (_) {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Save or update
  // ---------------------------------------------------------------------------

  /// Creates a new user record or updates an existing one.
  ///
  /// If the record **does not exist**, writes the full payload including
  /// `createdAt`.
  /// If the record **already exists**, updates only `lastLogin`, `deviceId`,
  /// `appVersion`, and `status`.
  Future<void> saveOrUpdateUser({
    required String phone,
    required String uid,
    required String deviceId,
    required String appVersion,
    String status = 'active',
  }) async {
    final ref = _userRef(phone);

    try {
      final snapshot = await ref.get();

      if (snapshot.exists) {
        // ── Update existing record ─────────────────────────────────────────
        await ref.update(<String, Object>{
          'lastLogin': ServerValue.timestamp,
          'deviceId': deviceId,
          'appVersion': appVersion,
          'status': status,
        });
      } else {
        // ── Create new record ──────────────────────────────────────────────
        await ref.set(<String, Object>{
          'phone': phone,
          'uid': uid,
          'deviceId': deviceId,
          'createdAt': ServerValue.timestamp,
          'lastLogin': ServerValue.timestamp,
          'appVersion': appVersion,
          'status': status,
        });
      }
    } catch (e) {
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Read user
  // ---------------------------------------------------------------------------

  /// Reads a single snapshot for [phone] and returns it as a [Map], or null.
  Future<Map<String, dynamic>?> getUser(String phone) async {
    try {
      final snapshot = await _userRef(phone).get();
      if (!snapshot.exists) return null;
      return Map<String, dynamic>.from(snapshot.value as Map);
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Update status
  // ---------------------------------------------------------------------------

  /// Marks a user as [status] (e.g. "inactive" on logout).
  Future<void> updateStatus(String phone, String status) async {
    try {
      await _userRef(phone).update({'status': status});
    } catch (_) {}
  }
}
