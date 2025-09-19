// lib/screens/new_listing_screen.dart

import 'package:flutter/material.dart';
import '../services/listing_service.dart'; // <-- CORRECTED IMPORT

class NewListingScreen extends StatefulWidget {
  const NewListingScreen({super.key});

  @override
  State<NewListingScreen> createState() => _NewListingScreenState();
}

class _NewListingScreenState extends State<NewListingScreen> {
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final ListingService _listingService = ListingService();
  bool _isLoading = false;

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
                labelText: 'Location (e.g., "Bhosari MIDC, Pune")',
                border: OutlineInputBorder(),
              ),
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
    );
  }
}