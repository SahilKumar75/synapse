// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import '../widgets/account_icon_button.dart';
import '../widgets/notification_icon_button.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'login_screen.dart';
import 'new_listing_screen.dart';
import 'matches_screen.dart';
import 'listing_details_screen.dart';
import '../services/auth_service.dart';
import '../services/listing_service.dart';
import 'my_listings_screen.dart';
import '../widgets/listing_card.dart';

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
                    const SizedBox(height: 180),
                    ...listingsAtLocation.map((listing) => ListingCard(
                      listing: listing,
                      borderColor: (() {
                        switch (listing.listingType.toLowerCase()) {
                          case 'offer':
                            return Colors.green;
                          case 'request':
                            return Colors.orange;
                          default:
                            return Colors.grey;
                        }
                      })(),
                      onView: () {
                        Navigator.pop(context);
                        setState(() {
                          _selectedListing = listing;
                        });
                      },
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: SizedBox(
                height: 32,
                width: 32,
                child: SvgPicture.asset(
                  'assets/logo.svg',
                ),
              ),
            ),
            Text(
              'Synapse',
              style: const TextStyle(
                fontFamily: 'SF Pro Display',
                fontWeight: FontWeight.w700,
                fontSize: 24,
                color: Colors.black,
              ),
            ),
          ],
        ),
        actions: [
          AccountIconButton(
            onPressed: () async {
              await _fetchUserInfo();
              setState(() {
                _showUserCard = true;
              });
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
                        ElevatedButton.icon(
                          icon: const Icon(Icons.list),
                          label: const Text('My Listings'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                          ),
                          onPressed: () {
                            if (_userInfo != null && _userInfo!['_id'] != null) {
                              setState(() {
                                _showUserCard = false;
                              });
                              Future.delayed(const Duration(milliseconds: 200), () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MyListingsScreen(userId: _userInfo!['_id']),
                                  ),
                                );
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 8),
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
            top: MediaQuery.of(context).padding.top + kToolbarHeight + 16,
            left: 16,
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (_) {},
              onPointerMove: (_) {},
              onPointerUp: (_) {},
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 480,
                  constraints: const BoxConstraints(minHeight: 420, maxHeight: 600),
                  padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 32),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: _selectedListing == null
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('All Listings', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, fontFamily: 'SF Pro')),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: Color(0xFFF7F7F7),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Color(0xFFE0E0E0)),
                                  ),
                                  child: DropdownButton<String>(
                                    value: _filterType,
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'All',
                                        child: Text('All', style: TextStyle(fontFamily: 'SF Pro', fontSize: 18, fontWeight: FontWeight.w500)),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Offer',
                                        child: Text('Offer', style: TextStyle(fontFamily: 'SF Pro', fontSize: 18, fontWeight: FontWeight.w500)),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Request',
                                        child: Text('Request', style: TextStyle(fontFamily: 'SF Pro', fontSize: 18, fontWeight: FontWeight.w500)),
                                      ),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) setState(() => _filterType = val);
                                    },
                                    underline: SizedBox(),
                                    icon: Icon(Icons.arrow_drop_down, color: Color(0xFF007AFF)),
                                    dropdownColor: Color(0xFFF7F7F7),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextField(
                                    style: const TextStyle(fontFamily: 'SF Pro'),
                                    decoration: const InputDecoration(
                                      labelText: 'Region/Location',
                                      labelStyle: TextStyle(fontFamily: 'SF Pro'),
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
                            Expanded(
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
                                      return ListingCard(
                                        listing: listing,
                                        borderColor: (() {
                                          switch (listing.listingType.toLowerCase()) {
                                            case 'offer':
                                              return Colors.green;
                                            case 'request':
                                              return Colors.orange;
                                            default:
                                              return Colors.grey;
                                          }
                                        })(),
                                        onView: () {
                                          setState(() {
                                            _selectedListing = listing;
                                          });
                                        },
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