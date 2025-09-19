// lib/screens/edit_listing_screen.dart

import 'package:flutter/material.dart';
import '../services/listing_service.dart';

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

  @override
  void initState() {
    super.initState();
    // Pre-fill the text fields with the existing listing data
    _descriptionController = TextEditingController(text: widget.listing.description);
    _locationController = TextEditingController(text: widget.listing.location);
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
        child: Column(
          children: [
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(labelText: 'Location', border: OutlineInputBorder()),
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
    );
  }
}