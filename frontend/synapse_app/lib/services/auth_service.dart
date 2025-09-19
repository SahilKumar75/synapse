// frontend/synapse/lib/services/auth_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  // For Android Emulator, use 10.0.2.2. For web or physical device, use your computer's IP address.
  // lib/services/auth_service.dart
final String _baseUrl = 'http://localhost:5001/api/users';
  final _storage = const FlutterSecureStorage();

  Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _storage.write(key: 'token', value: data['token']);
        return true;
      }
      return false;
    } catch (e) {
      print(e.toString());
      return false;
    }
  }
}