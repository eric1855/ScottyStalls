import 'package:flutter/material.dart';
// import 'package:provider/provider.dart'; // Not used here—safe to remove or keep.

import '../settings/settings_view.dart';
import 'sample_item.dart';
import 'sample_item_details_view.dart';

class MyAppState extends ChangeNotifier {
  var current = "test";
}

/// Displays a list of SampleItems.
class SampleItemListView extends StatelessWidget {
  const SampleItemListView({
    super.key,
    this.items = const [SampleItem(1), SampleItem(2), SampleItem(3)],
  });

  static const routeName = '/';

  final List<SampleItem> items;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA), // light, minimal backdrop
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827), // near-black text/icons
        iconTheme: const IconThemeData(color: Color(0xFF111827)),
        title: const Text(
          'Restroom Reviewer',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800, // bold + minimal
            letterSpacing: 0.5,
            color: Color(0xFF111827),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.restorablePushNamed(context, SettingsView.routeName);
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: const Color(0xFFE5E7EB), // subtle divider (gray-200)
            height: 1,
          ),
        ),
      ),
      body: ListView.builder(
        restorationId: 'sampleItemListView',
        itemCount: items.length,
        itemBuilder: (BuildContext context, int index) {
          final item = items[index];

          return Container(
            color: Colors.white, // minimal list row
            child: ListTile(
              title: Text(
                'SampleItem ${item.id}',
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontWeight: FontWeight.w600,
                ),
              ),
              leading: const CircleAvatar(
                foregroundImage: AssetImage('assets/images/flutter_logo.png'),
                backgroundColor: Colors.white,
              ),
              trailing: const Icon(Icons.chevron_right, color: Color(0xFF6B7280)),
              onTap: () {
                Navigator.restorablePushNamed(
                  context,
                  SampleItemDetailsView.routeName,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
