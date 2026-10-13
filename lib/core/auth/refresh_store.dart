import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class RefreshStore {
  bool get persistent;
  Future<String?> read();
  Future<void> write(String token);
  Future<void> delete();
}

class MemoryRefreshStore implements RefreshStore {
  String? _value;
  @override
  bool get persistent => false;
  @override
  Future<String?> read() async => _value;
  @override
  Future<void> write(String token) async {
    _value = token;
  }

  @override
  Future<void> delete() async {
    _value = null;
  }
}

class NativeRefreshStore implements RefreshStore {
  static const key = 'eastalya.refresh.v1';
  final FlutterSecureStorage storage;
  NativeRefreshStore({FlutterSecureStorage? storage})
    : storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(storageNamespace: 'eastalya_auth'),
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.unlocked_this_device,
            ),
          );
  @override
  bool get persistent => true;
  @override
  Future<String?> read() => storage.read(key: key);
  @override
  Future<void> write(String token) => storage.write(key: key, value: token);
  @override
  Future<void> delete() => storage.delete(key: key);
}

RefreshStore createRefreshStore() =>
    kIsWeb ? MemoryRefreshStore() : NativeRefreshStore();
