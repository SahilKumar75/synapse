import 'dart:convert';
import 'package:http/http.dart' as http;

Future<String?> getGeminiMatchScore(String prompt) async {
  final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=AIzaSyC-zDG5ss2NZkm4IrnBSrXcL0lCRGoKkyg');
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'contents': [
        {'parts': [{'text': prompt}]}
      ]
    }),
  );
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['candidates'][0]['content']['parts'][0]['text'];
  } else {
    print('Error: ${response.body}');
    return null;
  }
}
