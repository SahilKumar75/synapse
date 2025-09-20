// lib/screens/listing_details_screen.dart

import 'package:flutter/material.dart';
import 'edit_listing_screen.dart'; // <-- MAKE SURE THIS IMPORT IS HERE
import '../services/listing_service.dart';

class ListingDetailsScreen extends StatelessWidget {
  final Listing listing;
  const ListingDetailsScreen({super.key, required this.listing});

  void _navigateToEdit(BuildContext context) async {
    final result = await Navigator.push(
      context,
      // Ensure you are calling 'EditListingScreen' and NOT using 'const'
      MaterialPageRoute(builder: (context) => EditListingScreen(listing: listing)),
    );
    if (result == true && context.mounted) {
      Navigator.pop(context, true);
    }
  }

  void _deleteListing(BuildContext context) async {
    final bool? confirmed = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text('Are you sure you want to delete this listing?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      final success = await ListingService().deleteListing(listing.id);
      if (context.mounted) {
        if (success) {
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete listing. You may not be the owner.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get current user ID from somewhere (e.g., Provider, AuthService, or pass as argument)
    final currentUserId = ModalRoute.of(context)?.settings.arguments as String?;
    dynamic postedBy = listing.postedBy;
    String? postedById;
    if (postedBy is Map<String, dynamic>) {
      postedById = postedBy['_id'];
    } else if (postedBy is String) {
      postedById = postedBy;
    }
    final isOwner = currentUserId != null && postedById == currentUserId;
    return Scaffold(
      appBar: AppBar(
        title: Text(listing.companyName),
        backgroundColor: Colors.teal,
        actions: [
          if (isOwner)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _navigateToEdit(context),
              tooltip: 'Edit Listing',
            ),
          if (isOwner)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteListing(context),
              tooltip: 'Delete Listing',
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              listing.description,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Text(
              'From: ${listing.companyName}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Location: ${listing.location}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}