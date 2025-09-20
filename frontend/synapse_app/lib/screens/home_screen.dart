// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import '../widgets/account_icon_button.dart';
import '../widgets/notification_icon_button.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'login_screen.dart';
import 'new_listing_screen.dart';
import 'matches_screen.dart';
import 'listing_details_screen.dart';
import '../services/auth_service.dart';
import '../services/listing_service.dart';
import 'my_listings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
  // User info state
  Map<String, dynamic>? _userInfo;
  bool _showUserCard = false;

  Future<void> _fetchUserInfo() async {
    final user = await _authService.getCurrentUser();
    if (mounted && user != null) {
      setState(() {
        _userInfo = user;
      });
    }
  }
  void _updateMarkers(List<Listing> listings) {
    // Group listings by coordinates
    Map<String, List<Listing>> coordMap = {};
    for (var listing in listings) {
      final coords = listing.coordinates;
      final key = '${coords.latitude},${coords.longitude}';
      coordMap.putIfAbsent(key, () => []).add(listing);
    }
    final markers = coordMap.entries.map((entry) {
      final listingsAtLocation = entry.value;
      final firstListing = listingsAtLocation.first;
      BitmapDescriptor markerColor;
      switch (firstListing.listingType.toUpperCase()) {
        case 'OFFER':
          markerColor = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
          break;
        case 'REQUEST':
          markerColor = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
          break;
        default:
          markerColor = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
      }
      LatLng coords = firstListing.coordinates;
      if (coords.latitude == 0 && coords.longitude == 0) {
        coords = LatLng(18.5204, 73.8567); // Pune center
      }
      return Marker(
        markerId: MarkerId(entry.key),
        position: coords,
        icon: markerColor,
        onTap: () {
          if (listingsAtLocation.length == 1) {
            setState(() {
              _selectedListing = firstListing;
            });
          } else {
            // Show bottom sheet with all listings at this location
            showModalBottomSheet(
              context: context,
              builder: (context) {
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text('Listings at this location', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ...listingsAtLocation.map((listing) => Card(
                      child: ListTile(
                        title: Text(listing.companyName),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(listing.description),
                            Text('Location: ${listing.location}'),
                          ],
                        ),
                        trailing: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            setState(() {
                              _selectedListing = listing;
                            });
                          },
                          child: const Text('View'),
                        ),
                      ),
                    ))
                  ],
                );
              },
            );
          }
        },
        infoWindow: InfoWindow(
          title: listingsAtLocation.length == 1
              ? firstListing.description
              : '${listingsAtLocation.length} listings here',
          snippet: listingsAtLocation.length == 1
              ? '${firstListing.companyName} - ${firstListing.location}'
              : '',
        ),
      );
    }).toSet();
    setState(() {
      _markers = markers;
    });
  }
  String _filterType = 'All';
  String _filterRegion = '';
  List<Map<String, dynamic>> _newListings = [];
  GoogleMapController? _mapController;
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
  Listing? _selectedListing;
  List<Listing> _allListings = [];

  // Pune's coordinates
  static const CameraPosition _puneCameraPosition = CameraPosition(
    target: LatLng(18.5204, 73.8567),
    zoom: 11.0,
  );

  @override
  void initState() {
    super.initState();
    _initUserAndListings();
  }

  Future<void> _initUserAndListings() async {
    await _fetchUserInfo();
    await _fetchListingsAndCreateMarkers();
  }

  Future<void> _fetchListingsAndCreateMarkers() async {
    if (mounted) setState(() { _isLoading = true; });

    final listings = await _listingService.getListings();
    _allListings = listings;
    // Debug print: show all listings and their coordinates
    for (var listing in _allListings) {
      print('[DEBUG] Listing: id=${listing.id}, type=${listing.listingType}, company=${listing.companyName}, desc=${listing.description}, loc=${listing.location}, coords=${listing.coordinates.latitude},${listing.coordinates.longitude}');
    }
    // Do not update markers here; markers will be updated after filtering in the card list
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateAndRefresh() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NewListingScreen()),
    );
    if (result != null && result is Map && result['success'] == true) {
      // If location is provided, store info for marker persistence
      if (result['location'] != null && result['location'] is LatLng) {
        _newListings.add({
          'location': result['location'],
          'description': result['description'] ?? 'New Listing',
          'listingType': result['listingType'] ?? '',
        });
        await Future.delayed(const Duration(milliseconds: 300));
        if (_mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(result['location'], 14),
          );
        }
      }
      // Refresh all markers from backend (will re-add all new markers)
      await _fetchListingsAndCreateMarkers();
    } else if (result == true) {
      _fetchListingsAndCreateMarkers();
    }
  }

  void _logout() async {
    await _authService.logout();
    if (mounted) {
      setState(() {
        _filterType = 'All';
        _filterRegion = '';
      });
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
          AccountIconButton(
            onPressed: () async {
              await _fetchUserInfo();
              setState(() {
                _showUserCard = true;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.list),
            tooltip: 'My Listings',
            onPressed: () {
              debugPrint('[DEBUG] My Listings button (AppBar) pressed');
              if (_userInfo != null && _userInfo!['_id'] != null) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => MyListingsScreen(userId: _userInfo!['_id']),
                  ),
                );
              } else {
                debugPrint('[ERROR] _userInfo or _userInfo[\'_id\'] is null');
              }
            },
          ),
          NotificationIconButton(),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          )
        ],
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : GoogleMap(
                  initialCameraPosition: _puneCameraPosition,
                  markers: _markers,
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                ),
          // User details card overlay
          if (_showUserCard && _userInfo != null)
            Positioned(
              top: 16,
              right: 16,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {}, // Prevent tap-through
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 280,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Account Details', style: Theme.of(context).textTheme.titleMedium),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                setState(() {
                                  _showUserCard = false;
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // ...existing code...
                        Text('Name: ${_userInfo!['name']}'),
                        Text('Email: ${_userInfo!['email']}'),
                        Text('Company: ${_userInfo!['company']}'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          // Dismiss card when tapping outside
          if (_showUserCard)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _showUserCard = false;
                  });
                },
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ),
          Positioned(
            top: 16,
            left: 16,
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (_) {},
              onPointerMove: (_) {},
              onPointerUp: (_) {},
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 320,
                  constraints: const BoxConstraints(maxHeight: 400),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _selectedListing == null
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('All Listings', style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                DropdownButton<String>(
                                  value: _filterType,
                                  items: const [
                                    DropdownMenuItem(value: 'All', child: Text('All')),
                                    DropdownMenuItem(value: 'Offer', child: Text('Offer')),
                                    DropdownMenuItem(value: 'Request', child: Text('Request')),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) setState(() => _filterType = val);
                                  },
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextField(
                                    decoration: const InputDecoration(
                                      labelText: 'Region/Location',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                    onChanged: (val) {
                                      setState(() => _filterRegion = val);
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 250,
                              child: Builder(
                                builder: (context) {
                                  final currentUserId = _userInfo?['_id'];
                                  final filteredListings = _allListings.where((listing) {
                                    dynamic postedBy = listing.postedBy;
                                    String? postedById;
                                    if (postedBy is Map<String, dynamic>) {
                                      postedById = postedBy['_id'];
                                    } else if (postedBy is String) {
                                      postedById = postedBy;
                                    }
                                    // ...existing code...
                                    if (postedById != null && currentUserId != null && postedById == currentUserId) return false;
                                    final typeMatch = _filterType == 'All' ||
                                      listing.listingType.toLowerCase() == _filterType.toLowerCase();
                                    final regionMatch = _filterRegion.isEmpty ||
                                      listing.location.toLowerCase().contains(_filterRegion.toLowerCase());
                                    return typeMatch && regionMatch;
                                  }).toList();
                                  // Update markers to match filtered listings
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    _updateMarkers(filteredListings);
                                  });
                                  if (filteredListings.isEmpty) {
                                    return const Center(child: Text('No listings found.'));
                                  }
                                  return ListView.builder(
                                    itemCount: filteredListings.length,
                                    itemBuilder: (context, index) {
                                      final listing = filteredListings[index];
                                      Color borderColor;
                                      switch (listing.listingType.toLowerCase()) {
                                        case 'offer':
                                          borderColor = Colors.green;
                                          break;
                                        case 'request':
                                          borderColor = Colors.orange;
                                          break;
                                        default:
                                          borderColor = Colors.grey;
                                      }
                                      return Container(
                                        margin: const EdgeInsets.symmetric(vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border(
                                            left: BorderSide(color: borderColor, width: 6),
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black12,
                                              blurRadius: 2,
                                              offset: Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                        child: ListTile(
                                          title: Text(listing.companyName),
                                          subtitle: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(listing.description),
                                              Text('Location: ${listing.location}'),
                                            ],
                                          ),
                                          trailing: ElevatedButton(
                                            onPressed: () {
                                              setState(() {
                                                _selectedListing = listing;
                                              });
                                            },
                                            child: const Text('View'),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _selectedListing!.companyName,
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.arrow_back),
                                  onPressed: () {
                                    setState(() {
                                      _selectedListing = null;
                                    });
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _selectedListing!.description,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 8),
                            Text('Location: ${_selectedListing!.location}'),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    _showFindMatchesDialog(_selectedListing!);
                                  },
                                  child: const Text('Find Matches'),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ListingDetailsScreen(listing: _selectedListing!),
                                      ),
                                    );
                                    if (result == true) {
                                      setState(() {
                                        _selectedListing = null;
                                      });
                                      await _fetchListingsAndCreateMarkers();
                                    }
                                  },
                                  child: const Text('Details'),
                                ),
                              ],
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateAndRefresh,
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
      ),
    );
  }
}