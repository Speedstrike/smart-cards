// MIT License
//
// Copyright (c) 2026 Aaryan Karlapalem
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
import 'package:http/http.dart' as http;

import 'dart:convert';
import 'dart:io';

import 'config.dart';

class Flashcard {
  final String question;
  final String answer;

  Flashcard({required this.question, required this.answer});

  factory Flashcard.fromJson(Map<String, dynamic> json) {
    return Flashcard(
      question: json['question'] as String? ?? '',
      answer: json['answer'] as String? ?? ''
    );
  }
}

class OpenRouter {
  static const String _model = 'openai/gpt-3.5-turbo';

  static Future<List<Flashcard>> generateFlashcards({required String topic, required int count,}) async {
    final prompt = Config.getTopicPrompt(topic: topic, count: count);

    try {
      final body = jsonEncode({
        'model': _model,
        'messages': [
          {'role': 'user', 'content': prompt}
        ],
        'temperature': 0.7
      });

      final response = await http
          .post(
            Uri.https('openrouter.ai', '/api/v1/chat/completions'),
            headers: {
              'Authorization': 'Bearer ${Config.apiKey}',
              'Content-Type': 'application/json',
              'HTTP-Referer': 'https://smartcards.local',
              'X-OpenRouter-Title': 'Smart Cards App'
            },
            body: body
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;

        final jsonMatch = RegExp(r'\[[\s\S]*\]', multiLine: true).firstMatch(content);
        if (jsonMatch != null) {
          final jsonArray = jsonDecode(jsonMatch.group(0)!);
          return (jsonArray as List).map((item) => Flashcard.fromJson(item as Map<String, dynamic>)).toList();
        }
        throw Exception('Invalid response format');
      }
      else {
        try {
          final error = jsonDecode(response.body);
          throw Exception(error['error']?['message'] ?? 'Failed to generate flashcards');
        }
        catch (e) {
          throw Exception('HTTP ${response.statusCode}: ${response.body}');
        }
      }
    }
    on SocketException catch (e) {
      throw Exception('Network error: ${e.message}. Check your internet connection.');
    }
    on HttpException catch (e) {
      throw Exception('HTTP Error: $e');
    }
    catch (e) {
      rethrow;
    }
  }

  static Future<List<Flashcard>> processText({required String text, required int count,}) async {
    final prompt = Config.getTextPrompt(text: text, count: count);

    try {
      final body = jsonEncode({
        'model': _model,
        'messages': [
          {'role': 'user', 'content': prompt}
        ],
        'temperature': 0.7
      });

      final response = await http
        .post(
          Uri.https('openrouter.ai', '/api/v1/chat/completions'),
          headers: {
            'Authorization': 'Bearer ${Config.apiKey}',
            'Content-Type': 'application/json',
            'HTTP-Referer': 'https://smartcards.local',
            'X-OpenRouter-Title': 'Smart Cards App'
          },
          body: body,
        ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;

        final jsonMatch = RegExp(r'\[[\s\S]*\]',multiLine: true).firstMatch(content);
        if (jsonMatch != null) {
          final jsonArray = jsonDecode(jsonMatch.group(0)!);
          return (jsonArray as List).map((item) => Flashcard.fromJson(item as Map<String, dynamic>)).toList();
        }
        throw Exception('Invalid response format');
      }
      else {
        try {
          final error = jsonDecode(response.body);
          throw Exception(error['error']?['message'] ?? 'Failed to process text');
        }
        catch (e) {
          throw Exception('HTTP ${response.statusCode}: ${response.body}');
        }
      }
    }
    on SocketException catch (e) {
      throw Exception('Network error: ${e.message}. Check your internet connection.');
    }
    on HttpException catch (e) {
      throw Exception('HTTP Error: $e');
    }
    catch (e) {
      rethrow;
    }
  }
}