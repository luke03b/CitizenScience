import 'package:citizen_science/widgets/placeholder_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import '../providers/app_state_provider.dart';
import 'create_sighting_screen.dart';
import 'sighting_detail_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  MapController? _mapController;
  static const _initialPosition = LatLng(45.4642, 9.1900); // Milano
  final List<Marker> _markers = [];
  bool _isLoadingLocation = false;
  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _loadMarkers();
    // Aspetta che la mappa sia pronta prima di muovere la camera
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _isMapReady = true;
      });
      _goToCurrentLocation();
    });
  }

  void _loadMarkers() {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final sightings = appState.allSightings;

    setState(() {
      _markers.clear();
      for (var sighting in sightings) {
        _markers.add(
          Marker(
            point: LatLng(sighting.latitude, sighting.longitude),
            width: 40,
            height: 40,
            child: GestureDetector(
              onTap: () => _showMarkerPreview(sighting.id),
              child: const Icon(
                Icons.location_pin,
                color: Colors.green,
                size: 40,
              ),
            ),
          ),
        );
      }
    });
  }

  void _showMarkerPreview(String sightingId) {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final sighting = appState.allSightings.firstWhere((s) => s.id == sightingId);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        content: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 350,
            maxHeight: 400,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
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
                  builder: (context) => SightingDetailScreen(sighting: sighting),
                ),
              );
            },
            child: const Text('Dettagli'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Chiudi'),
          ),
        ],
      ),
    );
  }

  Future<void> _goToCurrentLocation() async {
    if (_isLoadingLocation || !_isMapReady || _mapController == null) return;

    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Controlla se i servizi di localizzazione sono abilitati
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _useFallbackLocation('Servizi di localizzazione disabilitati');
        return;
      }

      // Controlla i permessi
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _useFallbackLocation('Permesso di localizzazione negato');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _useFallbackLocation('Permesso di localizzazione negato permanentemente');
        return;
      }

      // Ottieni la posizione corrente
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final currentLocation = LatLng(position.latitude, position.longitude);
      _mapController?.move(currentLocation, 14);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Centrato sulla posizione attuale'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      _useFallbackLocation('Errore nel recupero della posizione: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  void _useFallbackLocation(String message) {
    _mapController?.move(_initialPosition, 14);

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
    return Scaffold(
      body: Stack(
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
                        color: Colors.green,
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
          // Current location button (top left)
          Positioned(
            top: 16,
            left: 16,
            child: FloatingActionButton(
              heroTag: 'locationButton',
              mini: true,
              onPressed: _isLoadingLocation ? null : _goToCurrentLocation,
              backgroundColor: Colors.white,
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
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const CreateSightingScreen(),
                  ),
                );
              },
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _mapController = null;
    super.dispose();
  }
}