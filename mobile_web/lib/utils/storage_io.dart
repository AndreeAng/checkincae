import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'app_storage.dart';

class _SecureStorage implements AppStorage {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

final AppStorage storageInstance = _SecureStorage();
