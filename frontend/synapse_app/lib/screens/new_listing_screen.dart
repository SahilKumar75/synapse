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
      // Go back to the previous screen and signal success
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create listing.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Listing'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Waste Description (e.g., "500kg of plastic scrap")',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Search Location',
                  border: OutlineInputBorder(),
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
              if (_isSearching) const LinearProgressIndicator(),
              if (_placeSuggestions.isNotEmpty)
                Container(
                  height: 150,
                  child: ListView.builder(
                    itemCount: _placeSuggestions.length,
                    itemBuilder: (context, index) {
                      final suggestion = _placeSuggestions[index];
                      return ListTile(
                        title: Text(suggestion['description']),
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
                          }
                        },
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
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
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Listing Type:'),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButton<String>(
                      value: _listingType,
                      items: const [
                        DropdownMenuItem(value: 'OFFER', child: Text('Offer')),
                        DropdownMenuItem(value: 'REQUEST', child: Text('Request')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _listingType = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitListing,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                ),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Submit Listing'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}