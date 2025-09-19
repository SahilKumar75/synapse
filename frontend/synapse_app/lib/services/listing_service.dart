// lib/services/listing_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Listing {
  final String id;
  final String description;
  final String location;
  final String companyName;

  Listing({
    required this.id,
    required this.description,
    required this.location,
    required this.companyName,
  });

  factory Listing.fromJson(Map<String, dynamic> json) {
    return Listing(
      id: json['_id'] ?? '',
      description: json['description'] ?? 'No description',
      location: json['location'] ?? 'No location',
      companyName: json['postedBy']?['company'] ?? 'Unknown Company',
    );
  }
}

class ListingService {
  final String _baseUrl = 'http://localhost:5001/api/listings';
  final _storage = const FlutterSecureStorage();

  Future<List<Listing>> getListings() async {
    try {
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

  Future<bool> createListing(String description, String location) async {
    try {
      String? token = await _storage.read(key: 'token');
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token ?? '',
        },
        body: jsonEncode({
          'description': description,
          'location': location,
        }),
      );
      return response.statusCode == 201;
    } catch (e) {
      print(e.toString());
      return false;
    }
  }

  // lib/services/listing_service.dart
// Add this method to the ListingService class

  Future<bool> updateListing(String id, String description, String location) async {
    try {
      String? token = await _storage.read(key: 'token');
      final response = await http.put(
        Uri.parse('$_baseUrl/$id'),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token ?? '',
        },
        body: jsonEncode({
          'description': description,
          'location': location,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print(e.toString());
      return false;
    }
  }

  Future<bool> deleteListing(String listingId) async {
    try {
      String? token = await _storage.read(key: 'token');
      final response = await http.delete(
        Uri.parse('$_baseUrl/$listingId'),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token ?? '',
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      print(e.toString());
      return false;
    }
  }
}