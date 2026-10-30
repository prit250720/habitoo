import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceIdentityService {
  DeviceIdentityService({
    SharedPreferences? preferences,
    FirebaseDatabase? database,
    Uuid? uuidGenerator,
    DeviceInfoPlugin? deviceInfoPlugin,
    Future<void> Function(
      String deviceId,
      String platform,
      Map<String, Object?> payload,
    )?
    writeDeviceIdentity,
  }) : _preferences = preferences,
       _database = database,
       _uuidGenerator = uuidGenerator ?? const Uuid(),
       _deviceInfoPlugin = deviceInfoPlugin,
       _writeDeviceIdentity = writeDeviceIdentity;

  final SharedPreferences? _preferences;
  final FirebaseDatabase? _database;
  final Uuid _uuidGenerator;
  final DeviceInfoPlugin? _deviceInfoPlugin;
  final Future<void> Function(
    String deviceId,
    String platform,
    Map<String, Object?> payload,
  )?
  _writeDeviceIdentity;

  FirebaseDatabase get _databaseInstance =>
      _database ?? FirebaseDatabase.instance;

  static const String _storageKey = 'device_uuid';

  Future<String> initializeDeviceIdentity() async {
    final prefs = _preferences ?? await SharedPreferences.getInstance();

    String deviceId = prefs.getString(_storageKey) ?? '';
    if (deviceId.isEmpty) {
      deviceId = await _resolveDeviceId();
      await prefs.setString(_storageKey, deviceId);
    }

    final platform = defaultTargetPlatform.name;
    final deviceDetails = await _getDeviceDetails();
    final payload = <String, Object?>{
      'deviceId': deviceId,
      'createdAt': ServerValue.timestamp,
      'lastSeenAt': ServerValue.timestamp,
      'platform': platform,
      'authMode': 'anonymous',
      'isGuest': true,
      ...deviceDetails,
    };

    try {
      if (_writeDeviceIdentity != null) {
        await _writeDeviceIdentity(deviceId, platform, payload);
      } else {
        await _ensureAnonymousAuthentication();
        await _registerDevice(deviceId, payload);
      }
    } catch (error) {
      // ignore: device info unavailable
    }

    return deviceId;
  }

  Future<void> _registerDevice(
    String deviceId,
    Map<String, Object?> payload,
  ) async {
    final deviceRef = _databaseInstance.ref().child('devices').child(deviceId);
    final response = await deviceRef.get();

    if (response.exists) {
      await deviceRef.update(<String, Object?>{
        'lastSeenAt': ServerValue.timestamp,
      });
    } else {
      await deviceRef.set(payload);
    }
  }

  Future<Map<String, Object?>> _getDeviceDetails() async {
    if (_deviceInfoPlugin == null) {
      return <String, Object?>{};
    }

    try {
      if (kIsWeb) {
        final webInfo = await _deviceInfoPlugin.webBrowserInfo;
        return <String, Object?>{
          'deviceName': webInfo.userAgent,
          'deviceModel': webInfo.vendor,
          'osVersion': webInfo.appVersion,
          'deviceIdentifierSource': 'webBrowser',
        };
      }

      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfoPlugin.androidInfo;
        return <String, Object?>{
          'deviceName': androidInfo.device,
          'deviceModel': androidInfo.model,
          'manufacturer': androidInfo.manufacturer,
          'osVersion': 'Android ${androidInfo.version.release}',
          'deviceIdentifierSource': 'androidId',
        };
      }

      if (Platform.isIOS) {
        final iosInfo = await _deviceInfoPlugin.iosInfo;
        return <String, Object?>{
          'deviceName': iosInfo.name,
          'deviceModel': iosInfo.utsname.machine,
          'manufacturer': 'Apple',
          'osVersion': '${iosInfo.systemName} ${iosInfo.systemVersion}',
          'deviceIdentifierSource': 'identifierForVendor',
        };
      }

      if (Platform.isLinux) {
        final linuxInfo = await _deviceInfoPlugin.linuxInfo;
        return <String, Object?>{
          'deviceName': linuxInfo.name,
          'deviceModel': linuxInfo.prettyName,
          'manufacturer': linuxInfo.id,
          'osVersion': linuxInfo.version,
          'deviceIdentifierSource': 'machineId',
        };
      }

      if (Platform.isWindows) {
        final windowsInfo = await _deviceInfoPlugin.windowsInfo;
        return <String, Object?>{
          'deviceName': windowsInfo.computerName,
          'deviceModel': windowsInfo.computerName,
          'manufacturer': 'Microsoft',
          'osVersion':
              '${windowsInfo.majorVersion}.${windowsInfo.minorVersion}',
          'deviceIdentifierSource': 'deviceId',
        };
      }

      if (Platform.isMacOS) {
        final macInfo = await _deviceInfoPlugin.macOsInfo;
        return <String, Object?>{
          'deviceName': macInfo.computerName,
          'deviceModel': macInfo.model,
          'manufacturer': 'Apple',
          'osVersion': macInfo.osRelease,
          'deviceIdentifierSource': 'computerName',
        };
      }
    } catch (_) {
      // ignore: device info unavailable
    }

    return <String, Object?>{};
  }

  Future<String> _resolveDeviceId() async {
    if (_deviceInfoPlugin == null) {
      return _uuidGenerator.v4();
    }

    try {
      if (kIsWeb) {
        final webInfo = await _deviceInfoPlugin.webBrowserInfo;
        final browserId = webInfo.userAgent ?? webInfo.vendor;
        return browserId?.isNotEmpty == true ? browserId! : _uuidGenerator.v4();
      }

      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfoPlugin.androidInfo;
        return androidInfo.id.isNotEmpty ? androidInfo.id : _uuidGenerator.v4();
      }

      if (Platform.isIOS) {
        final iosInfo = await _deviceInfoPlugin.iosInfo;
        final iosId = iosInfo.identifierForVendor;
        return iosId?.isNotEmpty == true ? iosId! : _uuidGenerator.v4();
      }

      if (Platform.isLinux) {
        final linuxInfo = await _deviceInfoPlugin.linuxInfo;
        final linuxId = linuxInfo.machineId;
        return linuxId?.isNotEmpty == true ? linuxId! : _uuidGenerator.v4();
      }

      if (Platform.isWindows) {
        final windowsInfo = await _deviceInfoPlugin.windowsInfo;
        final windowsId = windowsInfo.deviceId;
        final windowsName = windowsInfo.computerName;
        return windowsId.isNotEmpty
            ? windowsId
            : windowsName.isNotEmpty
            ? windowsName
            : _uuidGenerator.v4();
      }

      if (Platform.isMacOS) {
        final macInfo = await _deviceInfoPlugin.macOsInfo;
        final macHost = macInfo.hostName;
        final macComputer = macInfo.computerName;
        return macHost.isNotEmpty
            ? macHost
            : macComputer.isNotEmpty
            ? macComputer
            : _uuidGenerator.v4();
      }
    } catch (_) {
      // ignore: device id unavailable
    }

    return _uuidGenerator.v4();
  }

  Future<void> _ensureAnonymousAuthentication() async {
    final auth = FirebaseAuth.instance;
    if (auth.currentUser == null) {
      await auth.signInAnonymously();
    }
  }
}
