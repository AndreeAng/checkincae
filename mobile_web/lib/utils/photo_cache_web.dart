// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

const _key = 'temp_photo_base64';

Future<void> saveTempPhoto(String base64Data) async {
  html.window.localStorage[_key] = base64Data;
}

Future<String?> loadTempPhoto() async {
  return html.window.localStorage[_key];
}

Future<void> clearTempPhoto() async {
  html.window.localStorage.remove(_key);
}
