import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../services/listing_service.dart';

class ListingCard extends StatelessWidget {
  final Listing listing;
  final Color borderColor;
  final VoidCallback onView;

  const ListingCard({
    Key? key,
    required this.listing,
    required this.borderColor,
    required this.onView,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
  margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
      // Remove minHeight constraint so card always fits its content
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(28),
        border: Border(
          left: BorderSide(color: borderColor, width: 9),
        ),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey4.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.max, // Card will expand to fit its content
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    listing.companyName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.label,
                      fontFamily: 'SF Pro',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  color: CupertinoColors.activeBlue,
                  borderRadius: BorderRadius.circular(10),
                  onPressed: onView,
                  child: const Text('View', style: TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'SF Pro')),
                ),
              ],
            ),
            if (listing.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                listing.description,
                style: const TextStyle(
                  fontSize: 14,
                  color: CupertinoColors.secondaryLabel,
                  fontFamily: 'SF Pro',
                ),
                softWrap: true,
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(CupertinoIcons.location_solid, size: 18, color: CupertinoColors.systemGrey),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Location: ${listing.location}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: CupertinoColors.systemGrey,
                      fontFamily: 'SF Pro',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
