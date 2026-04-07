import 'package:shared_preferences/shared_preferences.dart';

class PreferenceHandler {
  //Inisialisasi Shared Preference
  static final PreferenceHandler _instance = PreferenceHandler._internal();
  late SharedPreferences _preferences;
  factory PreferenceHandler() => _instance;
  PreferenceHandler._internal();
  Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
  }

  //Key user
  static const String _isLogin = 'isLogin';
  static const String _token = 'token';
  static const String _userCreatedAt = 'userCreatedAt';
  static const String _isDarkMode = 'isDarkMode';

  //CREATE
  Future<void> storingIsLogin(bool isLogin) async {
    // final prefs = await SharedPreferences.getInstance();
    _preferences.setBool(_isLogin, isLogin);
  }

  Future<void> storingToken(String token) async {
    // final prefs = await SharedPreferences.getInstance();
    _preferences.setString(_token, token);
  }

  Future<void> storingUserCreatedAt(String createdAt) async {
    _preferences.setString(_userCreatedAt, createdAt);
  }

  Future<void> storingIsDarkMode(bool isDarkMode) async {
    _preferences.setBool(_isDarkMode, isDarkMode);
  }

  //GET
  static Future<bool?> getIsLogin() async {
    final prefs = await SharedPreferences.getInstance();

    var data = prefs.getBool(_isLogin);
    return data;
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();

    var data = prefs.getString(_token);
    return data;
  }

  static Future<String?> getUserCreatedAt() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userCreatedAt);
  }

  static Future<bool?> getIsDarkMode() async {
    final prefs = await SharedPreferences.getInstance();

    var data = prefs.getBool(_isDarkMode);
    return data;
  }

  //DELETE
  Future<void> deleteIsLogin() async {
    await _preferences.remove(_isLogin);
  }

  Future<void> deleteToken() async {
    await _preferences.remove(_token);
  }

  static Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_isLogin);
    await prefs.remove(_token);
    await prefs.remove(_userCreatedAt);
  }
}
