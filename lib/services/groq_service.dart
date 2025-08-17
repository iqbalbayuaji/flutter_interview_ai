import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GroqService {
  GroqService();

  static const _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static String get _model =>
      (dotenv.env['GROQ_MODEL']?.trim() ?? 'llama-3.1-8b-instant');

  final String _apiKey = dotenv.env['GROQ_API_KEY']?.trim() ?? '';

  Future<String> chat(List<Map<String, String>> messages) async {
    if (_apiKey.isEmpty) {
      throw Exception('GROQ_API_KEY not provided. Run with --dart-define=GROQ_API_KEY=...');
    }

    final uri = Uri.parse(_baseUrl);
    final body = jsonEncode({
      'model': _model,
      'messages': messages,
      'temperature': 0.2,
    });

    final res = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: body,
    );

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final choices = data['choices'] as List?;
      if (choices == null || choices.isEmpty) {
        throw Exception('No response from Groq');
      }
      final content = choices.first['message']?['content'] as String?;
      if (content == null) {
        throw Exception('Invalid Groq response payload');
      }
      return content.trim();
    }

    throw Exception('Groq error ${res.statusCode} (model: '+_model+'): ${res.body}');
  }
}
