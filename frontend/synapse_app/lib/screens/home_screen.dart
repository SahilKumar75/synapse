// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'login_screen.dart';
import 'new_listing_screen.dart';
import 'matches_screen.dart';
import '../services/auth_service.dart';
import '../services/listing_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  void _navigateToMatchesScreen(String listingId) async {
    // Fetch matches from backend and navigate
    final matches = await _listingService.getMatches(listingId);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MatchesScreen(matches: matches),
      ),
    );
  }

  void _showFindMatchesDialog(Listing listing) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Find Matches'),
          content: Text('Find matches for this listing?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _navigateToMatchesScreen(listing.id);
              },
              child: const Text('Find Matches'),
            ),
          ],
        );
      },
    );
  }
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
      BitmapDescriptor markerColor = BitmapDescriptor.defaultMarker;
        if (listing.listingType == 'OFFER') {
          markerColor = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
        } else if (listing.listingType == 'REQUEST') {
          markerColor = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
        }
        markerColor = listing.listingType == 'OFFER' ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen) : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
      return Marker(
        markerId: MarkerId(listing.id),
        position: listing.coordinates,
        icon: markerColor,
        infoWindow: InfoWindow(
          title: listing.description,
          snippet: '${listing.companyName} - ${listing.location}',
          onTap: () {
            _showFindMatchesDialog(listing);
          },
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