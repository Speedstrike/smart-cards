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
import 'package:supabase_flutter/supabase_flutter.dart';

class Config {
  static late String apiKey;
  static late String topicPrompt;
  static late String textPrompt;

  static Future<void> load() async {
    try {
      final response = await Supabase.instance.client.functions.invoke('smart-api', body: {'name': 'Functions'});
      final data = response.data as Map<String, dynamic>;

      apiKey = data['apiKey'] as String? ?? '';
      topicPrompt = data['topicPrompt'] as String? ?? '';
      textPrompt = data['textPrompt'] as String? ?? '';

      if (apiKey.isEmpty) throw Exception('apiKey missing');
      if (topicPrompt.isEmpty) throw Exception('topicPrompt missing');
      if (textPrompt.isEmpty) throw Exception('textPrompt missing');
    }
    catch (e) {
      throw Exception('Failed to load configuration: $e');
    }
  }

  static String getTopicPrompt({required String topic, required int count}) => topicPrompt.replaceAll('{topic}', topic).replaceAll('{count}', count.toString());

  static String getTextPrompt({required String text, required int count}) => textPrompt.replaceAll('{text}', text).replaceAll('{count}', count.toString());
}