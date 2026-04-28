import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Gemma 4 AI assistant via HuggingFace Inference API.
/// Model: google/gemma-3-4b-it  (update to google/gemma-4-4b-it when available)
class GemmaService {
  GemmaService._();
  static final GemmaService instance = GemmaService._();

  static const _modelId = 'google/gemma-3-4b-it';
  static const _baseUrl = 'https://api-inference.huggingface.co';
  static const _hfToken = 'hf_YOUR_TOKEN_HERE'; // replace with your token

  static const _systemPrompt =
      'You are CrisisSync AI, an expert emergency response coordinator for a hospitality venue. '
      'Analyse crisis reports, recommend immediate actions, suggest personnel deployment, '
      'provide evacuation guidance, and draft communications. '
      'Be calm, authoritative, concise, and action-oriented. Prioritise life safety.';

  final List<Map<String, String>> _history = [];

  Future<String> chat(String userMessage) async {
    _history.add({'role': 'user', 'content': userMessage});
    try {
      final reply = await _callApi();
      _history.add({'role': 'assistant', 'content': reply});
      return reply;
    } catch (e) {
      debugPrint('[GemmaService] Error: $e');
      _history.removeLast();
      return _fallbackResponse(userMessage);
    }
  }

  Future<String> analyseIncident({
    required String type,
    required String severity,
    required String location,
    required String description,
  }) => chat(
    'Analyse this hospitality crisis:\n'
    'Type: $type | Severity: $severity | Location: $location\n'
    'Description: $description\n\n'
    'Give: 1) Immediate actions (0-5 min) 2) Personnel deployment 3) Guest communication template',
  );

  void clearHistory() => _history.clear();

  Future<String> _callApi() async {
    final url = Uri.parse('$_baseUrl/models/$_modelId/v1/chat/completions');
    final messages = [
      {'role': 'system', 'content': _systemPrompt},
      ..._history,
    ];
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $_hfToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': _modelId,
        'messages': messages,
        'max_tokens': 512,
        'temperature': 0.7,
        'stream': false,
      }),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = data['choices'] as List<dynamic>;
      if (choices.isNotEmpty) {
        return (choices[0]['message']['content'] as String).trim();
      }
    } else if (response.statusCode == 503) {
      return await _callLegacyApi(_history.last['content']!);
    }
    throw Exception('HF API ${response.statusCode}');
  }

  Future<String> _callLegacyApi(String prompt) async {
    final url = Uri.parse('$_baseUrl/models/$_modelId');
    final formatted = '<start_of_turn>user\n$prompt<end_of_turn>\n<start_of_turn>model\n';
    final response = await http.post(
      url,
      headers: {'Authorization': 'Bearer $_hfToken', 'Content-Type': 'application/json'},
      body: jsonEncode({'inputs': formatted, 'parameters': {'max_new_tokens': 400}}),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List<dynamic>;
      if (data.isNotEmpty) {
        final raw = data[0]['generated_text'] as String;
        const marker = '<start_of_turn>model\n';
        final idx = raw.lastIndexOf(marker);
        return idx >= 0 ? raw.substring(idx + marker.length).trim() : raw.trim();
      }
    }
    throw Exception('Legacy API ${response.statusCode}');
  }

  String _fallbackResponse(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('fire')) {
      return '🔥 **Fire Response Protocol**\n\n'
          '**Immediate Actions (0–5 min)**\n'
          '1. Activate fire alarm system\n'
          '2. Call emergency services (911)\n'
          '3. Deploy Security to affected floor\n'
          '4. Initiate stairwell evacuation\n\n'
          '**Personnel**\n'
          '• Security: Zone containment & evacuation\n'
          '• Medical: Lobby triage station\n'
          '• Front Desk: Account for all guests\n\n'
          '**Guest Message:** "Please proceed calmly to the nearest exit. Do not use elevators."';
    }
    if (lower.contains('medical')) {
      return '🏥 **Medical Emergency Protocol**\n\n'
          '1. Call 911 immediately\n'
          '2. Deploy on-site medical team\n'
          '3. Retrieve AED from nearest station\n'
          '4. Clear area for emergency access\n\n'
          '**Personnel:** Medical team to scene, Security to manage access route.';
    }
    if (lower.contains('security') || lower.contains('intruder')) {
      return '🔒 **Security Breach Protocol**\n\n'
          '1. Alert all security personnel immediately\n'
          '2. Lock down affected areas\n'
          '3. Call law enforcement (911)\n'
          '4. Move guests away from affected zone\n\n'
          '**Do NOT confront the individual directly.**';
    }
    return '⚠️ **CrisisSync AI – Demo Mode**\n\n'
        'Configure your HuggingFace token in `gemma_service.dart` to enable live AI responses.\n\n'
        'I can help with:\n• Incident analysis & action plans\n• Personnel deployment\n• Guest communications\n• Evacuation guidance';
  }
}
