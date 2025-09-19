// lib/services/listing_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// A simple class to hold our listing data
class Listing {
  final String description;
  final String location;
  final String companyName;

  Listing({
    required this.description,
    required this.location,
    required this.companyName,
  });

  factory Listing.fromJson(Map<String, dynamic> json) {
    return Listing(
      description: json['description'] ?? 'No description',
      location: json['location'] ?? 'No location',
      // Data from the 'populate' function on the backend
      companyName: json['postedBy']?['company'] ?? 'Unknown Company',
    );
  }
}

class ListingService {
  final String _baseUrl = 'http://localhost:5001/api/listings';
  final _storage = const FlutterSecureStorage();

  Future<List<Listing>> getListings() async {
    try {
      // We get the token to prove we're logged in, even for public routes
      String? token = await _storage.read(key: 'token');

      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token ?? '',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Listing.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print(e.toString());
      return [];
    }
  }
}