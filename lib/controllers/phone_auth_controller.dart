import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../firebase/services/phone_auth_service.dart';
import '../firebase/services/realtime_db_service.dart';
import '../services/alarm_service.dart';
import '../utils/shared_prefs_helper.dart';

// ---------------------------------------------------------------------------
// State sealed classes
// ---------------------------------------------------------------------------

sealed class PhoneAuthState {
  const PhoneAuthState();
}

class PhoneAuthIdle extends PhoneAuthState {
  const PhoneAuthIdle();
}

class PhoneAuthLoading extends PhoneAuthState {
  const PhoneAuthLoading();
}

class PhoneAuthOtpSent extends PhoneAuthState {
  const PhoneAuthOtpSent(this.phoneNumber);
  final String phoneNumber;
}

class PhoneAuthSuccess extends PhoneAuthState {
  const PhoneAuthSuccess({required this.uid, required this.phoneNumber});
  final String uid;
  final String phoneNumber;
}

class PhoneAuthError extends PhoneAuthState {
  const PhoneAuthError(this.message);
  final String message;
}

// ---------------------------------------------------------------------------
// Controller  (Notifier — compatible with flutter_riverpod ^3.x)
// ---------------------------------------------------------------------------

/// Orchestrates the entire phone-auth flow:
/// 1. Send OTP  2. Verify OTP  3. Get deviceId + appVersion
/// 4. Save/update Realtime DB  5. Persist SharedPrefs
class PhoneAuthController extends Notifier<PhoneAuthState> {
  late PhoneAuthService _auth;
  late RealtimeDbService _db;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  @override
  PhoneAuthState build() {
    _auth = PhoneAuthService();
    _db = RealtimeDbService();
    return const PhoneAuthIdle();
  }

  // ── Send OTP ──────────────────────────────────────────────────────────────

  Future<void> sendOtp(String phoneNumber) async {
    final trimmed = phoneNumber.trim();
    if (trimmed.isEmpty) {
      state = const PhoneAuthError('Please enter your phone number.');
      return;
    }
    if (!RegExp(r'^\+[1-9]\d{6,14}$').hasMatch(trimmed)) {
      state = const PhoneAuthError(
        'Enter a valid phone number with country code (e.g. +919876543210).',
      );
      return;
    }
    state = const PhoneAuthLoading();
    await _auth.sendOtp(
      phoneNumber: trimmed,
      onCodeSent: () => state = PhoneAuthOtpSent(trimmed),
      onError: (msg) => state = PhoneAuthError(msg),
      onAutoVerified: (PhoneAuthCredential cred) async {
        final result = await _auth.signInWithCredential(cred);
        await _handleCredential(result, trimmed);
      },
    );
  }

  // ── Verify OTP ────────────────────────────────────────────────────────────

  Future<void> verifyOtp({
    required String otp,
    required String phoneNumber,
  }) async {
    if (otp.trim().length < 6) {
      state = const PhoneAuthError('Please enter the 6-digit OTP.');
      return;
    }
    state = const PhoneAuthLoading();
    try {
      final credential = await _auth.verifyOtp(otp);
      await _handleCredential(credential, phoneNumber);
    } catch (e) {
      state = PhoneAuthError(e.toString());
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  Future<void> logout({String? phoneNumber}) async {
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      await _db.updateStatus(phoneNumber, 'inactive');
    }
    await AlarmService.cancelAll();
    await _auth.signOut();
    await SharedPrefsHelper.clearLoginState();
    state = const PhoneAuthIdle();
  }

  // ── Reset ─────────────────────────────────────────────────────────────────

  void reset() => state = const PhoneAuthIdle();

  // ── Post-credential steps ─────────────────────────────────────────────────

  Future<void> _handleCredential(
    UserCredential credential,
    String phoneNumber,
  ) async {
    try {
      final uid = credential.user!.uid;
      final deviceId = await _getDeviceId();
      final appVersion = await _getAppVersion();
      await _db.saveOrUpdateUser(
        phone: phoneNumber,
        uid: uid,
        deviceId: deviceId,
        appVersion: appVersion,
      );
      await SharedPrefsHelper.saveLoginState(phone: phoneNumber, uid: uid);
      state = PhoneAuthSuccess(uid: uid, phoneNumber: phoneNumber);
    } catch (e) {
      state = PhoneAuthError('Login succeeded but failed to save session: $e');
    }
  }

  // ── Device ID ─────────────────────────────────────────────────────────────

  Future<String> _getDeviceId() async {
    try {
      if (kIsWeb) return 'web';
      if (Platform.isAndroid) {
        final info = await _deviceInfo.androidInfo;
        return info.id; // Android Build.ID
      }
      if (Platform.isIOS) {
        final info = await _deviceInfo.iosInfo;
        return info.identifierForVendor ?? 'ios-unknown';
      }
      return 'unknown';
    } catch (_) {
      return 'unknown';
    }
  }

  // ── App version ───────────────────────────────────────────────────────────

  Future<String> _getAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return info.version;
    } catch (_) {
      return '0.0.0';
    }
  }
}

// ---------------------------------------------------------------------------
// Riverpod provider  (NotifierProvider — riverpod ^3.x)
// ---------------------------------------------------------------------------

final phoneAuthControllerProvider =
    NotifierProvider<PhoneAuthController, PhoneAuthState>(
      PhoneAuthController.new,
    );
