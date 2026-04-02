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

  //CREATE
  Future<void> storingIsLogin(bool isLogin) async {
    // final prefs = await SharedPreferences.getInstance();
    _preferences.setBool(_isLogin, isLogin);
  }

  Future<void> storingToken(String token) async {
    // final prefs = await SharedPreferences.getInstance();
    _preferences.setString(_token, token);
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
  }
}
