import 'app_storage.dart';

class _StubStorage implements AppStorage {
  @override
  Future<String?> read(String key) async => null;

  @override
  Future<void> write(String key, String value) async {}

  @override
  Future<void> delete(String key) async {}
}

final AppStorage storageInstance = _StubStorage();
