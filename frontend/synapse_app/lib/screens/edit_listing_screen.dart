// lib/screens/edit_listing_screen.dart

import 'package:flutter/material.dart';
import '../services/listing_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';

class EditListingScreen extends StatefulWidget {
  final Listing listing;
  const EditListingScreen({super.key, required this.listing});

  @override
  State<EditListingScreen> createState() => _EditListingScreenState();
}

class _EditListingScreenState extends State<EditListingScreen> {
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  final ListingService _listingService = ListingService();
  bool _isLoading = false;
  GoogleMapController? _mapController;
  List<dynamic> _placeSuggestions = [];
  bool _isSearching = false;
  static const kGoogleApiKey = 'AIzaSyDSKfX62OR56G4BZnAVtr_FzcvoIwA9IZI';
  GoogleMapsPlaces _places = GoogleMapsPlaces(apiKey: kGoogleApiKey);
  LatLng? _selectedLatLng;
  final String _placesApiBase = 'http://localhost:5001/api/places';

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(text: widget.listing.description);
    _locationController = TextEditingController(text: widget.listing.location);
    // Set initial marker position if available
    if (widget.listing.coordinates.latitude != 0 && widget.listing.coordinates.longitude != 0) {
      _selectedLatLng = widget.listing.coordinates;
    }
  }

  Future<void> _updateListing() async {
    setState(() { _isLoading = true; });

    final success = await _listingService.updateListing(
      widget.listing.id,
      _descriptionController.text,
      _locationController.text,
    );

    if (!mounted) return;
    setState(() { _isLoading = false; });

    if (success) {
      Navigator.pop(context, true); // Go back and signal success
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update listing.')),
      );
    }
  }
  
  @override
  void dispose() {
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Listing'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Search Location', border: OutlineInputBorder()),
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
              if (_placeSuggestions != null && _placeSuggestions.isNotEmpty)
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
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _updateListing,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                ),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Update Listing'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}