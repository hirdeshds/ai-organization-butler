import 'package:flutter/material.dart' show TimeOfDay;
import 'dart:ui' show Rect;

// ==================== USER MODEL ====================
class UserProfile {
  final String id;
  final String name;
  final String email;
  final String emoji; // Changed from avatarUrl to emoji
  final bool isPremium;
  final int streakDays;
  final int totalItemsSorted;
  final DateTime joinedDate;

  UserProfile({
    required this.id,
    required this.name,
    this.email = '',
    this.emoji = '👤', // Default emoji
    this.isPremium = false,
    this.streakDays = 0,
    this.totalItemsSorted = 0,
    DateTime? joinedDate,
  }) : joinedDate = joinedDate ?? DateTime.now();

  UserProfile copyWith({
    String? name,
    String? email,
    String? emoji,
    bool? isPremium,
    int? streakDays,
    int? totalItemsSorted,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      emoji: emoji ?? this.emoji,
      isPremium: isPremium ?? this.isPremium,
      streakDays: streakDays ?? this.streakDays,
      totalItemsSorted: totalItemsSorted ?? this.totalItemsSorted,
      joinedDate: joinedDate,
    );
  }

  // JSON serialization for API/storage
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'emoji': emoji,
    'isPremium': isPremium,
    'streakDays': streakDays,
    'totalItemsSorted': totalItemsSorted,
    'joinedDate': joinedDate.toIso8601String(),
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    email: json['email'] ?? '',
    emoji: json['emoji'] ?? '👤',
    isPremium: json['isPremium'] ?? false,
    streakDays: json['streakDays'] ?? 0,
    totalItemsSorted: json['totalItemsSorted'] ?? 0,
    joinedDate: json['joinedDate'] != null
        ? DateTime.parse(json['joinedDate'])
        : DateTime.now(),
  );
}

// ==================== ROOM MODEL ====================
enum RoomStatus { pending, scanning, analyzed, cleaned }

class Room {
  final String id;
  final String name;
  final String imageUrl;
  final RoomStatus status;
  final int clutterScore;
  final DateTime? lastScanned;
  final DateTime? completedAt;
  final List<ClutterItem> clutterItems;

  Room({
    required this.id,
    required this.name,
    this.imageUrl = '',
    this.status = RoomStatus.pending,
    this.clutterScore = 0,
    this.lastScanned,
    this.completedAt,
    this.clutterItems = const [],
  });

  bool get isSpotless => clutterScore < 20;
  bool get isChaosMode => clutterScore > 80;
  bool get needsAttention => clutterScore >= 50;

  // Get status color for UI
  String get statusLabel {
    switch (status) {
      case RoomStatus.pending: return 'Pending';
      case RoomStatus.scanning: return 'Scanning...';
      case RoomStatus.analyzed: return 'Analyzed';
      case RoomStatus.cleaned: return 'Cleaned';
    }
  }

  // Get clutter level description
  String get clutterLevel {
    if (clutterScore < 20) return 'Spotless';
    if (clutterScore < 40) return 'Tidy';
    if (clutterScore < 60) return 'Moderate';
    if (clutterScore < 80) return 'Cluttered';
    return 'Chaos Mode';
  }

  Room copyWith({
    String? name,
    String? imageUrl,
    RoomStatus? status,
    int? clutterScore,
    DateTime? lastScanned,
    DateTime? completedAt,
    List<ClutterItem>? clutterItems,
  }) {
    return Room(
      id: id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      status: status ?? this.status,
      clutterScore: clutterScore ?? this.clutterScore,
      lastScanned: lastScanned ?? this.lastScanned,
      completedAt: completedAt ?? this.completedAt,
      clutterItems: clutterItems ?? this.clutterItems,
    );
  }

  // JSON serialization
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'imageUrl': imageUrl,
    'status': status.name,
    'clutterScore': clutterScore,
    'lastScanned': lastScanned?.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'clutterItems': clutterItems.map((e) => e.toJson()).toList(),
  };

  factory Room.fromJson(Map<String, dynamic> json) => Room(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    imageUrl: json['imageUrl'] ?? '',
    status: RoomStatus.values.firstWhere(
          (e) => e.name == json['status'],
      orElse: () => RoomStatus.pending,
    ),
    clutterScore: json['clutterScore'] ?? 0,
    lastScanned: json['lastScanned'] != null
        ? DateTime.parse(json['lastScanned'])
        : null,
    completedAt: json['completedAt'] != null
        ? DateTime.parse(json['completedAt'])
        : null,
    clutterItems: (json['clutterItems'] as List?)
        ?.map((e) => ClutterItem.fromJson(e))
        .toList() ?? [],
  );
}

// ==================== CLUTTER ITEM MODEL ====================
enum ClutterAction { discard, relocate, keep, donate }

extension ClutterActionExtension on ClutterAction {
  String get label {
    switch (this) {
      case ClutterAction.discard: return 'Discard';
      case ClutterAction.relocate: return 'Relocate';
      case ClutterAction.keep: return 'Keep & Organize';
      case ClutterAction.donate: return 'Donate';
    }
  }

  String get icon {
    switch (this) {
      case ClutterAction.discard: return '🗑️';
      case ClutterAction.relocate: return '📦';
      case ClutterAction.keep: return '✅';
      case ClutterAction.donate: return '🎁';
    }
  }

  String get description {
    switch (this) {
      case ClutterAction.discard: return 'Remove and properly dispose';
      case ClutterAction.relocate: return 'Move to appropriate location';
      case ClutterAction.keep: return 'Find a proper place';
      case ClutterAction.donate: return 'Set aside for donation';
    }
  }
}

class ClutterItem {
  final String id;
  final String label;
  final ClutterAction suggestedAction;
  final double? confidence;
  final Rect boundingBox;
  final bool isProcessed;
  final String? category;  // e.g., 'electronics', 'clothing', 'paper'

  ClutterItem({
    required this.id,
    required this.label,
    required this.suggestedAction,
    this.confidence,
    required this.boundingBox,
    this.isProcessed = false,
    this.category,
  });

  // Confidence percentage string
  String get confidencePercent =>
      confidence != null ? '${(confidence! * 100).toInt()}%' : 'N/A';

  ClutterItem copyWith({
    bool? isProcessed,
    ClutterAction? suggestedAction,
  }) {
    return ClutterItem(
      id: id,
      label: label,
      suggestedAction: suggestedAction ?? this.suggestedAction,
      confidence: confidence,
      boundingBox: boundingBox,
      isProcessed: isProcessed ?? this.isProcessed,
      category: category,
    );
  }

  // JSON serialization
  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'suggestedAction': suggestedAction.name,
    'confidence': confidence,
    'boundingBox': {
      'left': boundingBox.left,
      'top': boundingBox.top,
      'width': boundingBox.width,
      'height': boundingBox.height,
    },
    'isProcessed': isProcessed,
    'category': category,
  };

  factory ClutterItem.fromJson(Map<String, dynamic> json) {
    final bbox = json['boundingBox'] as Map<String, dynamic>? ??
        json['bbox'] as Map<String, dynamic>?;

    return ClutterItem(
      id: json['id'] ?? 'item_${DateTime.now().millisecondsSinceEpoch}',
      label: json['label'] ?? 'Unknown item',
      suggestedAction: ClutterAction.values.firstWhere(
            (e) => e.name == json['suggestedAction'],
        orElse: () => ClutterAction.keep,
      ),
      confidence: (json['confidence'] as num?)?.toDouble(),
      boundingBox: bbox != null
          ? Rect.fromLTWH(
        (bbox['left'] ?? bbox['x'] ?? 0).toDouble(),
        (bbox['top'] ?? bbox['y'] ?? 0).toDouble(),
        (bbox['width'] ?? 0.1).toDouble(),
        (bbox['height'] ?? 0.1).toDouble(),
      )
          : Rect.zero,
      isProcessed: json['isProcessed'] ?? false,
      category: json['category'],
    );
  }
}

// ==================== TASK MODEL ====================
enum TaskPriority { low, medium, high, urgent }

class CleanupTask {
  final String id;
  final String title;
  final String description;
  final int durationMinutes;
  final bool isCompleted;
  final String roomId;
  final int priority;
  final String? relatedItemId;  // Link to ClutterItem

  CleanupTask({
    required this.id,
    required this.title,
    required this.description,
    required this.durationMinutes,
    this.isCompleted = false,
    required this.roomId,
    this.priority = 0,
    this.relatedItemId,
  });

  String get durationLabel {
    if (durationMinutes < 60) return '$durationMinutes min';
    final hours = durationMinutes ~/ 60;
    final mins = durationMinutes % 60;
    return mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
  }

  CleanupTask copyWith({
    bool? isCompleted,
    int? priority,
    String? title,
    String? description,
  }) {
    return CleanupTask(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      durationMinutes: durationMinutes,
      isCompleted: isCompleted ?? this.isCompleted,
      roomId: roomId,
      priority: priority ?? this.priority,
      relatedItemId: relatedItemId,
    );
  }

  // JSON serialization
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'durationMinutes': durationMinutes,
    'isCompleted': isCompleted,
    'roomId': roomId,
    'priority': priority,
    'relatedItemId': relatedItemId,
  };

  factory CleanupTask.fromJson(Map<String, dynamic> json) => CleanupTask(
    id: json['id'] ?? '',
    title: json['title'] ?? '',
    description: json['description'] ?? '',
    durationMinutes: json['durationMinutes'] ?? 5,
    isCompleted: json['isCompleted'] ?? false,
    roomId: json['roomId'] ?? '',
    priority: json['priority'] ?? 0,
    relatedItemId: json['relatedItemId'],
  );
}

// ==================== INSIGHT MODEL ====================
enum InsightType { tip, warning, achievement, stat }

class Insight {
  final String id;
  final String title;
  final String description;
  final InsightType type;
  final String? value;
  final String? change;
  final DateTime createdAt;

  Insight({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.value,
    this.change,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isPositiveChange =>
      change != null && (change!.startsWith('+') || change!.startsWith('-'));
}

// ==================== ACHIEVEMENT MODEL ====================
class Achievement {
  final String id;
  final String name;
  final String description;
  final String iconName;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final int requiredValue;
  final int currentValue;

  Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.iconName,
    this.isUnlocked = false,
    this.unlockedAt,
    this.requiredValue = 0,
    this.currentValue = 0,
  });

  double get progress => requiredValue > 0
      ? (currentValue / requiredValue).clamp(0.0, 1.0)
      : 0;

  int get progressPercent => (progress * 100).toInt();

  bool get isClose => progress >= 0.8 && !isUnlocked;

  Achievement copyWith({
    bool? isUnlocked,
    DateTime? unlockedAt,
    int? currentValue,
  }) {
    return Achievement(
      id: id,
      name: name,
      description: description,
      iconName: iconName,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      requiredValue: requiredValue,
      currentValue: currentValue ?? this.currentValue,
    );
  }

  // JSON serialization
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'iconName': iconName,
    'isUnlocked': isUnlocked,
    'unlockedAt': unlockedAt?.toIso8601String(),
    'requiredValue': requiredValue,
    'currentValue': currentValue,
  };

  factory Achievement.fromJson(Map<String, dynamic> json) => Achievement(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    description: json['description'] ?? '',
    iconName: json['iconName'] ?? '',
    isUnlocked: json['isUnlocked'] ?? false,
    unlockedAt: json['unlockedAt'] != null
        ? DateTime.parse(json['unlockedAt'])
        : null,
    requiredValue: json['requiredValue'] ?? 0,
    currentValue: json['currentValue'] ?? 0,
  );
}

// ==================== CHAT MESSAGE MODEL ====================
enum MessageType { text, image, suggestion, system }

class ChatMessage {
  final String id;
  final String content;
  final bool isFromUser;
  final MessageType type;
  final DateTime timestamp;
  final List<String>? suggestions;
  final String? imageUrl;
  final bool isLoading;  // For typing indicator

  ChatMessage({
    required this.id,
    required this.content,
    required this.isFromUser,
    this.type = MessageType.text,
    DateTime? timestamp,
    this.suggestions,
    this.imageUrl,
    this.isLoading = false,
  }) : timestamp = timestamp ?? DateTime.now();

  ChatMessage copyWith({
    String? content,
    List<String>? suggestions,
    bool? isLoading,
  }) {
    return ChatMessage(
      id: id,
      content: content ?? this.content,
      isFromUser: isFromUser,
      type: type,
      timestamp: timestamp,
      suggestions: suggestions ?? this.suggestions,
      imageUrl: imageUrl,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// ==================== APP SETTINGS MODEL ====================
class AppSettings {
  final bool notificationsEnabled;
  final bool darkModeEnabled;
  final String aiPersonality;
  final String scanFrequency;
  final TimeOfDay scheduledScanTime;
  final bool hapticFeedback;
  final bool autoScan;

  AppSettings({
    this.notificationsEnabled = true,
    this.darkModeEnabled = true,
    this.aiPersonality = 'Sophisticated Butler',
    this.scanFrequency = 'Daily',
    this.scheduledScanTime = const TimeOfDay(hour: 8, minute: 0),
    this.hapticFeedback = true,
    this.autoScan = false,
  });

  AppSettings copyWith({
    bool? notificationsEnabled,
    bool? darkModeEnabled,
    String? aiPersonality,
    String? scanFrequency,
    TimeOfDay? scheduledScanTime,
    bool? hapticFeedback,
    bool? autoScan,
  }) {
    return AppSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      darkModeEnabled: darkModeEnabled ?? this.darkModeEnabled,
      aiPersonality: aiPersonality ?? this.aiPersonality,
      scanFrequency: scanFrequency ?? this.scanFrequency,
      scheduledScanTime: scheduledScanTime ?? this.scheduledScanTime,
      hapticFeedback: hapticFeedback ?? this.hapticFeedback,
      autoScan: autoScan ?? this.autoScan,
    );
  }

  // JSON serialization
  Map<String, dynamic> toJson() => {
    'notificationsEnabled': notificationsEnabled,
    'darkModeEnabled': darkModeEnabled,
    'aiPersonality': aiPersonality,
    'scanFrequency': scanFrequency,
    'scheduledScanTime': {
      'hour': scheduledScanTime.hour,
      'minute': scheduledScanTime.minute,
    },
    'hapticFeedback': hapticFeedback,
    'autoScan': autoScan,
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final timeMap = json['scheduledScanTime'] as Map<String, dynamic>?;
    return AppSettings(
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      darkModeEnabled: json['darkModeEnabled'] ?? true,
      aiPersonality: json['aiPersonality'] ?? 'Sophisticated Butler',
      scanFrequency: json['scanFrequency'] ?? 'Daily',
      scheduledScanTime: timeMap != null
          ? TimeOfDay(
              hour: timeMap['hour'] ?? 8,
              minute: timeMap['minute'] ?? 0,
            )
          : const TimeOfDay(hour: 8, minute: 0),
      hapticFeedback: json['hapticFeedback'] ?? true,
      autoScan: json['autoScan'] ?? false,
    );
  }
}

// ==================== API RESPONSE MODELS ====================
class AnalysisResult {
  final int messinessScore;
  final List<DetectedObject> objects;
  final int processingTimeMs;
  final String? error;

  AnalysisResult({
    required this.messinessScore,
    required this.objects,
    this.processingTimeMs = 0,
    this.error,
  });

  bool get hasError => error != null;

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      messinessScore: (json['messiness_score'] ?? json['messinessScore'] ?? 0) as int,
      objects: (json['objects'] as List?)
          ?.map((e) => DetectedObject.fromJson(e))
          .toList() ?? [],
      processingTimeMs: json['processing_time_ms'] ?? 0,
      error: json['error'],
    );
  }

  factory AnalysisResult.error(String message) {
    return AnalysisResult(
      messinessScore: 0,
      objects: [],
      error: message,
    );
  }
}

class DetectedObject {
  final String label;
  final double confidence;
  final Rect boundingBox;
  final String? category;

  DetectedObject({
    required this.label,
    required this.confidence,
    required this.boundingBox,
    this.category,
  });

  factory DetectedObject.fromJson(Map<String, dynamic> json) {
    final bbox = json['bbox'] ?? json['boundingBox'] ?? {};

    return DetectedObject(
      label: json['label'] ?? 'Unknown',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.5,
      boundingBox: Rect.fromLTWH(
        (bbox['x'] ?? bbox['left'] ?? 0).toDouble(),
        (bbox['y'] ?? bbox['top'] ?? 0).toDouble(),
        (bbox['width'] ?? 0.1).toDouble(),
        (bbox['height'] ?? 0.1).toDouble(),
      ),
      category: json['category'],
    );
  }

  ClutterItem toClutterItem(ClutterAction action) {
    return ClutterItem(
      id: 'item_${DateTime.now().millisecondsSinceEpoch}_${label.hashCode}',
      label: label,
      suggestedAction: action,
      confidence: confidence,
      boundingBox: boundingBox,
      category: category,
    );
  }
}