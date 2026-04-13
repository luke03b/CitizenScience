import 'dart:math';

import 'package:citizen_science/widgets/placeholder_image.dart';
import 'package:citizen_science/widgets/sighting_detail_content.dart';
import 'package:citizen_science/utils/ui_constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'dart:async';
import 'package:flutter_localization/flutter_localization.dart';
import '../l10n/app_locale.dart';
import '../providers/app_state_provider.dart';
import '../models/sighting_model.dart';
import '../utils/location_utils.dart';
import '../utils/error_handler.dart';
import 'create_sighting_screen.dart';
import 'sighting_detail_screen.dart';

/// Screen displaying sightings on an interactive map.
///
/// Shows clustered markers for sightings, supports location-based fetching,
/// and provides map navigation with current location button.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  MapController? _mapController;
  static const _initialPosition = LatLng(45.4642, 9.1900); // Milano
  List<Marker> _markers = [];
  bool _isLoadingLocation = false;
  bool _isMapReady = false;
  bool _isLoadingSightings = false;
  LatLng? _lastFetchedPosition;
  double? _lastFetchedZoom;
  Timer? _fetchDebounceTimer;
  SightingModel? _selectedSighting;

  static const double _minZoomForSightings = 10.0;
  static const double _fetchThresholdKm = 2.0;
  static const Duration _debounceDelay = Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _isMapReady = true;
      });
      _goToCurrentLocation();
    });
  }

  /// Calculates fetch radius in km based on zoom level.
  double _getRadiusFromZoom(double zoom) {
    // Approximate formula: higher zoom = smaller radius
    // Zoom 10: ~50km, Zoom 12: ~25km, Zoom 14: ~10km, Zoom 16: ~5km
    if (zoom < 10) return 100.0;
    if (zoom < 12) return 50.0;
    if (zoom < 14) return 25.0;
    if (zoom < 16) return 10.0;
    return 5.0;
  }

  /// Calculates distance between two points in kilometers.
  double _calculateDistance(LatLng point1, LatLng point2) {
    const earthRadius = 6371.0; // km
    final dLat = _toRadians(point2.latitude - point1.latitude);
    final dLon = _toRadians(point2.longitude - point1.longitude);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(point1.latitude)) *
            cos(_toRadians(point2.latitude)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * pi / 180.0;
  }

  /// Determines if sightings should be refetched based on map movement.
  bool _shouldFetchSightings(LatLng currentPosition, double currentZoom) {
    if (_lastFetchedPosition == null || _lastFetchedZoom == null) {
      return true;
    }

    // Check if zoom level changed significantly
    if ((currentZoom - _lastFetchedZoom!).abs() > 1.0) {
      return true;
    }

    // Check if position moved significantly
    final distance = _calculateDistance(_lastFetchedPosition!, currentPosition);
    if (distance > _fetchThresholdKm) {
      return true;
    }

    return false;
  }

  /// Fetches sightings for the current map view position and zoom.
  ///
  /// If [forceFetch] is true, bypasses movement and zoom checks to force a refresh.
  Future<void> _fetchSightingsForCurrentView({bool forceFetch = false}) async {
    if (_mapController == null || !_isMapReady || _isLoadingSightings) return;

    final center = _mapController!.camera.center;
    final zoom = _mapController!.camera.zoom;

    // Don't fetch if zoomed out too much
    if (zoom < _minZoomForSightings) {
      return;
    }

    // Check if we should fetch (skip check if forceFetch is true)
    if (!forceFetch && !_shouldFetchSightings(center, zoom)) {
      return;
    }

    setState(() {
      _isLoadingSightings = true;
    });

    try {
      final appState = Provider.of<AppStateProvider>(context, listen: false);
      final radius = _getRadiusFromZoom(zoom);

      final sightings = await appState.fetchSightingsByLocation(
        lat: center.latitude,
        lng: center.longitude,
        radiusKm: radius,
      );

      _lastFetchedPosition = center;
      _lastFetchedZoom = zoom;

      _loadMarkers(sightings);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorHandler.getErrorMessage(context, e)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSightings = false;
        });
      }
    }
  }

  /// Debounced version of fetch for map move/zoom events.
  void _debouncedFetchSightings() {
    _fetchDebounceTimer?.cancel();
    _fetchDebounceTimer = Timer(_debounceDelay, () {
      _fetchSightingsForCurrentView();
    });
  }

  /// Loads markers from sightings and updates map.
  void _loadMarkers([List<SightingModel>? sightings]) {
    final List<SightingModel> sightingsToShow;

    if (sightings != null) {
      sightingsToShow = sightings;
    } else {
      final appState = Provider.of<AppStateProvider>(context, listen: false);
      sightingsToShow = appState.allSightings;
    }

    setState(() {
      _markers = sightingsToShow
          .map(
            (sighting) => Marker(
              point: LatLng(sighting.latitude, sighting.longitude),
              width: 40,
              height: 40,
              alignment: Alignment.center,
              child: GestureDetector(
                onTap: () => _showMarkerPreview(sighting.id, sightingsToShow),
                child: Icon(
                  Icons.location_pin,
                  color: Theme.of(context).colorScheme.primary,
                  size: 40,
                ),
              ),
            ),
          )
          .toList();
    });
  }

  /// Shows sighting preview dialog or side panel based on screen size.
  void _showMarkerPreview(String sightingId, List<SightingModel> sightings) {
    try {
      final sighting = sightings.firstWhere(
        (s) => s.id == sightingId,
        orElse: () => throw StateError('Sighting not found'),
      );

      final screenWidth = MediaQuery.of(context).size.width;
      final isDesktop = screenWidth >= kDesktopBreakpoint;

      if (isDesktop) {
        // On desktop, show in side panel
        setState(() {
          _selectedSighting = sighting;
        });
      } else {
        // On mobile, show preview dialog
        setState(() {
          _selectedSighting = null;
        });

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            contentPadding: EdgeInsets.zero,
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 350, maxHeight: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                    child: SizedBox(
                      height: 200,
                      child: sighting.firstImage.isNotEmpty
                          ? Image.network(
                              sighting.firstImage,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const PlaceholderImage();
                              },
                            )
                          : const PlaceholderImage(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sighting.flowerName,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          sighting.location,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          SightingDetailScreen(sighting: sighting),
                    ),
                  );
                },
                child: Text(AppLocale.details.getString(context)),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(AppLocale.close.getString(context)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocale.sightingNotFound.getString(context)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Moves map to current GPS location.
  Future<void> _goToCurrentLocation() async {
    if (_isLoadingLocation || !_isMapReady || _mapController == null) return;

    setState(() {
      _isLoadingLocation = true;
    });

    try {
      final result = await LocationUtils.getCurrentLocation();

      if (result.success && result.position != null) {
        final currentLocation = LatLng(
          result.position!.latitude,
          result.position!.longitude,
        );
        _mapController?.move(currentLocation, 14);

        await _fetchSightingsForCurrentView();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocale.centeredOnCurrentLocation.getString(context),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (!mounted) return;
        _useFallbackLocation(
          result.errorMessage ?? AppLocale.unknownError.getString(context),
        );
      }
    } catch (e) {
      if (!mounted) return;
      _useFallbackLocation('${AppLocale.locationError.getString(context)}: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  /// Uses fallback location (Milano) when GPS fails.
  void _useFallbackLocation(String message) {
    _mapController?.move(_initialPosition, 14);

    _fetchSightingsForCurrentView();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$message. Uso posizione predefinita (Milano)'),
          duration: const Duration(seconds: 3),
        ),
      );
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= kDesktopBreakpoint;
    final hasSelectedSighting = _selectedSighting != null;

    return Scaffold(
      body: isDesktop && hasSelectedSighting
          ? _buildDesktopLayout()
          : _buildMapView(),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Map on the left
        Expanded(child: _buildMapView()),
        // Details panel on the right
        SightingDetailSidePanel(
          sighting: _selectedSighting!,
          onClose: () {
            setState(() {
              _selectedSighting = null;
            });
          },
        ),
      ],
    );
  }

  Widget _buildMapView() {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _initialPosition,
            initialZoom: 12,
            minZoom: 3,
            maxZoom: 19,
            cameraConstraint: CameraConstraint.contain(
              bounds: LatLngBounds(
                const LatLng(-90, -180),
                const LatLng(90, 180),
              ),
            ),
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
            onPositionChanged: (position, hasGesture) {
              if (hasGesture && _isMapReady) {
                _debouncedFetchSightings();
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.citizen_science',
              maxZoom: 19,
              maxNativeZoom: 19,
            ),
            MarkerClusterLayerWidget(
              options: MarkerClusterLayerOptions(
                maxClusterRadius: 120,
                size: const Size(40, 40),
                markers: _markers,
                builder: (context, markers) {
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    child: Center(
                      child: Text(
                        markers.length.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        if (_isLoadingSightings)
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        Positioned(
          top: 16,
          left: 16,
          child: FloatingActionButton(
            heroTag: 'locationButton',
            mini: true,
            onPressed: _isLoadingLocation ? null : _goToCurrentLocation,
            backgroundColor: Theme.of(context).colorScheme.surface,
            foregroundColor: Theme.of(context).colorScheme.primary,
            child: _isLoadingLocation
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location),
          ),
        ),
        // Add sighting button (bottom right)
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            heroTag: 'addButton',
            onPressed: () async {
              final result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (context) => const CreateSightingScreen(),
                ),
              );
              if (mounted && result == true) {
                // Refresh both location-based sightings (for map) and user sightings (for collection)
                // Force fetch to ensure new sighting appears on map immediately
                _fetchSightingsForCurrentView(forceFetch: true);
                try {
                  final appState = Provider.of<AppStateProvider>(
                    context,
                    listen: false,
                  );
                  await appState.fetchUserSightings();
                } catch (e) {
                  // Silently fail if refresh fails, but log for debugging
                  debugPrint(
                    'Failed to refresh user sightings after creation: $e',
                  );
                }
              }
            },
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _fetchDebounceTimer?.cancel();
    _mapController?.dispose();
    _mapController = null;
    super.dispose();
  }
}
