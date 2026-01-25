import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;
import '../providers/app_state_provider.dart';
import '../widgets/sighting_card.dart';
import '../models/sighting_model.dart';
import 'sighting_detail_screen.dart';

// Responsive breakpoints
const double _kMobileBreakpoint = 600.0;
const double _kTabletBreakpoint = 900.0;
const double _kDesktopBreakpoint = 1200.0;

enum ViewMode { card, list }

enum SortOption {
  mostRecent,
  leastRecent,
  closest,
  farthest,
  alphabeticalAsc,
  alphabeticalDesc,
}

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  ViewMode _viewMode = ViewMode.card;
  SortOption _sortOption = SortOption.mostRecent;
  Position? _userPosition;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.deniedForever) {
        // Cannot request permission, user must enable in settings
        return;
      }
      if (permission == LocationPermission.denied) {
        final newPermission = await Geolocator.requestPermission();
        if (newPermission == LocationPermission.denied || newPermission == LocationPermission.deniedForever) {
          return;
        }
      }
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _userPosition = position;
      });
    } catch (e) {
      // Silently fail if location is not available
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371; // km
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  double _getDistanceFromUser(SightingModel sighting) {
    if (_userPosition == null) return 0;
    return _calculateDistance(
      _userPosition!.latitude,
      _userPosition!.longitude,
      sighting.latitude,
      sighting.longitude,
    );
  }

  List<SightingModel> _sortSightings(List<SightingModel> sightings) {
    final sorted = List<SightingModel>.from(sightings);
    
    switch (_sortOption) {
      case SortOption.mostRecent:
        sorted.sort((a, b) => b.date.compareTo(a.date));
        break;
      case SortOption.leastRecent:
        sorted.sort((a, b) => a.date.compareTo(b.date));
        break;
      case SortOption.closest:
        if (_userPosition != null) {
          sorted.sort((a, b) => _getDistanceFromUser(a).compareTo(_getDistanceFromUser(b)));
        }
        break;
      case SortOption.farthest:
        if (_userPosition != null) {
          sorted.sort((a, b) => _getDistanceFromUser(b).compareTo(_getDistanceFromUser(a)));
        }
        break;
      case SortOption.alphabeticalAsc:
        sorted.sort((a, b) => a.flowerName.compareTo(b.flowerName));
        break;
      case SortOption.alphabeticalDesc:
        sorted.sort((a, b) => b.flowerName.compareTo(a.flowerName));
        break;
    }
    
    return sorted;
  }

  String _getSortOptionLabel(SortOption option) {
    switch (option) {
      case SortOption.mostRecent:
        return 'Più recente';
      case SortOption.leastRecent:
        return 'Meno recente';
      case SortOption.closest:
        return 'Più vicino';
      case SortOption.farthest:
        return 'Più lontano';
      case SortOption.alphabeticalAsc:
        return 'A-Z';
      case SortOption.alphabeticalDesc:
        return 'Z-A';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        final sightings = _sortSightings(appState.userSightings);

        return Column(
          children: [
            // Top bar with controls
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // View mode toggle
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.grid_view),
                          onPressed: () {
                            setState(() {
                              _viewMode = ViewMode.card;
                            });
                          },
                          color: _viewMode == ViewMode.card
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        IconButton(
                          icon: const Icon(Icons.list),
                          onPressed: () {
                            setState(() {
                              _viewMode = ViewMode.list;
                            });
                          },
                          color: _viewMode == ViewMode.list
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ],
                    ),
                  ),
                  // Sort dropdown
                  Semantics(
                    label: 'Ordina per',
                    child: DropdownButton<SortOption>(
                      value: _sortOption,
                      icon: const Icon(Icons.sort),
                      underline: Container(),
                      items: SortOption.values.map((option) {
                        return DropdownMenuItem(
                          value: option,
                          child: Text(_getSortOptionLabel(option)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _sortOption = value;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: sightings.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.collections,
                            size: 100,
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Nessun avvistamento',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'I tuoi avvistamenti appariranno qui',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                                ),
                          ),
                        ],
                      ),
                    )
                  : _viewMode == ViewMode.card
                      ? _buildCardView(sightings)
                      : _buildListView(sightings),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCardView(List<SightingModel> sightings) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width < _kMobileBreakpoint 
            ? 1 
            : (width < _kTabletBreakpoint ? 2 : (width < _kDesktopBreakpoint ? 3 : 4));
        
        // Calculate card aspect ratio: image (16:9) + fixed details height (120px)
        final cardWidth = (width - (16.0 * 2) - (16.0 * (crossAxisCount - 1))) / crossAxisCount;
        final imageHeight = cardWidth / (16 / 9);
        final cardHeight = imageHeight + 120;
        final childAspectRatio = cardWidth / cardHeight;
        
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: sightings.length,
          itemBuilder: (context, index) {
            final sighting = sightings[index];
            return SightingCard(
              sighting: sighting,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SightingDetailScreen(sighting: sighting),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildListView(List<SightingModel> sightings) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sightings.length,
      itemBuilder: (context, index) {
        final sighting = sightings[index];
        return _SightingListItem(
          sighting: sighting,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => SightingDetailScreen(
                  sighting: sighting,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _SightingListItem extends StatelessWidget {
  final SightingModel sighting;
  final VoidCallback onTap;

  const _SightingListItem({
    required this.sighting,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                Icons.local_florist,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  sighting.flowerName,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
