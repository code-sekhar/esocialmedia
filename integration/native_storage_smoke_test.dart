// Dedicated-device smoke; does not attest backup, restoration or release signing.
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('real dedicated native storage write/read/delete', (
    tester,
  ) async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      fail('RELEASE BLOCKED: actual Android/iOS required');
    }
    final random = Random.secure();
    final nonce = List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    final key = 'eastalya.release.check.$nonce';
    final value = List.generate(
      64,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    const storage = FlutterSecureStorage(
      aOptions: AndroidOptions(storageNamespace: 'eastalya_release_check'),
      iOptions: IOSOptions(
        accountName: 'eastalya_release_check',
        accessibility: KeychainAccessibility.unlocked_this_device,
      ),
    );
    try {
      await storage.write(key: key, value: value);
      expect(await storage.read(key: key), value);
      await storage.delete(key: key);
      expect(await storage.read(key: key), isNull);
    } finally {
      await storage.delete(key: key);
    }
  });
}
