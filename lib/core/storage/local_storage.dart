import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static const _keyDriverId = 'driverId';

  /// Save driverId for quick access
  static Future<void> saveDriverId(String driverId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDriverId, driverId);
  }

  static Future<String?> getDriverId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyDriverId);
  }

  static String? getDriverIdSync() {
    // optional convenience sync getter (use carefully)
    final prefs = SharedPreferences.getInstance();
    return prefs.then((p) => p.getString(_keyDriverId)) as String?;
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}