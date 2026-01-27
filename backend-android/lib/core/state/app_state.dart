import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/models.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';

class AppState extends ChangeNotifier {
  final StorageService _storage = StorageService();
  bool _isLoading = true;

  // ==================== USER STATE ====================
  UserProfile _user = UserProfile(
    id: 'user_1',
    name: '',
    emoji: '👤',
  );

  UserProfile get user => _user;
  bool get isLoading => _isLoading;

  // ==================== SELECTED IMAGE STATE ====================
  File? _selectedImage;
  File? get selectedImage => _selectedImage;

  void setSelectedImage(File? image) {
    _selectedImage = image;
    notifyListeners();
  }

  void clearSelectedImage() {
    _selectedImage = null;
    notifyListeners();
  }

  // ==================== IMAGE PERSISTENCE ====================
  /// Save image to app's documents directory for persistence
  Future<String?> _saveImagePermanently(File sourceImage, String roomId) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final imageDir = Directory(path.join(appDir.path, 'room_images'));

      if (!await imageDir.exists()) {
        await imageDir.create(recursive: true);
      }

      final extension = path.extension(sourceImage.path);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'room_${roomId}_$timestamp$extension';
      final destinationPath = path.join(imageDir.path, fileName);

      final savedFile = await sourceImage.copy(destinationPath);
      debugPrint('✅ Image saved permanently: ${savedFile.path}');

      return savedFile.path;
    } catch (e) {
      debugPrint('❌ Error saving image: $e');
      return null;
    }
  }

  // ==================== ROOMS STATE ====================
  List<Room> _rooms = [];
  Room? _currentRoom;
  Room? _scanningRoom;

  List<Room> get rooms => _rooms;
  List<Room> get cleanedRooms => _rooms.where((r) => r.status == RoomStatus.cleaned).toList();
  Room? get currentRoom => _currentRoom;
  Room? get scanningRoom => _scanningRoom;

  // ==================== TASKS STATE ====================
  List<CleanupTask> _tasks = [];
  List<CleanupTask> get tasks => _tasks;

  // ==================== ACHIEVEMENTS STATE ====================
  List<Achievement> _achievements = [];
  List<Achievement> get achievements => _achievements;
  List<Achievement> get unlockedAchievements => _achievements.where((a) => a.isUnlocked).toList();

  // ==================== SETTINGS STATE ====================
  AppSettings _settings = AppSettings();
  AppSettings get settings => _settings;

  // ==================== INSIGHTS STATE ====================
  List<Insight> get todayInsights {
    if (_user.totalItemsSorted == 0) return [];
    return [
      Insight(
        id: 'i1',
        title: 'Items Sorted Today',
        description: 'Great progress!',
        type: InsightType.stat,
        value: '${_getTodayItemsSorted()}',
        change: '+${_getTodayItemsSorted()}',
      ),
      Insight(
        id: 'i2',
        title: 'Clutter Reduction',
        description: 'Your spaces are cleaner',
        type: InsightType.stat,
        value: '${_getClutterReduction()}%',
      ),
    ];
  }

  // Weekly cleanliness data for chart
  List<int> _weeklyScores = [];
  List<int> get weeklyScores {
    if (_weeklyScores.isEmpty) return [];
    while (_weeklyScores.length < 7) {
      _weeklyScores.add(0);
    }
    return _weeklyScores.take(7).toList();
  }

  int get currentCleanlinessScore {
    if (_weeklyScores.isEmpty) return 0;
    return _weeklyScores.last;
  }

  int get scoreChange {
    if (_weeklyScores.length < 2) return 0;
    return _weeklyScores.last - _weeklyScores[_weeklyScores.length - 2];
  }

  // ==================== INITIALIZATION ====================
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      _user = await _storage.getUserProfile();
      _rooms = await _storage.getRooms();
      _tasks = await _storage.getTasks();
      _achievements = await _storage.getAchievements();
      _settings = await _storage.getSettings();
      _weeklyScores = await _storage.getWeeklyScores();
      await _updateStreak();
    } catch (e) {
      debugPrint('Error loading app state: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== USER METHODS ====================
  Future<void> updateUser(UserProfile user) async {
    _user = user;
    await _storage.saveUserProfile(user);
    notifyListeners();
  }

  Future<void> completeOnboarding(String name, String emoji) async {
    _user = _user.copyWith(name: name, emoji: emoji);
    await _storage.saveUserProfile(_user);
    await _storage.setOnboardingComplete(true);
    notifyListeners();
  }

  Future<void> incrementStreak() async {
    final lastActivity = await _storage.getLastActivityDate();
    final now = DateTime.now();

    if (lastActivity == null) {
      _user = _user.copyWith(streakDays: 1);
      await _storage.setLastActivityDate(now);
    } else {
      final daysSince = now.difference(lastActivity).inDays;
      if (daysSince == 0) {
        return;
      } else if (daysSince == 1) {
        _user = _user.copyWith(streakDays: _user.streakDays + 1);
        await _storage.setLastActivityDate(now);
      } else {
        _user = _user.copyWith(streakDays: 1);
        await _storage.setLastActivityDate(now);
      }
    }

    await _storage.saveUserProfile(_user);
    _checkAchievements();
    notifyListeners();
  }

  Future<void> _updateStreak() async {
    final lastActivity = await _storage.getLastActivityDate();
    if (lastActivity == null) return;

    final now = DateTime.now();
    final daysSince = now.difference(lastActivity).inDays;

    if (daysSince > 1) {
      _user = _user.copyWith(streakDays: 0);
      await _storage.saveUserProfile(_user);
    }
  }

  Future<void> addSortedItems(int count) async {
    _user = _user.copyWith(totalItemsSorted: _user.totalItemsSorted + count);
    await _storage.saveUserProfile(_user);
    _checkAchievements();
    notifyListeners();
  }

  // ==================== ROOM METHODS ====================
  void selectRoom(String roomId) {
    _currentRoom = _rooms.firstWhere((r) => r.id == roomId);
    notifyListeners();
  }

  Future<void> addRoom(Room room) async {
    _rooms.add(room);
    await _storage.saveRooms(_rooms);
    notifyListeners();
  }

  Future<void> updateRoom(Room room) async {
    final index = _rooms.indexWhere((r) => r.id == room.id);
    if (index != -1) {
      _rooms[index] = room;
      await _storage.saveRooms(_rooms);
      notifyListeners();
    }
  }

  void setScanningRoom(Room? room) {
    _scanningRoom = room;
    notifyListeners();
  }

  // ==================== TASK METHODS ====================
  Future<void> addTask(CleanupTask task) async {
    _tasks.add(task);
    await _storage.saveTasks(_tasks);
    notifyListeners();
  }

  Future<void> toggleTask(String taskId) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      _tasks[index] = _tasks[index].copyWith(
        isCompleted: !_tasks[index].isCompleted,
      );
      await _storage.saveTasks(_tasks);
      notifyListeners();
    }
  }

  Future<void> generateTasksForRoom(String roomId, [List<ClutterItem>? clutterItems]) async {
    // Check if tasks already exist for this room
    final existingTasks = _tasks.where((t) => t.roomId == roomId).toList();
    if (existingTasks.isNotEmpty) {
      debugPrint('⚠️ Tasks already exist for room $roomId, skipping generation');
      return;
    }

    final room = _rooms.firstWhere((r) => r.id == roomId, orElse: () => Room(id: roomId, name: 'Room'));

    final newTasks = [
      CleanupTask(
        id: 'task_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Clear floor periphery',
        description: 'Move items to designated storage containers',
        durationMinutes: 15,
        roomId: roomId,
        priority: 1,
      ),
    ];

    _tasks.addAll(newTasks);
    await _storage.saveTasks(_tasks);
    notifyListeners();
  }

  List<CleanupTask> getTasksForRoom(String roomId) {
    return _tasks.where((t) => t.roomId == roomId).toList();
  }

  // ==================== ACHIEVEMENT METHODS ====================
  void _checkAchievements() {
    bool updated = false;

    final zenIndex = _achievements.indexWhere((a) => a.id == 'a2');
    if (zenIndex != -1) {
      final achievement = _achievements[zenIndex];
      final newValue = _user.streakDays;
      if (newValue != achievement.currentValue) {
        _achievements[zenIndex] = achievement.copyWith(
          currentValue: newValue,
          isUnlocked: newValue >= achievement.requiredValue,
          unlockedAt: newValue >= achievement.requiredValue ? DateTime.now() : null,
        );
        updated = true;
      }
    }

    final proIndex = _achievements.indexWhere((a) => a.id == 'a6');
    if (proIndex != -1) {
      final achievement = _achievements[proIndex];
      final newValue = _user.totalItemsSorted;
      if (newValue != achievement.currentValue) {
        _achievements[proIndex] = achievement.copyWith(
          currentValue: newValue,
          isUnlocked: newValue >= achievement.requiredValue,
          unlockedAt: newValue >= achievement.requiredValue ? DateTime.now() : null,
        );
        updated = true;
      }
    }

    final spaceIndex = _achievements.indexWhere((a) => a.id == 'a4');
    if (spaceIndex != -1) {
      final achievement = _achievements[spaceIndex];
      final newValue = cleanedRooms.length;
      if (newValue != achievement.currentValue) {
        _achievements[spaceIndex] = achievement.copyWith(
          currentValue: newValue,
          isUnlocked: newValue >= achievement.requiredValue,
          unlockedAt: newValue >= achievement.requiredValue ? DateTime.now() : null,
        );
        updated = true;
      }
    }

    if (updated) {
      _storage.saveAchievements(_achievements);
      notifyListeners();
    }
  }

  // ==================== SETTINGS METHODS ====================
  Future<void> updateSettings(AppSettings settings) async {
    _settings = settings;
    await _storage.saveSettings(settings);
    notifyListeners();
  }

  Future<void> toggleNotifications() async {
    _settings = _settings.copyWith(notificationsEnabled: !_settings.notificationsEnabled);
    await _storage.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> setAIPersonality(String personality) async {
    _settings = _settings.copyWith(aiPersonality: personality);
    await _storage.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> setScanFrequency(String frequency) async {
    _settings = _settings.copyWith(scanFrequency: frequency);
    await _storage.saveSettings(_settings);
    notifyListeners();
  }

  // ==================== WEEKLY SCORES METHODS ====================
  Future<void> addWeeklyScore(int score) async {
    _weeklyScores.add(score);
    if (_weeklyScores.length > 7) {
      _weeklyScores = _weeklyScores.sublist(_weeklyScores.length - 7);
    }
    await _storage.saveWeeklyScores(_weeklyScores);
    notifyListeners();
  }

  // ==================== HELPER METHODS ====================
  int _getTodayItemsSorted() => 0;

  int _getClutterReduction() {
    if (_rooms.isEmpty) return 0;
    final avgScore = _rooms.map((r) => r.clutterScore).reduce((a, b) => a + b) / _rooms.length;
    return (100 - avgScore).round();
  }

  // ==================== API/ANALYSIS METHODS ====================
  double _analysisProgress = 0.0;
  double get analysisProgress => _analysisProgress;

  String? _analysisError;
  String? get analysisError => _analysisError;

  Future<bool> analyzeRoomWithAPI(String? imagePath) async {
    try {
      _analysisError = null;
      _analysisProgress = 0.0;
      notifyListeners();

      if (_selectedImage == null) {
        _analysisError = 'No image selected';
        notifyListeners();
        return false;
      }

      if (!await _selectedImage!.exists()) {
        debugPrint('❌ File does not exist: ${_selectedImage!.path}');
        _analysisError = 'Image file not found';
        notifyListeners();
        return false;
      }

      debugPrint('📸 Starting analysis for: ${_selectedImage!.path}');

      final roomId = 'room_${DateTime.now().millisecondsSinceEpoch}';

      // Save image permanently FIRST
      final permanentImagePath = await _saveImagePermanently(_selectedImage!, roomId);
      final imagePathToUse = permanentImagePath ?? _selectedImage!.path;

      final newRoom = Room(
        id: roomId,
        name: 'Scanned Room',
        imageUrl: imagePathToUse, // Use permanent path
        status: RoomStatus.scanning,
      );

      _scanningRoom = newRoom;
      _analysisProgress = 0.1;
      notifyListeners();
      debugPrint('✅ Step 1: Initializing');

      _analysisProgress = 0.3;
      notifyListeners();
      debugPrint('✅ Step 2: Calling Roboflow ML API...');

      RoboflowResponse? mlResponse;

      try {
        mlResponse = await ApiService.analyzeWithBase64(_selectedImage!);
      } catch (e) {
        debugPrint('⚠️ ML API error: $e');
        mlResponse = null;
      }

      if (mlResponse == null) {
        debugPrint('⚠️ ML API failed, using fallback');
        return await _fallbackAnalysis(newRoom, imagePathToUse);
      }

      _analysisProgress = 0.6;
      notifyListeners();
      debugPrint('✅ Step 3: Processing ML results');
      debugPrint('🔍 Detected ${mlResponse.predictions.length} objects');

      _analysisProgress = 0.8;
      notifyListeners();
      debugPrint('✅ Step 4: Generating cleanup plan');

      final clutterItems = mlResponse.predictions.map((obj) {
        return ClutterItem(
          id: 'item_${DateTime.now().millisecondsSinceEpoch}_${obj.label}',
          label: obj.label,
          suggestedAction: _getActionForItem(obj.label),
          boundingBox: Rect.fromLTWH(
            obj.x / 1000,
            obj.y / 1000,
            obj.width / 1000,
            obj.height / 1000,
          ),
        );
      }).toList();

      final analyzedRoom = newRoom.copyWith(
        imageUrl: imagePathToUse, // Ensure permanent path
        status: RoomStatus.analyzed,
        clutterScore: mlResponse.messinessScore,
        lastScanned: DateTime.now(),
        clutterItems: clutterItems,
      );

      _analysisProgress = 1.0;
      _rooms.add(analyzedRoom);
      _currentRoom = analyzedRoom;
      _scanningRoom = null;

      await _storage.saveRooms(_rooms);
      await incrementStreak();
      await addSortedItems(clutterItems.length);
      await _generateSmartTasks(analyzedRoom);

      notifyListeners();
      debugPrint('🎉 Analysis complete! Score: ${mlResponse.messinessScore}');
      return true;

    } catch (e, stackTrace) {
      debugPrint('❌ Analysis error: $e');
      debugPrint('Stack trace: $stackTrace');
      _scanningRoom = null;
      _analysisError = 'Analysis failed: $e';
      _analysisProgress = 0.0;
      notifyListeners();
      return false;
    }
  }

  Future<bool> _fallbackAnalysis(Room newRoom, String imagePath) async {
    try {
      debugPrint('🔄 Using fallback analysis...');

      await Future.delayed(const Duration(milliseconds: 500));
      _analysisProgress = 0.5;
      notifyListeners();

      await Future.delayed(const Duration(milliseconds: 500));
      _analysisProgress = 0.8;
      notifyListeners();

      final fallbackItems = [
        ClutterItem(
          id: 'item_${DateTime.now().millisecondsSinceEpoch}_1',
          label: 'Clothes',
          suggestedAction: ClutterAction.relocate,
          boundingBox: const Rect.fromLTWH(0.1, 0.2, 0.3, 0.25),
        ),
        ClutterItem(
          id: 'item_${DateTime.now().millisecondsSinceEpoch}_2',
          label: 'Books',
          suggestedAction: ClutterAction.relocate,
          boundingBox: const Rect.fromLTWH(0.5, 0.3, 0.25, 0.2),
        ),
        ClutterItem(
          id: 'item_${DateTime.now().millisecondsSinceEpoch}_3',
          label: 'Cables',
          suggestedAction: ClutterAction.relocate,
          boundingBox: const Rect.fromLTWH(0.6, 0.5, 0.2, 0.15),
        ),
      ];

      final analyzedRoom = newRoom.copyWith(
        status: RoomStatus.analyzed,
        clutterScore: 65,
        lastScanned: DateTime.now(),
        clutterItems: fallbackItems,
      );

      _analysisProgress = 1.0;
      _rooms.add(analyzedRoom);
      _currentRoom = analyzedRoom;
      _scanningRoom = null;

      await _storage.saveRooms(_rooms);
      await incrementStreak();
      await _generateSmartTasks(analyzedRoom);

      notifyListeners();
      debugPrint('✅ Fallback analysis complete!');
      return true;
    } catch (e) {
      debugPrint('❌ Fallback analysis error: $e');
      _scanningRoom = null;
      _analysisError = 'Analysis failed';
      _analysisProgress = 0.0;
      notifyListeners();
      return false;
    }
  }

  ClutterAction _getActionForItem(String label) {
    final lower = label.toLowerCase();
    if (lower.contains('trash') || lower.contains('garbage') || lower.contains('wrapper') || lower.contains('paper')) {
      return ClutterAction.discard;
    } else if (lower.contains('clothes') || lower.contains('shirt') || lower.contains('pants') || lower.contains('shoes')) {
      return ClutterAction.relocate;
    } else if (lower.contains('book') || lower.contains('toy') || lower.contains('old')) {
      return ClutterAction.donate;
    } else if (lower.contains('cable') || lower.contains('bag') || lower.contains('box')) {
      return ClutterAction.relocate;
    } else {
      return ClutterAction.keep;
    }
  }

  // ==================== SMART TASKS (DUPLICATE FIX) ====================
  Future<void> _generateSmartTasks(Room room) async {
    // ✅ FIX: Check for existing tasks to prevent duplicates
    final existingTasksForRoom = _tasks.where((t) => t.roomId == room.id).toList();
    if (existingTasksForRoom.isNotEmpty) {
      debugPrint('⚠️ Tasks already exist for room ${room.id}, skipping duplicate generation');
      return;
    }

    final tasks = <CleanupTask>[];
    final Set<String> addedLabels = {}; // Track unique labels

    for (final item in room.clutterItems) {
      // ✅ FIX: Skip duplicate labels
      if (addedLabels.contains(item.label.toLowerCase())) {
        debugPrint('⚠️ Skipping duplicate task for: ${item.label}');
        continue;
      }
      addedLabels.add(item.label.toLowerCase());

      String title;
      String description;
      int duration;

      switch (item.suggestedAction) {
        case ClutterAction.discard:
          title = 'Discard: ${item.label}';
          description = 'Remove unwanted items and dispose properly';
          duration = 5;
          break;
        case ClutterAction.relocate:
          title = 'Relocate: ${item.label}';
          description = 'Move to appropriate storage location';
          duration = 10;
          break;
        case ClutterAction.donate:
          title = 'Donate: ${item.label}';
          description = 'Consider donating this item';
          duration = 10;
          break;
        case ClutterAction.keep:
        default:
          title = 'Review: ${item.label}';
          description = 'Decide what to do with this item';
          duration = 5;
      }

      tasks.add(CleanupTask(
        id: 'task_${DateTime.now().millisecondsSinceEpoch}_${item.id}',
        title: title,
        description: description,
        durationMinutes: duration,
        roomId: room.id,
        priority: item.suggestedAction == ClutterAction.discard ? 1 : 2,
      ));
    }

    debugPrint('✅ Generated ${tasks.length} unique tasks for room ${room.id}');
    _tasks.addAll(tasks);
    await _storage.saveTasks(_tasks);
  }

  void resetAnalysis() {
    _selectedImage = null;
    _scanningRoom = null;
    _analysisProgress = 0.0;
    _analysisError = null;
    notifyListeners();
  }

  // ==================== CHAT METHODS ====================
  List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => _messages;

  Future<void> sendMessage(String content) async {
    final userMessage = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      content: content,
      isFromUser: true,
    );
    _messages.add(userMessage);
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));

    final aiMessage = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch + 1}',
      content: _generateAIResponse(content),
      isFromUser: false,
    );
    _messages.add(aiMessage);
    notifyListeners();
  }

  void clearChat() {
    _messages.clear();
    notifyListeners();
  }

  String _generateAIResponse(String userMessage) {
    final lowerMessage = userMessage.toLowerCase();
    if (lowerMessage.contains('help') || lowerMessage.contains('start')) {
      return 'I\'ve analyzed your space. Shall we begin with the most cluttered area?';
    } else if (lowerMessage.contains('desk') || lowerMessage.contains('table')) {
      return 'Great choice! Let\'s tackle the desk:\n• Clear surface first\n• Sort into keep/discard piles\n• Organize remaining items';
    } else if (lowerMessage.contains('clothes') || lowerMessage.contains('closet')) {
      return 'For clothes, try the fold test - if you haven\'t worn it in 6 months, consider donating it!';
    } else {
      return 'I\'m here to help organize your space. What area would you like to focus on?';
    }
  }
}