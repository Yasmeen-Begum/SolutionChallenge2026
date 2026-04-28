import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/message.dart';

class N8nIntegrationService {
  N8nIntegrationService._();
  static final instance = N8nIntegrationService._();

  // Replace with your n8n webhook URL
  String _webhookUrl = 'https://your-n8n-instance.com/webhook/crisis-sync';
  String? _apiKey;

  void configure({required String url, String? apiKey}) {
    _webhookUrl = url;
    _apiKey = apiKey;
  }

  /// Sends a crisis alert to the n8n workflow
  Future<bool> broadcastToExternalChannels({
    required String incidentTitle,
    required String description,
    required String severity,
    required List<String> channels, // ['whatsapp', 'slack', 'gmail']
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_webhookUrl),
        headers: {
          'Content-Type': 'application/json',
          if (_apiKey != null) 'X-N8N-API-KEY': _apiKey!,
        },
        body: jsonEncode({
          'timestamp': DateTime.now().toIso8601String(),
          'type': 'CRISIS_ALERT',
          'severity': severity,
          'title': incidentTitle,
          'message': description,
          'target_channels': channels,
          'metadata': {
            'source': 'CrisisSync_EOC',
            'priority': severity == 'critical' ? 'P0' : 'P1',
          }
        }),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('n8n Integration Error: $e');
      return false;
    }
  }
}
