import 'package:firebase_auth/firebase_auth.dart';

/// Wraps [FirebaseAuth] phone authentication (send OTP + verify OTP).
///
/// Keeps verification state in-memory so the controller can call
/// [verifyOtp] after [sendOtp] completes.
class PhoneAuthService {
  PhoneAuthService({FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  // Stored by [verificationCompleted] / [codeSent] callbacks.
  String? _verificationId;
  int? _resendToken;

  // ---------------------------------------------------------------------------
  // Send OTP
  // ---------------------------------------------------------------------------

  /// Sends an OTP SMS to [phoneNumber] (E.164 format, e.g. "+919876543210").
  ///
  /// [onCodeSent]     — called when the code has been dispatched.
  /// [onError]        — called with a human-readable message on failure.
  /// [onAutoVerified] — called with the credential when Android auto-verifies.
  Future<void> sendOtp({
    required String phoneNumber,
    required void Function() onCodeSent,
    required void Function(String message) onError,
    void Function(PhoneAuthCredential credential)? onAutoVerified,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: timeout,
      forceResendingToken: _resendToken,

      verificationCompleted: (PhoneAuthCredential credential) {
        onAutoVerified?.call(credential);
      },

      // ── Verification failed ──────────────────────────────────────────────
      verificationFailed: (FirebaseAuthException e) {
        onError(_mapError(e.code));
      },

      // ── Code sent ────────────────────────────────────────────────────────
      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        _resendToken = resendToken;
        onCodeSent();
      },

      // ── Timeout ──────────────────────────────────────────────────────────
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Verify OTP
  // ---------------------------------------------------------------------------

  /// Verifies [otp] and signs the user in.
  ///
  /// Returns the [UserCredential] on success.
  /// Throws a [String] with a human-readable message on failure.
  Future<UserCredential> verifyOtp(String otp) async {
    if (_verificationId == null) {
      throw 'No verification in progress. Please request a new OTP.';
    }

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp.trim(),
      );
      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _mapError(e.code);
    } catch (_) {
      throw 'Something went wrong. Please try again.';
    }
  }

  // ---------------------------------------------------------------------------
  // Sign-in with pre-built credential (auto-verify path)
  // ---------------------------------------------------------------------------

  /// Signs in directly with an already-built [PhoneAuthCredential].
  Future<UserCredential> signInWithCredential(
      PhoneAuthCredential credential) async {
    try {
      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _mapError(e.code);
    } catch (_) {
      throw 'Something went wrong. Please try again.';
    }
  }

  // ---------------------------------------------------------------------------
  // Sign-out
  // ---------------------------------------------------------------------------

  /// Signs out the current Firebase user.
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (_) {
      // Best-effort; local session will still be cleared by SharedPrefs.
    }
  }

  // ---------------------------------------------------------------------------
  // Current user helpers
  // ---------------------------------------------------------------------------

  /// Returns the currently signed-in [User], or null.
  User? get currentUser => _auth.currentUser;

  /// Stream of auth state changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ---------------------------------------------------------------------------
  // Error mapping
  // ---------------------------------------------------------------------------

  String _mapError(String code) {
    switch (code) {
      case 'invalid-phone-number':
        return 'The phone number is not valid. Include country code (e.g. +91).';
      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again.';
      case 'invalid-verification-code':
        return 'The OTP you entered is incorrect. Please check and retry.';
      case 'session-expired':
        return 'The OTP has expired. Please request a new one.';
      case 'quota-exceeded':
        return 'SMS quota exceeded. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      case 'user-disabled':
        return 'This account has been disabled.';
      default:
        return 'Authentication failed ($code). Please try again.';
    }
  }
}
