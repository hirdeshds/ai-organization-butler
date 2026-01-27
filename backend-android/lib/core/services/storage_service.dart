import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/models.dart';

class StorageService {
  static const String _keyOnboardingComplete = 'onboarding_complete';
  static const String _keyUserName = 'user_name';
  static const String _keyUserEmoji = 'user_emoji';
  static const String _keyUserEmail = 'user_email';
  static const String _keyIsPremium = 'is_premium';
  static const String _keyStreakDays = 'streak_days';
  static const String _keyTotalItemsSorted = 'total_items_sorted';
  static const String _keyRooms = 'rooms';
  static const String _keyTasks = 'tasks';
  static const String _keyAchievements = 'achievements';
  static const String _keySettings = 'settings';
  static const String _keyWeeklyScores = 'weekly_scores';
  static const String _keyLastActivityDate = 'last_activity_date';

  // Onboarding
  Future<bool> isOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboardingComplete) ?? false;
  }

  Future<void> setOnboardingComplete(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingComplete, value);
  }

  // User Profile
  Future<UserProfile> getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return UserProfile(
      id: 'user_1',
      name: prefs.getString(_keyUserName) ?? '',
      email: prefs.getString(_keyUserEmail) ?? '',
      emoji: prefs.getString(_keyUserEmoji) ?? '👤',
      isPremium: prefs.getBool(_keyIsPremium) ?? false,
      streakDays: prefs.getInt(_keyStreakDays) ?? 0,
      totalItemsSorted: prefs.getInt(_keyTotalItemsSorted) ?? 0,
    );
  }

  Future<void> saveUserProfile(UserProfile user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserName, user.name);
    await prefs.setString(_keyUserEmoji, user.emoji);
    if (user.email.isNotEmpty) {
      await prefs.setString(_keyUserEmail, user.email);
    }
    await prefs.setBool(_keyIsPremium, user.isPremium);
    await prefs.setInt(_keyStreakDays, user.streakDays);
    await prefs.setInt(_keyTotalItemsSorted, user.totalItemsSorted);
  }

  // Rooms
  Future<List<Room>> getRooms() async {
    final prefs = await SharedPreferences.getInstance();
    final roomsJson = prefs.getString(_keyRooms);
    if (roomsJson == null) return [];
    try {
      final List<dynamic> decoded = jsonDecode(roomsJson);
      return decoded.map((e) => Room.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveRooms(List<Room> rooms) async {
    final prefs = await SharedPreferences.getInstance();
    final roomsJson = jsonEncode(rooms.map((r) => r.toJson()).toList());
    await prefs.setString(_keyRooms, roomsJson);
  }

  // Tasks
  Future<List<CleanupTask>> getTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = prefs.getString(_keyTasks);
    if (tasksJson == null) return [];
    try {
      final List<dynamic> decoded = jsonDecode(tasksJson);
      return decoded.map((e) => CleanupTask.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveTasks(List<CleanupTask> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = jsonEncode(tasks.map((t) => t.toJson()).toList());
    await prefs.setString(_keyTasks, tasksJson);
  }

  // Achievements
  Future<List<Achievement>> getAchievements() async {
    final prefs = await SharedPreferences.getInstance();
    final achievementsJson = prefs.getString(_keyAchievements);
    if (achievementsJson == null) {
      // Return default locked achievements
      return _getDefaultAchievements();
    }
    try {
      final List<dynamic> decoded = jsonDecode(achievementsJson);
      return decoded.map((e) => Achievement.fromJson(e)).toList();
    } catch (e) {
      return _getDefaultAchievements();
    }
  }

  Future<void> saveAchievements(List<Achievement> achievements) async {
    final prefs = await SharedPreferences.getInstance();
    final achievementsJson = jsonEncode(achievements.map((a) => a.toJson()).toList());
    await prefs.setString(_keyAchievements, achievementsJson);
  }

  // Settings
  Future<AppSettings> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString(_keySettings);
    if (settingsJson == null) return AppSettings();
    try {
      final Map<String, dynamic> decoded = jsonDecode(settingsJson);
      return AppSettings.fromJson(decoded);
    } catch (e) {
      return AppSettings();
    }
  }

  Future<void> saveSettings(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = jsonEncode(settings.toJson());
    await prefs.setString(_keySettings, settingsJson);
  }

  // Weekly Scores
  Future<List<int>> getWeeklyScores() async {
    final prefs = await SharedPreferences.getInstance();
    final scoresJson = prefs.getString(_keyWeeklyScores);
    if (scoresJson == null) return [];
    try {
      final List<dynamic> decoded = jsonDecode(scoresJson);
      return decoded.map((e) => e as int).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveWeeklyScores(List<int> scores) async {
    final prefs = await SharedPreferences.getInstance();
    final scoresJson = jsonEncode(scores);
    await prefs.setString(_keyWeeklyScores, scoresJson);
  }

  // Last Activity Date (for streak tracking)
  Future<DateTime?> getLastActivityDate() async {
    final prefs = await SharedPreferences.getInstance();
    final dateStr = prefs.getString(_keyLastActivityDate);
    if (dateStr == null) return null;
    try {
      return DateTime.parse(dateStr);
    } catch (e) {
      return null;
    }
  }

  Future<void> setLastActivityDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastActivityDate, date.toIso8601String());
  }

  // Helper: Default achievements (all locked)
  List<Achievement> _getDefaultAchievements() {
    return [
      Achievement(
        id: 'a1',
        name: 'The Purge',
        description: 'Remove 50 items from your space',
        iconName: 'cleaning_services',
        requiredValue: 50,
        currentValue: 0,
      ),
      Achievement(
        id: 'a2',
        name: 'Zen Master',
        description: 'Maintain a 7-day streak',
        iconName: 'self_improvement',
        requiredValue: 7,
        currentValue: 0,
      ),
      Achievement(
        id: 'a3',
        name: 'Categorizer',
        description: 'Organize 100 items',
        iconName: 'category',
        requiredValue: 100,
        currentValue: 0,
      ),
      Achievement(
        id: 'a4',
        name: 'Space Maker',
        description: 'Clean 5 rooms',
        iconName: 'space_dashboard',
        requiredValue: 5,
        currentValue: 0,
      ),
      Achievement(
        id: 'a5',
        name: 'Minimalist',
        description: 'Achieve spotless status in 3 rooms',
        iconName: 'minimize',
        requiredValue: 3,
        currentValue: 0,
      ),
      Achievement(
        id: 'a6',
        name: 'Butler Pro',
        description: 'Sort 1000 items total',
        iconName: 'workspace_premium',
        requiredValue: 1000,
        currentValue: 0,
      ),
    ];
  }

  // Clear all data (for logout/testing)
  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
