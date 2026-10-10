import 'package:shared_preferences/shared_preferences.dart';

abstract class LocalStore {
  String? read(String key);
  Future<void> write(String key, String value);
}

class PreferencesStore implements LocalStore {
  PreferencesStore(this.preferences);
  final SharedPreferences preferences;
  @override
  String? read(String key) => preferences.getString(key);
  @override
  Future<void> write(String key, String value) async {
    final saved = await preferences.setString(key, value);
    if (!saved) throw StateError('Local storage is unavailable.');
  }
}

class MemoryStore implements LocalStore {
  final Map<String, String> values = {};
  @override
  String? read(String key) => values[key];
  @override
  Future<void> write(String key, String value) async => values[key] = value;
}
