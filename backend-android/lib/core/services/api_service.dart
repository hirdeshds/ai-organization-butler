// lib/core/services/api_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // ==================== SERVERPOD CONFIG ====================
  static String get serverpodUrl {
    if (kIsWeb) {
      return 'http://localhost:8082';
    } else if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:8082'; // Android Emulator
      // return 'http://YOUR_PC_IP:8082'; // Real device
    } else {
      return 'http://localhost:8082';
    }
  }

  // ==================== ROBOFLOW ML CONFIG ====================
  static const String roboflowApiUrl = 'https://serverless.roboflow.com/roomclutterdetection-3h7ce/workflows/detect-count-and-visualize';
  static const String roboflowApiKey = 'mXtugLtRIX7wQwJPVaHV';

  // ==================== HEALTH CHECK ====================
  static Future<bool> healthCheck() async {
    try {
      final response = await http.get(
        Uri.parse('$serverpodUrl/'),
      ).timeout(const Duration(seconds: 5));

      debugPrint('🟢 Serverpod health: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('🔴 Serverpod health failed: $e');
      return false;
    }
  }

  // ==================== ROBOFLOW DIRECT ANALYSIS ====================
  // Use this for quick testing without Serverpod
  static Future<RoboflowResponse?> analyzeWithRoboflow(String imageUrl) async {
    try {
      debugPrint('🤖 Calling Roboflow ML API...');
      debugPrint('📸 Image URL: $imageUrl');

      final response = await http.post(
        Uri.parse(roboflowApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'api_key': roboflowApiKey,
          'inputs': {
            'image': {'type': 'url', 'value': imageUrl}
          }
        }),
      ).timeout(const Duration(seconds: 30));

      debugPrint('📥 Roboflow response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('✅ ML Analysis complete: $data');
        return RoboflowResponse.fromJson(data);
      } else {
        debugPrint('❌ Roboflow error: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Roboflow API Error: $e');
      return null;
    }
  }

  // ==================== ANALYZE WITH BASE64 IMAGE ====================
  static Future<RoboflowResponse?> analyzeWithBase64(File imageFile) async {
    try {
      debugPrint('🤖 Analyzing image with Roboflow (base64)...');

      // Convert image to base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http.post(
        Uri.parse(roboflowApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'api_key': roboflowApiKey,
          'inputs': {
            'image': {'type': 'base64', 'value': base64Image}
          }
        }),
      ).timeout(const Duration(seconds: 45));

      debugPrint('📥 Roboflow response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('✅ ML Analysis complete');
        return RoboflowResponse.fromJson(data);
      } else {
        debugPrint('❌ Roboflow error: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Roboflow API Error: $e');
      return null;
    }
  }

  // ==================== SERVERPOD ENDPOINT CALL ====================
  // Call your Serverpod backend (which then calls Roboflow)
  static Future<RoomAnalysisResponse?> analyzeViaServerpod(String imageUrl) async {
    try {
      debugPrint('🚀 Calling Serverpod analyzeRoom endpoint...');

      final response = await http.post(
        Uri.parse('$serverpodUrl/api/room/analyzeRoom'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'imageUrl': imageUrl}),
      ).timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('✅ Serverpod analysis complete');
        return RoomAnalysisResponse.fromJson(data);
      } else {
        debugPrint('❌ Serverpod error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Serverpod API Error: $e');
      return null;
    }
  }

  // ==================== GET ALL ANALYSES ====================
  static Future<List<RoomAnalysisResponse>> getAllAnalyses() async {
    try {
      final response = await http.get(
        Uri.parse('$serverpodUrl/api/room/getAllAnalyses'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => RoomAnalysisResponse.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('❌ Get analyses error: $e');
      return [];
    }
  }
}

// ==================== RESPONSE MODELS ====================

class RoboflowResponse {
  final List<DetectedObject> predictions;
  final String? visualizedImage;

  RoboflowResponse({required this.predictions, this.visualizedImage});

  factory RoboflowResponse.fromJson(Map<String, dynamic> json) {
    List<DetectedObject> predictions = [];
    String? visualizedImage;

    // Handle different Roboflow response formats

    // Format 1: Direct predictions array
    if (json['predictions'] != null) {
      final preds = json['predictions'] as List? ?? [];
      predictions = preds.map((p) => DetectedObject.fromJson(p)).toList();
    }

    // Format 2: Outputs array (workflow response)
    if (json['outputs'] != null) {
      final outputs = json['outputs'] as List? ?? [];
      for (var output in outputs) {
        if (output is Map<String, dynamic>) {
          // Check for predictions in output
          if (output['predictions'] != null) {
            final preds = output['predictions'];
            if (preds is List) {
              predictions = preds.map((p) => DetectedObject.fromJson(p as Map<String, dynamic>)).toList();
            } else if (preds is Map && preds['predictions'] != null) {
              final innerPreds = preds['predictions'] as List? ?? [];
              predictions = innerPreds.map((p) => DetectedObject.fromJson(p as Map<String, dynamic>)).toList();
            }
          }
          // Check for visualized image
          if (output['output_image'] != null) {
            visualizedImage = output['output_image'].toString();
          }
          if (output['visualization'] != null) {
            visualizedImage = output['visualization'].toString();
          }
        }
      }
    }

    // Format 3: Direct response with image
    if (json['image'] != null && json['image']['predictions'] != null) {
      final preds = json['image']['predictions'] as List? ?? [];
      predictions = preds.map((p) => DetectedObject.fromJson(p)).toList();
    }

    debugPrint('🔍 Parsed ${predictions.length} predictions from Roboflow');

    return RoboflowResponse(
      predictions: predictions,
      visualizedImage: visualizedImage,
    );
  }

  int get messinessScore {
    if (predictions.isEmpty) return 10;

    final weights = {
      'clothes': 15, 'cables': 10, 'books': 5, 'bottles': 8,
      'papers': 12, 'trash': 20, 'shoes': 7, 'bags': 6,
    };

    int score = 0;
    for (var obj in predictions) {
      score += weights[obj.label.toLowerCase()] ?? 5;
    }
    return score > 100 ? 100 : score;
  }

  String get roomState {
    final score = messinessScore;
    if (score < 20) return 'Clean';
    if (score < 40) return 'Slightly Messy';
    if (score < 70) return 'Messy';
    return 'Very Messy';
  }

  List<String> get organizationPlan {
    final actionMap = {
      'clothes': 'Fold and store clothes in wardrobe',
      'cables': 'Bundle and organize cables',
      'books': 'Arrange books on shelf',
      'bottles': 'Put bottles in designated area',
      'papers': 'Sort and file papers',
      'trash': 'Dispose trash properly',
      'shoes': 'Place shoes on rack',
      'bags': 'Hang bags in closet',
    };

    List<String> plan = [];
    Set<String> added = {};
    int step = 1;

    for (var obj in predictions) {
      final action = actionMap[obj.label.toLowerCase()];
      if (action != null && !added.contains(action)) {
        plan.add('Step $step: $action');
        added.add(action);
        step++;
      }
    }

    if (plan.isEmpty) {
      plan.add('Step 1: Room looks clean! Maintain it.');
    }

    return plan;
  }
}

class DetectedObject {
  final String label;
  final double confidence;
  final double x;
  final double y;
  final double width;
  final double height;

  DetectedObject({
    required this.label,
    required this.confidence,
    this.x = 0,
    this.y = 0,
    this.width = 0,
    this.height = 0,
  });

  factory DetectedObject.fromJson(Map<String, dynamic> json) {
    return DetectedObject(
      label: json['class'] ?? json['label'] ?? 'unknown',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      x: (json['x'] ?? 0.0).toDouble(),
      y: (json['y'] ?? 0.0).toDouble(),
      width: (json['width'] ?? 0.0).toDouble(),
      height: (json['height'] ?? 0.0).toDouble(),
    );
  }
}

class RoomAnalysisResponse {
  final int? id;
  final String imageUrl;
  final List<String> detectedObjects;
  final int messinessScore;
  final String roomState;
  final List<String> organizationPlan;
  final DateTime createdAt;

  RoomAnalysisResponse({
    this.id,
    required this.imageUrl,
    required this.detectedObjects,
    required this.messinessScore,
    required this.roomState,
    required this.organizationPlan,
    required this.createdAt,
  });

  factory RoomAnalysisResponse.fromJson(Map<String, dynamic> json) {
    return RoomAnalysisResponse(
      id: json['id'],
      imageUrl: json['imageUrl'] ?? '',
      detectedObjects: List<String>.from(json['detectedObjects'] ?? []),
      messinessScore: json['messinessScore'] ?? 0,
      roomState: json['roomState'] ?? 'Unknown',
      organizationPlan: List<String>.from(json['organizationPlan'] ?? []),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}