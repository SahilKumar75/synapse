import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';

class MatchesScreen extends StatelessWidget {
  final List<Map<String, dynamic>> matches;

  const MatchesScreen({Key? key, required this.matches}) : super(key: key);

  Future<void> _sendContactNotification(BuildContext context, Map<String, dynamic> match) async {
    final notificationService = NotificationService();
    final authService = AuthService();
    final currentUser = await authService.getCurrentUser();
    final receiverId = match['postedBy']?['_id'] ?? match['userId'] ?? '';
    final senderName = currentUser?['name'] ?? 'A user';
    final message = '$senderName is interested in your listing: ${match['title'] ?? 'Listing'}';
    if (receiverId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not find user to notify.')),
      );
      return;
    }
    final success = await notificationService.sendNotification(receiverId: receiverId, message: message);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? 'Contact request sent to ${match['title'] ?? 'user'}'
            : 'Failed to send contact request.'),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Potential Matches'),
      ),
      body: matches.isEmpty
          ? const Center(child: Text('No matches found.'))
          : ListView.builder(
              itemCount: matches.length,
              itemBuilder: (context, index) {
                final match = matches[index];
                return InkWell(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(match['title'] ?? 'Listing'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Material: ${match['material'] ?? ''}'),
                            Text('Location: ${match['location'] ?? ''}'),
                            Text('Quantity: ${match['quantity'] ?? ''}'),
                            if (match['score'] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Chip(label: Text('Score: ${match['score'].toStringAsFixed(2)}')),
                              ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      title: Text(match['title'] ?? 'Listing'),
                      subtitle: Text('Material: ${match['material'] ?? ''}\nLocation: ${match['location'] ?? ''}\nQuantity: ${match['quantity'] ?? ''}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (match['score'] != null)
                            Chip(label: Text('Score: ${match['score'].toStringAsFixed(2)}')),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              _sendContactNotification(context, match);
                            },
                            child: const Text('Contact'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
