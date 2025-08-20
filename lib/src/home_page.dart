import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';

import 'models/restroom.dart';
import 'review_page.dart';
import 'reader_review_page.dart';
import 'profile_page.dart';
import 'package:provider/provider.dart';
import 'providers/restroom_provider.dart';
import 'providers/auth_provider.dart';

/// The home screen of the restroom reviewer app.
///
/// Displays a map with markers representing available restrooms. At the top
/// the user can search for restrooms or buildings, and toggle whether to
/// center the map on their current location. At the bottom a draggable
/// sheet lists the available restrooms with quick details. Tapping a list
/// entry navigates to the review page for that restroom.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  static const String routeName = '/home';

  

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  bool _useMyLocation = true;

  // The list of restrooms is now loaded from the backend via the
  // [RestroomProvider]. We no longer maintain a hard‑coded list here.

  // Fallback user location. In a real app you would use a location plugin to
  // get the current position. These coordinates roughly represent the centre
  // of campus.
  final LatLng _myLocation = LatLng(40.4440, -79.9600);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Trigger loading of restrooms once the widget has been inserted into the
    // widget tree. We use addPostFrameCallback to ensure that a context
    // exists when calling the provider.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<RestroomProvider>().loadRestrooms();
      }
    });
  }

  void _centerOnUser() {
    // In a real app, update _myLocation using a location service. Here we just
    // centre the map controller on the hard‑coded location.
    _mapController.move(_myLocation, 16);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Load restrooms from the provider. When the provider has not yet
    // fetched data this list will be empty; a loading indicator is shown.
    final restroomProvider = context.watch<RestroomProvider>();
    final restrooms = restroomProvider.restrooms;
    final query = _searchController.text.toLowerCase();
    final List<Restroom> visibleRestrooms = query.isEmpty
        ? restrooms
        : restrooms.where((r) {
            return r.name.toLowerCase().contains(query) ||
                r.building.toLowerCase().contains(query);
          }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Map view
            SizedBox.expand(
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  center: _myLocation,
                  zoom: 16.0,
                  maxZoom: 18.0,
                  minZoom: 14.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.toilet_app',
                  ),
                  MarkerLayer(
                    markers: visibleRestrooms
                        .map(
                          (r) => Marker(
                            width: 36,
                            height: 36,
                            point: LatLng(r.latitude, r.longitude),
                            builder: (ctx) => _buildRatingMarker(
                                context, r.generalRating),
                          ),
                        )
                        .toList(),
                  ),
                ],
              )
            ),

            // Loading overlay: show when restrooms are being fetched
            if (restroomProvider.isLoading)
              const Center(
                child: CircularProgressIndicator(),
              ),
            // Top area with search bar and location toggle
            Positioned(
              top: 12,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (val) => setState(() {}),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.search),
                              hintText: 'Search buildings, restrooms',
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Account/profile button
                      Consumer<AuthProvider>(
                        builder: (context, auth, _) {
                          return InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => const ProfilePage()),
                              );
                            },
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.white,
                              child: Icon(
                                auth.user.isGuest ? Icons.person_outline : Icons.person,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _useMyLocation = !_useMyLocation;
                      });
                      if (_useMyLocation) {
                        _centerOnUser();
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _useMyLocation
                                ? Icons.location_on
                                : Icons.location_off,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Use my location',
                            style: GoogleFonts.inter(
                              textStyle: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF111827),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Bottom sheet with list of restrooms
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomSheet(context, visibleRestrooms),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a small circular marker widget displaying the restroom rating.
  Widget _buildRatingMarker(BuildContext context, double rating) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        rating.toStringAsFixed(1),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  /// Builds the bottom sheet listing all visible restrooms.
  Widget _buildBottomSheet(
      BuildContext context, List<Restroom> visibleRestrooms) {
    final theme = Theme.of(context);
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(
            height: 220,
            child: ListView.builder(
              itemCount: visibleRestrooms.length,
              itemBuilder: (context, index) {
                final restroom = visibleRestrooms[index];
                final distance = Distance().as(
                  LengthUnit.Mile,
                  _myLocation,
                  LatLng(restroom.latitude, restroom.longitude),
                );
                return InkWell(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      ReaderReviewPage.routeName,
                      arguments: restroom,
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        // Rating badge
                        Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Text(
                            restroom.generalRating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                restroom.name,
                                style: GoogleFonts.inter(
                                  textStyle: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                restroom.building,
                                style: GoogleFonts.inter(
                                  textStyle: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${distance.toStringAsFixed(1)} mi',
                          style: GoogleFonts.inter(
                            textStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}