import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:aji_tfarraj/app/routes.dart';

/// Home Screen - List of available TV shows
/// TODO: Fetch shows from API
/// TODO: Implement show list with cards
/// TODO: Add pull-to-refresh functionality
/// TODO: Add search and filter options
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Émissions'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5, // TODO: Replace with actual show count
        itemBuilder: (context, index) {
          final showId = '${index + 1}';
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              // TODO: Add show image thumbnail
              leading: Container(
                width: 60,
                height: 60,
                color: Colors.grey[300],
                child: const Icon(Icons.tv),
              ),
              title: Text('Show $showId'), // TODO: Replace with show title
              subtitle: const Text('Date et heure'), // TODO: Replace with show date
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // Navigate to show detail with showId
                context.go(Routes.showDetail(showId));
              },
            ),
          );
        },
      ),
    );
  }
}
