import 'package:shared_preferences/shared_preferences.dart';

/// Keys used in [SharedPreferences] for phone-auth login state.
abstract class _Keys {
  static const String isLoggedIn = 'isLoggedIn';
  static const String phoneNumber = 'phoneNumber';
  static const String firebaseUID = 'firebaseUID';
}

/// Helper that stores and retrieves phone-auth login state locally.
///
/// Usage:
/// ```dart
/// await SharedPrefsHelper.saveLoginState(phone: '+919876543210', uid: 'xyz');
/// final loggedIn = await SharedPrefsHelper.isLoggedIn(); // true
/// await SharedPrefsHelper.clearLoginState(); // on logout
/// ```
class SharedPrefsHelper {
  SharedPrefsHelper._(); // static-only class

  // ---------------------------------------------------------------------------
  // Write
  // ---------------------------------------------------------------------------

  /// Persists login state after successful phone OTP verification.
  static Future<void> saveLoginState({
    required String phone,
    required String uid,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_Keys.isLoggedIn, true);
    await prefs.setString(_Keys.phoneNumber, phone);
    await prefs.setString(_Keys.firebaseUID, uid);
  }

  // ---------------------------------------------------------------------------
  // Read
  // ---------------------------------------------------------------------------

  /// Returns `true` when the user has a persisted phone-auth session.
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_Keys.isLoggedIn) ?? false;
  }

  /// Returns the stored phone number, or null.
  static Future<String?> getPhoneNumber() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_Keys.phoneNumber);
  }

  /// Returns the stored Firebase UID, or null.
  static Future<String?> getFirebaseUID() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_Keys.firebaseUID);
  }

  /// Returns all stored login fields at once. Any field may be null.
  static Future<({bool loggedIn, String? phone, String? uid})>
      getLoginState() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      loggedIn: prefs.getBool(_Keys.isLoggedIn) ?? false,
      phone: prefs.getString(_Keys.phoneNumber),
      uid: prefs.getString(_Keys.firebaseUID),
    );
  }

  // ---------------------------------------------------------------------------
  // Clear
  // ---------------------------------------------------------------------------

  /// Removes all phone-auth login keys (called on logout).
  static Future<void> clearLoginState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_Keys.isLoggedIn);
    await prefs.remove(_Keys.phoneNumber);
    await prefs.remove(_Keys.firebaseUID);
  }
}
