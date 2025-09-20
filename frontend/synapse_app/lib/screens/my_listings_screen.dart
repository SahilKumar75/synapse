import 'package:flutter/material.dart';
import '../services/listing_service.dart';
import 'listing_details_screen.dart';

class MyListingsScreen extends StatefulWidget {
  final String userId;
  const MyListingsScreen({super.key, required this.userId});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  final ListingService _listingService = ListingService();
  bool _isLoading = true;
  List<Listing> _myListings = [];

  @override
  void initState() {
    super.initState();
    if (widget.userId.isEmpty) {
      debugPrint('[ERROR] MyListingsScreen: userId is empty!');
    } else {
      debugPrint('[DEBUG] MyListingsScreen: userId = \'${widget.userId}\'');
    }
    _fetchMyListings();
  }

  Future<void> _fetchMyListings() async {
    final allListings = await _listingService.getListings();
    setState(() {
      _myListings = allListings.where((listing) {
        dynamic postedBy = listing.postedBy;
        String? postedById;
        if (postedBy is Map<String, dynamic>) {
          postedById = postedBy['_id'];
        } else if (postedBy is String) {
          postedById = postedBy;
        }
        return postedById == widget.userId;
      }).toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Listings'),
        backgroundColor: Colors.teal,
      ),
      body: widget.userId.isEmpty
          ? const Center(child: Text('Error: User ID is missing. Please log in again.'))
          : _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _myListings.isEmpty
                  ? const Center(child: Text('No listings found.'))
                  : ListView.builder(
                      itemCount: _myListings.length,
                      itemBuilder: (context, index) {
                        final listing = _myListings[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
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
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ListingDetailsScreen(listing: listing),
                                    settings: RouteSettings(arguments: widget.userId),
                                  ),
                                );
                                if (result == true) {
                                  // Refresh listings after edit
                                  _fetchMyListings();
                                }
                              },
                              child: const Text('View'),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
