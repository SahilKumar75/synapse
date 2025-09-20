import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class NotificationIconButton extends StatelessWidget {
  const NotificationIconButton({Key? key}) : super(key: key);

  Future<void> _showNotifications(BuildContext context) async {
    final notificationService = NotificationService();
    final notifications = await notificationService.getNotifications();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notifications'),
        content: SizedBox(
          width: 320,
          child: notifications.isEmpty
              ? const Text('No notifications.')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final n = notifications[index];
                    final sender = n['sender'] ?? {};
                    return ListTile(
                      title: Text(sender['name'] ?? 'Someone'),
                      subtitle: Text(n['message'] ?? ''),
                      trailing: n['read'] == true ? const Icon(Icons.check, color: Colors.green) : null,
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.notifications),
      onPressed: () {
        _showNotifications(context);
      },
      tooltip: 'Notifications',
    );
  }
}
