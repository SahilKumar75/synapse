// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import '../services/listing_service.dart'; // <-- CORRECTED IMPORT

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ListingService _listingService = ListingService();
  bool _isLoading = true;
  List<Listing> _listings = [];

  @override
  void initState() {
    super.initState();
    _fetchListings();
  }

  Future<void> _fetchListings() async {
    final listings = await _listingService.getListings();
    if (mounted) { // Check if the widget is still in the tree
      setState(() {
        _listings = listings;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Synapse Dashboard'),
        backgroundColor: Colors.teal,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _listings.isEmpty
              ? const Center(child: Text('No listings found.'))
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
                      ),
                    );
                  },
                ),
    );
  }
}