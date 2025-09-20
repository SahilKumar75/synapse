import 'package:flutter/cupertino.dart';
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
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('My Listings'),
        backgroundColor: CupertinoColors.systemGrey6,
      ),
      child: widget.userId.isEmpty
          ? const Center(child: Text('Error: User ID is missing. Please log in again.'))
          : _isLoading
              ? const Center(child: CupertinoActivityIndicator())
              : _myListings.isEmpty
                  ? const Center(child: Text('No listings found.'))
                  : ListView.builder(
                      itemCount: _myListings.length,
                      itemBuilder: (context, index) {
                        final listing = _myListings[index];
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemBackground,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: CupertinoColors.systemGrey.withOpacity(0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  listing.companyName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 17,
                                    color: CupertinoColors.label,
                                  ),
                                ),
                                if (listing.description.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    listing.description,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: CupertinoColors.secondaryLabel,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 6),
                                Text(
                                  'Location: ${listing.location}',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: CupertinoColors.systemGrey,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    CupertinoButton(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                      minSize: 32,
                                      color: CupertinoColors.activeBlue,
                                      borderRadius: BorderRadius.circular(8),
                                      child: const Text('View', style: TextStyle(fontSize: 15)),
                                      onPressed: () async {
                                        final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ListingDetailsScreen(listing: listing),
                                            settings: RouteSettings(arguments: widget.userId),
                                          ),
                                        );
                                        if (result == true) {
                                          _fetchMyListings();
                                        }
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    CupertinoButton(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                      minSize: 32,
                                      color: CupertinoColors.systemRed,
                                      borderRadius: BorderRadius.circular(8),
                                      child: const Text('End Listing', style: TextStyle(fontSize: 15)),
                                      onPressed: () async {
                                        final confirm = await showCupertinoDialog<bool>(
                                          context: context,
                                          builder: (context) => CupertinoAlertDialog(
                                            title: const Text('End Listing'),
                                            content: const Text('Are you sure you want to end (delete) this listing?'),
                                            actions: [
                                              CupertinoDialogAction(
                                                onPressed: () => Navigator.of(context).pop(false),
                                                child: const Text('Cancel'),
                                              ),
                                              CupertinoDialogAction(
                                                isDestructiveAction: true,
                                                onPressed: () => Navigator.of(context).pop(true),
                                                child: const Text('End Listing'),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirm == true) {
                                          final success = await _listingService.deleteListing(listing.id);
                                          if (success) {
                                            showCupertinoDialog(
                                              context: context,
                                              builder: (context) => CupertinoAlertDialog(
                                                title: const Text('Success'),
                                                content: const Text('Listing ended successfully.'),
                                                actions: [
                                                  CupertinoDialogAction(
                                                    child: const Text('OK'),
                                                    onPressed: () => Navigator.of(context).pop(),
                                                  ),
                                                ],
                                              ),
                                            );
                                            _fetchMyListings();
                                          } else {
                                            showCupertinoDialog(
                                              context: context,
                                              builder: (context) => CupertinoAlertDialog(
                                                title: const Text('Error'),
                                                content: const Text('Failed to end listing.'),
                                                actions: [
                                                  CupertinoDialogAction(
                                                    child: const Text('OK'),
                                                    onPressed: () => Navigator.of(context).pop(),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
