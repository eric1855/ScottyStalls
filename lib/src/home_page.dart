import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';

import 'models/restroom.dart';
import 'reader_review_page.dart';
import 'profile_page.dart';
import 'package:provider/provider.dart';
import 'providers/restroom_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/location_provider.dart';
import 'building_map_page.dart';

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

  // Remove the hardcoded _myLocation since we'll get it from the provider

  @override
  void initState() {
    super.initState();
    // Initialize offline tile cache and location provider
    FlutterMapTileCaching.initialise().then((_) {
      FMTC.instance('carto').manage.create();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<LocationProvider>().initialize();
        context.read<RestroomProvider>().loadRestrooms();
      }
    });
  }

  void _centerOnUser() {
    final locationProvider = context.read<LocationProvider>();
    if (locationProvider.hasPermission &&
        locationProvider.currentLocation != null) {
      _mapController.move(locationProvider.currentLocation!, 16);
    }
  }

  Future<void> _downloadMap() async {
    // Download a region around campus for offline use
    final bounds = LatLngBounds(
      LatLng(40.4370, -79.9680),
      LatLng(40.4490, -79.9560),
    );
    await FMTC
        .instance('carto')
        .download
        .downloadRegion(bounds, minZoom: 14, maxZoom: 18);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Map downloaded for offline use')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final restroomProvider = context.watch<RestroomProvider>();
    final locationProvider = context.watch<LocationProvider>();

    // Get current user location from provider
    final userLocation = locationProvider.currentLocation ??
        LatLng(40.4440, -79.9600); // Fallback location

    final restrooms = restroomProvider.restrooms;
    // Group restrooms by building to create highlight overlays. Each building's
    // centroid is computed from its restrooms' coordinates and rendered as a
    // subtle translucent circle on the map. We also attach transparent markers
    // at the same centroids to allow tapping a building to view its floors.
    final Map<String, List<Restroom>> _byBuilding = {};
    for (final r in restrooms) {
      _byBuilding.putIfAbsent(r.building, () => []).add(r);
    }
    final Map<String, LatLng> _buildingCenters = {};
    final buildingHighlights = _byBuilding.entries.map((entry) {
      final list = entry.value;
      final lat =
          list.map((r) => r.latitude).reduce((a, b) => a + b) / list.length;
      final lon =
          list.map((r) => r.longitude).reduce((a, b) => a + b) / list.length;
      final center = LatLng(lat, lon);
      _buildingCenters[entry.key] = center;
      return CircleMarker(
        point: center,
        radius: 50,
        color: theme.colorScheme.primary.withOpacity(0.2),
        borderStrokeWidth: 0,
      );
    }).toList();
    final buildingTapMarkers = _buildingCenters.entries.map((e) {
      return Marker(
        width: 80,
        height: 80,
        point: e.value,
        builder: (ctx) => GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BuildingMapPage(
                  building: e.key,
                  restrooms: _byBuilding[e.key]!,
                ),
              ),
            );
          },
          child: Container(color: Colors.transparent),
        ),
      );
    }).toList();
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
                center: userLocation,
                zoom: 16.0,
                maxZoom: 18.0,
                minZoom: 14.0,
              ),
              children: [
                // Use a cleaner basemap similar to the default Google Maps
                // appearance. CartoDB's "light_all" style provides a subtle
                // grayscale map that keeps the focus on our markers without
                // requiring any API keys.
                TileLayer(
                  urlTemplate:
                      'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                  subdomains: const ['a', 'b', 'c', 'd'],
                  userAgentPackageName: 'com.example.toilet_app',
                  tileProvider: FMTC.instance('carto').getTileProvider(),
                ),
                // Highlight the buildings that contain restrooms.
                if (buildingHighlights.isNotEmpty)
                  CircleLayer(circles: buildingHighlights),
                if (buildingTapMarkers.isNotEmpty)
                  MarkerLayer(markers: buildingTapMarkers),
                // User location marker (blue dot)
                if (locationProvider.hasPermission &&
                    locationProvider.currentLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        width: 24,
                        height: 24,
                        point: locationProvider.currentLocation!,
                        builder: (ctx) => _buildUserLocationMarker(),
                      ),
                    ],
                  ),
                // Restroom markers
                MarkerLayer(
                  markers: visibleRestrooms
                      .map(
                        (r) => Marker(
                          width: 36,
                          height: 36,
                          point: LatLng(r.latitude, r.longitude),
                          builder: (ctx) =>
                              _buildRatingMarker(context, r.generalRating),
                        ),
                      )
                      .toList(),
                ),
              ],
            )),

            // Loading overlay: show when restrooms are being fetched
            if (restroomProvider.isLoading)
              const Center(
                child: CircularProgressIndicator(),
              ),

            // Offline map download button
            Positioned(
              top: 16,
              right: 16,
              child: FloatingActionButton(
                heroTag: 'download',
                mini: true,
                onPressed: _downloadMap,
                child: const Icon(Icons.download),
              ),
            ),

            // Location permission banner
            if (!locationProvider.hasPermission && !locationProvider.isLoading)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.location_off, color: Colors.orange.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Location access needed for live tracking',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => locationProvider.requestPermission(),
                        child: Text(
                          'Enable',
                          style: TextStyle(color: Colors.orange.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Top area with search bar and location toggle
            Positioned(
              top: locationProvider.hasPermission
                  ? 12
                  : 80, // Adjust position if banner is shown
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
                                auth.user.isGuest
                                    ? Icons.person_outline
                                    : Icons.person,
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
              child: _buildBottomSheet(context, visibleRestrooms, userLocation),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the user's location marker (blue dot).
  Widget _buildUserLocationMarker() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(
        Icons.my_location,
        color: Colors.white,
        size: 16,
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
  Widget _buildBottomSheet(BuildContext context,
      List<Restroom> visibleRestrooms, LatLng userLocation) {
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
                  userLocation, // Use actual user location instead of hardcoded
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
