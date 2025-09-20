import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class NotificationService {
  final String _baseUrl = 'http://localhost:5001/api/notifications';
  final _storage = const FlutterSecureStorage();

  Future<bool> sendNotification({required String receiverId, required String message}) async {
    try {
      String? token = await _storage.read(key: 'token');
      if (token == null) return false;
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token,
        },
        body: jsonEncode({
          'receiverId': receiverId,
          'message': message,
        }),
      );
      return response.statusCode == 201;
    } catch (e) {
      print(e.toString());
      return false;
    }
  }
  Future<List<Map<String, dynamic>>> getNotifications() async {
    try {
      String? token = await _storage.read(key: 'token');
      if (token == null) return [];
      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token,
        },
      );
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => e as Map<String, dynamic>).toList();
      }
      return [];
    } catch (e) {
      print(e.toString());
      return [];
    }
  }
}
