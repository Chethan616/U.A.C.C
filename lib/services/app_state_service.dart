import 'package:shared_preferences/shared_preferences.dart';

class AppStateService {
  static const String _keyFirstLaunch = 'first_launch';
  static const String _keyOnboardingCompleted = 'onboarding_completed';
  static const String _keyUserLoggedIn = 'user_logged_in';
  static const String _keyLastUserId = 'last_user_id';

  static AppStateService? _instance;
  static AppStateService get instance => _instance ??= AppStateService._();
  AppStateService._();

  SharedPreferences? _prefs;

  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // First Launch Management
  Future<bool> isFirstLaunch() async {
    await initialize();
    return _prefs?.getBool(_keyFirstLaunch) ?? true;
  }

  Future<void> setFirstLaunchCompleted() async {
    await initialize();
    await _prefs?.setBool(_keyFirstLaunch, false);
  }

  // Onboarding Management
  Future<bool> isOnboardingCompleted() async {
    await initialize();
    return _prefs?.getBool(_keyOnboardingCompleted) ?? false;
  }

  Future<void> setOnboardingCompleted() async {
    await initialize();
    await _prefs?.setBool(_keyOnboardingCompleted, true);
  }

  // User Login State
  Future<bool> isUserLoggedIn() async {
    await initialize();
    return _prefs?.getBool(_keyUserLoggedIn) ?? false;
  }

  Future<void> setUserLoggedIn(bool isLoggedIn, [String? userId]) async {
    await initialize();
    await _prefs?.setBool(_keyUserLoggedIn, isLoggedIn);
    if (userId != null) {
      await _prefs?.setString(_keyLastUserId, userId);
    } else if (!isLoggedIn) {
      await _prefs?.remove(_keyLastUserId);
    }
  }

  Future<String?> getLastUserId() async {
    await initialize();
    return _prefs?.getString(_keyLastUserId);
  }

  // Clear all app state (for logout/reset)
  Future<void> clearAllState() async {
    await initialize();
    await _prefs?.clear();
  }

  // Reset only user-specific state (keep onboarding status)
  Future<void> clearUserState() async {
    await initialize();
    await _prefs?.remove(_keyUserLoggedIn);
    await _prefs?.remove(_keyLastUserId);

    // Also clear any other user-specific keys that might exist
    final keys = _prefs?.getKeys() ?? <String>{};
    for (final key in keys) {
      if (key.startsWith('user_') ||
          key.startsWith('profile_') ||
          key.startsWith('cache_') ||
          key.contains('_uid_')) {
        await _prefs?.remove(key);
      }
    }
  }

  // Clear authentication state completely (for account switching)
  Future<void> clearAuthenticationState() async {
    await initialize();
    await _prefs?.remove(_keyUserLoggedIn);
    await _prefs?.remove(_keyLastUserId);

    // Clear all cached data but keep onboarding status
    final keys = _prefs?.getKeys() ?? <String>{};
    for (final key in keys) {
      if (key != _keyFirstLaunch && key != _keyOnboardingCompleted) {
        await _prefs?.remove(key);
      }
    }
  }

  // Check if current user matches stored user (for account switching detection)
  Future<bool> isCurrentUserSameAsStored(String? currentUserId) async {
    if (currentUserId == null) return false;

    final storedUserId = await getLastUserId();
    return storedUserId == currentUserId;
  }
}
