import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ChatGPTService {
  late final String _apiKey;
  final String apiUrl = 'https://api.openai.com/v1/chat/completions';

  ChatGPTService() {
    _apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
  }

  Future<String> generateResponse(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [{'role': 'user', 'content': prompt}],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to generate response: $e');
    }
  }
}