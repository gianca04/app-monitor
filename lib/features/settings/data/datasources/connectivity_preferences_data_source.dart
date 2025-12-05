import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Data source for connectivity preferences using SharedPreferences
abstract class ConnectivityPreferencesDataSource {
  Future<Map<String, dynamic>?> getPreferences();
  Future<void> savePreferences(Map<String, dynamic> preferences);
}

/// Implementation of ConnectivityPreferencesDataSource
class ConnectivityPreferencesDataSourceImpl implements ConnectivityPreferencesDataSource {
  static const String _key = 'connectivity_preferences';

  @override
  Future<Map<String, dynamic>?> getPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    if (data != null) {
      return json.decode(data) as Map<String, dynamic>;
    }
    return null;
  }

  @override
  Future<void> savePreferences(Map<String, dynamic> preferences) async {
    final prefs = await SharedPreferences.getInstance();
    final data = json.encode(preferences);
    await prefs.setString(_key, data);
  }
}