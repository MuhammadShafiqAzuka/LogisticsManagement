import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static const _keyIsLoggedIn = 'isLoggedIn';
  static const _keyRole = 'role';
  static const _keyDriverId = 'driverId';

  static Future<void> saveLogin(String role, {String? driverId}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyRole, role);
    if (driverId != null) {
      await prefs.setString(_keyDriverId, driverId);
    }
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRole);
  }

  static Future<String?> getDriverId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyDriverId);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}