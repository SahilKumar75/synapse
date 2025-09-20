// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'login_screen.dart';
import 'new_listing_screen.dart';
import '../services/auth_service.dart';
import '../services/listing_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ListingService _listingService = ListingService();
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  Set<Marker> _markers = {};

  // Pune's coordinates
  static const CameraPosition _puneCameraPosition = CameraPosition(
    target: LatLng(18.5204, 73.8567),
    zoom: 11.0,
  );

  @override
  void initState() {
    super.initState();
    _fetchListingsAndCreateMarkers();
  }

  Future<void> _fetchListingsAndCreateMarkers() async {
    setState(() { _isLoading = true; });

    final listings = await _listingService.getListings();
    final markers = listings.map((listing) {
      return Marker(
        markerId: MarkerId(listing.id),
        position: listing.coordinates,
        infoWindow: InfoWindow(
          title: listing.description,
          snippet: '${listing.companyName} - ${listing.location}',
        ),
      );
    }).toSet();

    if (mounted) {
      setState(() {
        _markers = markers;
        _isLoading = false;
      });
    }
  }

  void _navigateAndRefresh() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NewListingScreen()),
    );
    if (result == true) {
      _fetchListingsAndCreateMarkers();
    }
  }

  void _logout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Synapse Map'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              initialCameraPosition: _puneCameraPosition,
              markers: _markers,
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateAndRefresh,
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
      ),
    );
  }
}