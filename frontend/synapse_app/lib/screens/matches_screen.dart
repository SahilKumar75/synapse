import 'package:flutter/material.dart';

class MatchesScreen extends StatelessWidget {
  final List<Map<String, dynamic>> matches;

  const MatchesScreen({Key? key, required this.matches}) : super(key: key);

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
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(match['title'] ?? 'Listing'),
                    subtitle: Text('Material: ${match['material'] ?? ''}\nLocation: ${match['location'] ?? ''}\nQuantity: ${match['quantity'] ?? ''}'),
                    trailing: match['score'] != null
                        ? Chip(label: Text('Score: ${match['score'].toStringAsFixed(2)}'))
                        : null,
                  ),
                );
              },
            ),
    );
  }
}
