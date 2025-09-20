// lib/services/listing_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Listing {
  final String id;
  final String description;
  final String location;
  final String companyName;
  final LatLng coordinates;
  final String listingType;

  Listing({
    required this.id,
    required this.description,
    required this.location,
    required this.companyName,
    required this.coordinates,
    required this.listingType,
  });

  factory Listing.fromJson(Map<String, dynamic> json) {
    // Default to Pune coordinates if none are provided or invalid
    double lat = 18.5204;
    double lng = 73.8567;
    if (json['geolocation'] != null && json['geolocation']['coordinates'] != null) {
      try {
        final coords = json['geolocation']['coordinates'];
        if (coords is List && coords.length == 2) {
          lng = coords[0].toDouble();
          lat = coords[1].toDouble();
          // If coordinates are [0,0], use Pune center
          if (lat == 0 && lng == 0) {
            lat = 18.5204;
            lng = 73.8567;
          }
        }
      } catch (_) {
        lat = 18.5204;
        lng = 73.8567;
      }
    }

    return Listing(
      id: json['_id'] ?? '',
      description: json['description'] ?? 'No description',
      location: json['location'] ?? 'No location',
      companyName: json['postedBy']?['company'] ?? 'Unknown Company',
      coordinates: LatLng(lat, lng),
      listingType: json['listingType'] ?? '',
    );
  }
}

class ListingService {
  Future<List<Map<String, dynamic>>> getMatches(String listingId) async {
    try {
      String? token = await _storage.read(key: 'token');
      final response = await http.get(
        Uri.parse('$_baseUrl/$listingId/matches'),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token ?? '',
        },
      );
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => json as Map<String, dynamic>).toList();
      } else {
        return [];
      }
    } catch (e) {
      print(e.toString());
      return [];
    }
  }
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

  Future<bool> createListing(String description, String location, String listingType) async {
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
          'listingType': listingType,
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