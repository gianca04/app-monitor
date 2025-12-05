import '../../domain/entities/connectivity_preferences.dart';
import '../datasources/connectivity_preferences_data_source.dart';

/// Repository for connectivity preferences
abstract class ConnectivityPreferencesRepository {
  Future<ConnectivityPreferences> getPreferences();
  Future<void> savePreferences(ConnectivityPreferences preferences);
}

/// Implementation of ConnectivityPreferencesRepository
class ConnectivityPreferencesRepositoryImpl implements ConnectivityPreferencesRepository {
  final ConnectivityPreferencesDataSource dataSource;

  ConnectivityPreferencesRepositoryImpl(this.dataSource);

  @override
  Future<ConnectivityPreferences> getPreferences() async {
    final data = await dataSource.getPreferences();
    if (data != null) {
      return ConnectivityPreferences.fromJson(data);
    }
    return const ConnectivityPreferences();
  }

  @override
  Future<void> savePreferences(ConnectivityPreferences preferences) async {
    await dataSource.savePreferences(preferences.toJson());
  }
}