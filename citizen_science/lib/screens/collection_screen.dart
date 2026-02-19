import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;
import 'package:flutter_localization/flutter_localization.dart';
import '../providers/app_state_provider.dart';
import '../widgets/sighting_card.dart';
import '../models/sighting_model.dart';
import '../widgets/sighting_detail_content.dart';
import 'sighting_detail_screen.dart';
import '../l10n/app_locale.dart';

const double _kMobileBreakpoint = 600.0;
const double _kTabletBreakpoint = 900.0;
const double _kDesktopBreakpoint = 1200.0;

/// Display mode for the sightings collection.
enum ViewMode { card, list }

/// Available sorting options for sightings.
enum SortOption {
  mostRecent,
  leastRecent,
  closest,
  farthest,
  alphabeticalAsc,
  alphabeticalDesc,
}

/// Screen displaying the user's collection of flower sightings.
/// 
/// Provides multiple view modes (card/list), sorting options, and responsive
/// layout. On desktop, shows details in a side panel; on mobile, navigates
/// to a separate detail screen.
class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  ViewMode _viewMode = ViewMode.card;
  SortOption _sortOption = SortOption.mostRecent;
  Position? _userPosition;
  bool _isLoading = false;
  String? _errorMessage;
  SightingModel? _selectedSighting;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    _loadUserSightings();
  }

  /// Fetches all sightings created by the current user.
  Future<void> _loadUserSightings() async {
    final errorMessage = AppLocale.unableToLoadSightings.getString(context);
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final appState = Provider.of<AppStateProvider>(context, listen: false);
      await appState.fetchUserSightings();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = errorMessage;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Requests and retrieves the user's current location.
  /// 
  /// Used for distance-based sorting. Fails silently if location
  /// permission is not granted or location services are unavailable.
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
    }
  }

  /// Calculates the distance between two geographic coordinates using the Haversine formula.
  /// 
  /// Returns distance in kilometers.
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

  /// Calculates the distance from the user's current location to a sighting.
  /// 
  /// Returns 0 if user location is not available.
  double _getDistanceFromUser(SightingModel sighting) {
    if (_userPosition == null) return 0;
    return _calculateDistance(
      _userPosition!.latitude,
      _userPosition!.longitude,
      sighting.latitude,
      sighting.longitude,
    );
  }

  /// Sorts the list of sightings based on the current [_sortOption].
  /// 
  /// Returns a new sorted list without modifying the original.
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

  /// Returns the localized label for a [SortOption].
  String _getSortOptionLabel(BuildContext context, SortOption option) {
    switch (option) {
      case SortOption.mostRecent:
        return AppLocale.mostRecent.getString(context);
      case SortOption.leastRecent:
        return AppLocale.leastRecent.getString(context);
      case SortOption.closest:
        return AppLocale.closest.getString(context);
      case SortOption.farthest:
        return AppLocale.farthest.getString(context);
      case SortOption.alphabeticalAsc:
        return AppLocale.alphabeticalAsc.getString(context);
      case SortOption.alphabeticalDesc:
        return AppLocale.alphabeticalDesc.getString(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= _kDesktopBreakpoint;
    final hasSelectedSighting = _selectedSighting != null;

    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        final sightings = _sortSightings(appState.userSightings);

        return isDesktop && hasSelectedSighting
            ? _buildDesktopLayout(sightings, appState)
            : _buildCollectionView(sightings, appState);
      },
    );
  }

  /// Builds the desktop layout with collection view on left and detail panel on right.
  Widget _buildDesktopLayout(List<SightingModel> sightings, AppStateProvider appState) {
    return Row(
      children: [
        // Collection view on the left
        Expanded(
          child: _buildCollectionView(sightings, appState),
        ),
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

  /// Builds the main collection view with controls and content.
  Widget _buildCollectionView(List<SightingModel> sightings, AppStateProvider appState) {
    final hasPending = appState.pendingSightings.isNotEmpty;
    
    return Column(
      children: [
        // Pending sightings banner
        if (hasPending)
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.orange.withValues(alpha: 0.2),
            child: Row(
              children: [
                const Icon(Icons.cloud_upload, color: Colors.orange),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${appState.pendingSightings.length} ${AppLocale.pendingSightingsCount.getString(context)}',
                    style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                  ),
                ),
                if (appState.isOnline)
                  TextButton(
                    onPressed: () async {
                      await appState.syncPendingSightings();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(AppLocale.syncCompleted.getString(context))),
                        );
                      }
                    },
                    child: Text(AppLocale.synchronize.getString(context)),
                  ),
              ],
            ),
          ),
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
                label: AppLocale.sortBy.getString(context),
                child: DropdownButton<SortOption>(
                  value: _sortOption,
                  icon: const Icon(Icons.sort),
                  underline: Container(),
                  items: SortOption.values.map((option) {
                    return DropdownMenuItem(
                      value: option,
                      child: Text(_getSortOptionLabel(context, option)),
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
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : _errorMessage != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _loadUserSightings,
                            icon: const Icon(Icons.refresh),
                            label: Text(AppLocale.retry.getString(context)),
                          ),
                        ],
                      ),
                    )
                  : sightings.isEmpty
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
                                AppLocale.noSightings.getString(context),
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                AppLocale.yourSightingsWillAppearHere.getString(context),
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
  }

  /// Builds a responsive grid view of sighting cards.
  /// 
  /// Adapts the number of columns based on screen width.
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
        
        return RefreshIndicator(
          onRefresh: _loadUserSightings,
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
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
                  final screenWidth = MediaQuery.of(context).size.width;
                  final isDesktop = screenWidth >= _kDesktopBreakpoint;

                  if (isDesktop) {
                    // On desktop, show in side panel
                    setState(() {
                      _selectedSighting = sighting;
                    });
                  } else {
                    // On mobile, navigate to detail screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SightingDetailScreen(sighting: sighting),
                      ),
                    );
                  }
                },
              );
            },
          ),
        );
      },
    );
  }

  /// Builds a list view of sightings.
  Widget _buildListView(List<SightingModel> sightings) {
    return RefreshIndicator(
      onRefresh: _loadUserSightings,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: sightings.length,
        itemBuilder: (context, index) {
          final sighting = sightings[index];
          return _SightingListItem(
            sighting: sighting,
            onTap: () {
              final screenWidth = MediaQuery.of(context).size.width;
              final isDesktop = screenWidth >= _kDesktopBreakpoint;

              if (isDesktop) {
                // On desktop, show in side panel
                setState(() {
                  _selectedSighting = sighting;
                });
              } else {
                // On mobile, navigate to detail screen
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => SightingDetailScreen(
                      sighting: sighting,
                    ),
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }
}

/// A compact list item widget displaying a single sighting.
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
