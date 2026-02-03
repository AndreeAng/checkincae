// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'app_storage.dart';

class _WebStorage implements AppStorage {
  @override
  Future<String?> read(String key) async {
    return html.window.localStorage[key];
  }

  @override
  Future<void> write(String key, String value) async {
    html.window.localStorage[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    html.window.localStorage.remove(key);
  }
}

final AppStorage storageInstance = _WebStorage();
