// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'listing_details_screen.dart';
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
  List<Listing> _listings = [];

  @override
  void initState() {
    super.initState();
    _fetchListings();
  }

  Future<void> _fetchListings() async {
    setState(() { _isLoading = true; });
    final listings = await _listingService.getListings();
    if (mounted) {
      setState(() {
        _listings = listings;
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
      _fetchListings();
    }
  }

  void _navigateToDetailsAndRefresh(Listing listing) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ListingDetailsScreen(listing: listing)),
    );
    if (result == true) {
      _fetchListings();
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
        title: const Text('Synapse Dashboard'),
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
          : RefreshIndicator(
              onRefresh: _fetchListings,
              child: _listings.isEmpty
                  ? const Center(child: Text('No listings found. Pull to refresh.'))
                  : ListView.builder(
                      itemCount: _listings.length,
                      itemBuilder: (context, index) {
                        final listing = _listings[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: ListTile(
                            title: Text(listing.description),
                            subtitle: Text('${listing.companyName} - ${listing.location}'),
                            leading: const Icon(Icons.recycling, color: Colors.teal),
                            onTap: () => _navigateToDetailsAndRefresh(listing),
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateAndRefresh,
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
      ),
    );
  }
}