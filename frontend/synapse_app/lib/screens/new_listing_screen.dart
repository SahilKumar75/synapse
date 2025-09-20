// lib/screens/new_listing_screen.dart

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:google_maps_webservice/places.dart';
import '../services/listing_service.dart'; // <-- CORRECTED IMPORT

class NewListingScreen extends StatefulWidget {
  const NewListingScreen({super.key});

  @override
  State<NewListingScreen> createState() => _NewListingScreenState();
}

class _NewListingScreenState extends State<NewListingScreen> {
  GoogleMapController? _mapController;
  List<dynamic> _placeSuggestions = [];
  bool _isSearching = false;
  final String _placesApiBase = 'http://localhost:5001/api/places';
  static const kGoogleApiKey = 'AIzaSyDSKfX62OR56G4BZnAVtr_FzcvoIwA9IZI';
  GoogleMapsPlaces _places = GoogleMapsPlaces(apiKey: kGoogleApiKey);
  LatLng? _selectedLatLng;
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final ListingService _listingService = ListingService();
  bool _isLoading = false;
  String _listingType = 'OFFER';

  Future<void> _submitListing() async {
    if (_descriptionController.text.isEmpty || _locationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out all fields.')),
      );
      return;
    }

    setState(() { _isLoading = true; });

    final success = await _listingService.createListing(
      _descriptionController.text,
      _locationController.text,
      _listingType,
    );

    if (!mounted) return;

    setState(() { _isLoading = false; });

    if (success) {
      // Show congratulation dialog
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Congratulations!'),
          content: const Text('Your listing has been created successfully.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      // Pass location back to previous screen
      Navigator.pop(context, {
        'success': true,
        'location': _selectedLatLng,
        'description': _descriptionController.text,
        'listingType': _listingType,
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create listing.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sfPro = const TextStyle(
      fontFamily: 'SFPRODISPLAYREGULAR',
      fontSize: 17,
      color: Color(0xFF222222),
    );
    final sfProBold = const TextStyle(
      fontFamily: 'SFPRODISPLAYBOLD',
      fontSize: 20,
      color: Color(0xFF222222),
    );
    final bgColor = const Color(0xFFF8F8F8);
    final accentColor = const Color(0xFF007AFF); // iOS blue
    final borderRadius = BorderRadius.circular(14);
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Create New Listing', style: TextStyle(fontFamily: 'SFPRODISPLAYBOLD', fontSize: 20, color: Color(0xFF222222))),
        backgroundColor: bgColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF222222)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _descriptionController,
                style: sfPro,
                decoration: InputDecoration(
                  labelText: 'Waste Description (e.g., "500kg of plastic scrap")',
                  labelStyle: sfPro,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: borderRadius,
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _locationController,
                style: sfPro,
                decoration: InputDecoration(
                  labelText: 'Search Location',
                  labelStyle: sfPro,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: borderRadius,
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                ),
                onChanged: (value) async {
                  if (value.isEmpty) {
                    setState(() { _placeSuggestions = []; });
                    return;
                  }
                  setState(() { _isSearching = true; });
                  final url = '$_placesApiBase/autocomplete?input=$value';
                  final response = await http.get(Uri.parse(url));
                  if (response.statusCode == 200) {
                    final data = json.decode(response.body);
                    setState(() {
                      _placeSuggestions = data['predictions'];
                      _isSearching = false;
                    });
                  } else {
                    setState(() { _isSearching = false; });
                  }
                },
              ),
              if (_isSearching)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: LinearProgressIndicator(color: Color(0xFF007AFF)),
                ),
              if (_placeSuggestions.isNotEmpty)
                Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: borderRadius,
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
                  ),
                  child: ListView.builder(
                    itemCount: _placeSuggestions.length,
                    itemBuilder: (context, index) {
                      final suggestion = _placeSuggestions[index];
                      return ListTile(
                        title: Text(suggestion['description'], style: sfPro),
                        onTap: () async {
                          _locationController.text = suggestion['description'];
                          setState(() { _placeSuggestions = []; });
                          // Get place details for coordinates via backend
                          final placeId = suggestion['place_id'];
                          final detailsUrl = '$_placesApiBase/details?placeId=$placeId';
                          final detailsResponse = await http.get(Uri.parse(detailsUrl));
                          if (detailsResponse.statusCode == 200) {
                            final detailsData = json.decode(detailsResponse.body);
                            final location = detailsData['result']['geometry']['location'];
                            setState(() {
                              _selectedLatLng = LatLng(location['lat'], location['lng']);
                            });
                            // Animate map to selected location
                            await Future.delayed(const Duration(milliseconds: 200));
                            if (_mapController != null) {
                              _mapController!.animateCamera(
                                CameraUpdate.newLatLngZoom(LatLng(location['lat'], location['lng']), 14),
                              );
                            }
                          }
                        },
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: borderRadius,
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
                ),
                child: ClipRRect(
                  borderRadius: borderRadius,
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _selectedLatLng ?? LatLng(18.5204, 73.8567),
                      zoom: 13,
                    ),
                    markers: _selectedLatLng == null
                        ? {}
                        : {
                            Marker(
                              markerId: const MarkerId('selected'),
                              position: _selectedLatLng!,
                            ),
                          },
                    onTap: (latLng) {
                      setState(() {
                        _selectedLatLng = latLng;
                      });
                    },
                    onMapCreated: (controller) {
                      _mapController = controller;
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text('Listing Type:', style: sfProBold),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: borderRadius,
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _listingType,
                          style: sfPro,
                          items: const [
                            DropdownMenuItem(value: 'OFFER', child: Text('Offer', style: TextStyle(fontFamily: 'SFPRODISPLAYREGULAR'))),
                            DropdownMenuItem(value: 'REQUEST', child: Text('Request', style: TextStyle(fontFamily: 'SFPRODISPLAYREGULAR'))),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _listingType = val);
                          },
                          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF007AFF)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitListing,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: borderRadius),
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Submit Listing', style: TextStyle(fontFamily: 'SFPRODISPLAYBOLD', fontSize: 17, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}