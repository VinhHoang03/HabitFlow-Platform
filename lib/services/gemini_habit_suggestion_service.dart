import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/ai_habit_suggestion_model.dart';
import '../models/habit_model.dart';

class GeminiHabitSuggestionService {
  static const _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  GeminiHabitSuggestionService({
    http.Client? client,
  }) : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<AiHabitSuggestionModel>> generateSuggestions(String goal) async {
    final goalText = goal.trim();
    if (goalText.isEmpty) {
      throw ArgumentError('Goal is required.');
    }
    final apiKey = dotenv.env['GEMINI_API_KEY']?.trim() ?? '';
    if (apiKey.isEmpty) {
      throw StateError(
        'Missing GEMINI_API_KEY in .env.',
      );
    }

    try {
      return await _requestSuggestions(
        apiKey: apiKey,
        goalText: goalText,
        maxOutputTokens: 2048,
      );
    } on FormatException {
      try {
        return await _requestSuggestions(
          apiKey: apiKey,
          goalText: goalText,
          maxOutputTokens: 4096,
        );
      } catch (_) {
        return _fallbackSuggestions(goalText);
      }
    }
  }

  Future<List<AiHabitSuggestionModel>> _requestSuggestions({
    required String apiKey,
    required String goalText,
    required int maxOutputTokens,
  }) async {
    final response = await _client.post(
      Uri.parse('$_endpoint?key=$apiKey'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(_buildRequestBody(goalText, maxOutputTokens)),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'Gemini request failed (${response.statusCode}): ${response.body}',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final text = body['candidates']?[0]?['content']?['parts']?[0]?['text'];
    if (text is! String || text.trim().isEmpty) {
      throw FormatException('Gemini returned an empty response: ${response.body}');
    }

    final data = _decodeGeminiJson(text);
    final rawSuggestions = data['suggestions'];
    if (rawSuggestions is! List) {
      throw const FormatException('Invalid Gemini suggestions response.');
    }

    return rawSuggestions
        .whereType<Map>()
        .map(
          (item) => AiHabitSuggestionModel.fromMap(
            Map<String, dynamic>.from(item),
          ),
        )
        .where((suggestion) => suggestion.name.trim().isNotEmpty)
        .take(5)
        .toList();
  }

  Map<String, dynamic> _buildRequestBody(String goalText, int maxOutputTokens) {
    return {
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': _buildPrompt(goalText)},
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0.35,
        'maxOutputTokens': maxOutputTokens,
        'responseMimeType': 'application/json',
        'responseSchema': {
          'type': 'OBJECT',
          'properties': {
            'suggestions': {
              'type': 'ARRAY',
              'minItems': 3,
              'maxItems': 3,
              'items': {
                'type': 'OBJECT',
                'properties': {
                  'name': {'type': 'STRING'},
                  'description': {'type': 'STRING'},
                  'category': {'type': 'STRING'},
                  'frequency': {
                    'type': 'STRING',
                    'enum': ['Daily', 'Weekly', 'Custom'],
                  },
                  'priority': {
                    'type': 'STRING',
                    'enum': ['Low', 'Medium', 'High'],
                  },
                  'difficulty': {
                    'type': 'STRING',
                    'enum': ['Easy', 'Medium', 'Hard'],
                  },
                  'reminderTime': {'type': 'STRING'},
                  'reason': {'type': 'STRING'},
                },
                'required': [
                  'name',
                  'description',
                  'category',
                  'frequency',
                  'priority',
                  'difficulty',
                  'reminderTime',
                  'reason',
                ],
              },
            },
          },
          'required': ['suggestions'],
        },
      },
    };
  }

  String _buildPrompt(String goalText) {
    return [
      'You are a habit coach for a Vietnamese habit tracking app.',
      'Suggest exactly 3 practical habits for the user personal goal.',
      'Return Vietnamese text for name, description, category, and reason.',
      'Do not put line breaks inside any JSON string value.',
      'Each description must be under 90 characters.',
      'Each reason must be under 80 characters.',
      'Each name must be under 45 characters.',
      'Keep each habit small, measurable, and realistic.',
      'Use only these enum values:',
      'frequency: Daily, Weekly, Custom',
      'priority: Low, Medium, High',
      'difficulty: Easy, Medium, Hard',
      'reminderTime must be HH:mm or empty string.',
      'User goal: $goalText',
    ].join('\n');
  }

  Map<String, dynamic> _decodeGeminiJson(String text) {
    final cleaned = _stripCodeFence(text.trim());
    try {
      return jsonDecode(cleaned) as Map<String, dynamic>;
    } on FormatException catch (firstError) {
      final repaired = _repairJsonStringControlChars(cleaned);
      try {
        return jsonDecode(repaired) as Map<String, dynamic>;
      } on FormatException catch (secondError) {
        throw FormatException(
          'Invalid Gemini JSON. First: ${firstError.message}. '
          'Second: ${secondError.message}. Preview: ${_preview(repaired)}',
        );
      }
    }
  }

  String _stripCodeFence(String value) {
    if (!value.startsWith('```')) return value;
    return value
        .replaceFirst(RegExp(r'^```(?:json)?\s*', caseSensitive: false), '')
        .replaceFirst(RegExp(r'\s*```$'), '')
        .trim();
  }

  String _repairJsonStringControlChars(String value) {
    final buffer = StringBuffer();
    var inString = false;
    var escaping = false;

    for (var index = 0; index < value.length; index++) {
      final char = value[index];

      if (escaping) {
        buffer.write(char);
        escaping = false;
        continue;
      }

      if (char == '\\') {
        buffer.write(char);
        escaping = true;
        continue;
      }

      if (char == '"') {
        inString = !inString;
        buffer.write(char);
        continue;
      }

      if (inString && (char == '\n' || char == '\r' || char == '\t')) {
        buffer.write(' ');
        continue;
      }

      buffer.write(char);
    }

    return buffer.toString();
  }

  String _preview(String value) {
    final compact = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    return compact.length > 260 ? '${compact.substring(0, 260)}...' : compact;
  }

  List<AiHabitSuggestionModel> _fallbackSuggestions(String goalText) {
    return [
      AiHabitSuggestionModel(
        name: 'Dành 10 phút bắt đầu',
        description: 'Làm một bước nhỏ liên quan đến mục tiêu của bạn.',
        category: 'Phát triển bản thân',
        frequency: HabitFrequency.daily,
        priority: HabitPriority.high,
        difficulty: HabitDifficulty.easy,
        reminderTime: '20:00',
        reason: 'Bước nhỏ giúp duy trì đều hơn.',
      ),
      const AiHabitSuggestionModel(
        name: 'Ghi lại tiến độ',
        description: 'Viết nhanh điều đã làm và việc cần cải thiện.',
        category: 'Phát triển bản thân',
        frequency: HabitFrequency.daily,
        priority: HabitPriority.medium,
        difficulty: HabitDifficulty.easy,
        reminderTime: '21:30',
        reason: 'Theo dõi giúp bạn thấy tiến bộ.',
      ),
      const AiHabitSuggestionModel(
        name: 'Ôn lại kế hoạch tuần',
        description: 'Mỗi tuần xem lại kế hoạch và chỉnh bước tiếp theo.',
        category: 'Phát triển bản thân',
        frequency: HabitFrequency.weekly,
        priority: HabitPriority.medium,
        difficulty: HabitDifficulty.medium,
        reminderTime: '19:00',
        reason: 'Giữ mục tiêu đi đúng hướng.',
      ),
    ];
  }
}
