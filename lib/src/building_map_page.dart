import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models/restroom.dart';
import 'reader_review_page.dart';

/// Displays the restrooms inside a particular building and lets the user
/// switch between floors. A simple floor plan image is shown with tappable
/// restroom icons positioned according to each restroom's `mapX`/`mapY`
/// coordinates (expressed as a 0‑1 fraction of the image dimensions).
/// Tapping a restroom icon opens its review page.
class BuildingMapPage extends StatefulWidget {
  const BuildingMapPage(
      {super.key, required this.building, required this.restrooms});

  final String building;
  final List<Restroom> restrooms;

  @override
  State<BuildingMapPage> createState() => _BuildingMapPageState();
}

class _BuildingMapPageState extends State<BuildingMapPage> {
  late List<int> _floors;
  late int _selectedFloor;

  @override
  void initState() {
    super.initState();
    _floors = widget.restrooms.map((r) => r.floor).toSet().toList()..sort();
    _selectedFloor = _floors.first;
  }

  @override
  Widget build(BuildContext context) {
    final floorRestrooms =
        widget.restrooms.where((r) => r.floor == _selectedFloor).toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.building),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButton<int>(
              value: _selectedFloor,
              items: _floors
                  .map((f) =>
                      DropdownMenuItem(value: f, child: Text('Floor $f')))
                  .toList(),
              onChanged: (f) {
                if (f != null) {
                  setState(() => _selectedFloor = f);
                }
              },
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final height = constraints.maxHeight;
                return Stack(
                  children: [
                    // Display a generic floor plan image. In a production
                    // app this would vary per building/floor.
                    Positioned.fill(
                      child: Container(
                        color: Colors.grey.shade200,
                        child: Center(
                          child: Text(
                            'No floor map available',
                            style: GoogleFonts.inter(),
                          ),
                        ),
                      ),
                    ),
                    // Restroom markers on the floor plan
                    ...floorRestrooms.map((r) {
                      final dx = r.mapX * width;
                      final dy = r.mapY * height;
                      return Positioned(
                        left: dx - 12,
                        top: dy - 12,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ReaderReviewPage(restroom: r),
                              ),
                            );
                          },
                          child: Icon(
                            Icons.wc,
                            color: Theme.of(context).colorScheme.primary,
                            size: 24,
                          ),
                        ),
                      );
                    })
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
