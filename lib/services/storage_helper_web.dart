import 'dart:html' as html;

class StorageHelper {
  static String? read(String key) {
    try {
      return html.window.localStorage[key];
    } catch (_) {
      return null;
    }
  }

  static void write(String key, String value) {
    try {
      html.window.localStorage[key] = value;
    } catch (_) {}
  }
}
