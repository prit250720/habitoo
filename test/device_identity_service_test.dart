import 'package:flutter_test/flutter_test.dart';
import 'package:habitoo/services/device_identity_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('persists a device id and sends it to the identity sink', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final payloads = <Map<String, Object?>>[];
    final service = DeviceIdentityService(
      preferences: prefs,
      writeDeviceIdentity: (deviceId, platform, payload) async {
        payloads.add({'deviceId': deviceId, 'platform': platform, ...payload});
      },
    );

    final deviceId = await service.initializeDeviceIdentity();

    expect(deviceId, isNotEmpty);
    expect(prefs.getString('device_uuid'), deviceId);
    expect(payloads, hasLength(1));
    expect(payloads.single['deviceId'], deviceId);
    expect(payloads.single['platform'], isA<String>());
    expect(payloads.single['authMode'], 'anonymous');
    expect(payloads.single['isGuest'], true);
  });
}
