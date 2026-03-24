import 'package:citizen_science/widgets/placeholder_image.dart';
import 'package:citizen_science/utils/ui_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:provider/provider.dart';
import '../l10n/app_locale.dart';
import '../models/sighting_model.dart';
import '../providers/app_state_provider.dart';
import '../utils/error_handler.dart';

/// A widget that displays sighting details in a desktop side panel.
///
/// Includes a close button, delete button (for owners), and the sighting content.
/// Designed for desktop layouts with a fixed width side panel.
class SightingDetailSidePanel extends StatelessWidget {
  /// The sighting data to display in the side panel.
  final SightingModel sighting;
  
  /// Callback function executed when the close button is pressed.
  final VoidCallback onClose;

  /// Creates a [SightingDetailSidePanel] widget.
  const SightingDetailSidePanel({
    super.key,
    required this.sighting,
    required this.onClose,
  });

  /// Shows a confirmation dialog before deleting the sighting.
  Future<void> _showDeleteConfirmation(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(AppLocale.confirmDelete.getString(dialogContext)),
          content: Text(AppLocale.confirmDeleteMessage.getString(dialogContext)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(AppLocale.cancel.getString(dialogContext)),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                // Check if the outer context is still mounted before proceeding
                if (context.mounted) {
                  await _deleteSighting(context);
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(dialogContext).colorScheme.error,
              ),
              child: Text(AppLocale.deleteAction.getString(dialogContext)),
            ),
          ],
        );
      },
    );
  }

  /// Deletes the sighting after confirmation.
  ///
  /// Shows a loading dialog during deletion and displays success or error messages.
  Future<void> _deleteSighting(BuildContext context) async {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;
    
    // Show loading dialog
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Center(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(AppLocale.loading.getString(context)),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }
    
    try {
      await appState.deleteSighting(sighting.id);
      
      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      
      // Show success message and close side panel
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(AppLocale.sightingDeleted.getString(context)),
          duration: const Duration(seconds: 2),
        ),
      );
      
      if (context.mounted) {
        onClose();
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      
      // Show error message
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(ErrorHandler.getErrorMessage(context, e)),
          duration: const Duration(seconds: 3),
          backgroundColor: errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final isOwner = appState.currentUser?.id == sighting.userId;
    return Container(
      width: kSidePanelWidth,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(-2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Close button
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                Semantics(
                  label: AppLocale.close.getString(context),
                  button: true,
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onClose,
                    tooltip: AppLocale.close.getString(context),
                  ),
                ),
                Expanded(
                  child: Text(
                    AppLocale.sightingDetails.getString(context),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isOwner)
                  Semantics(
                    label: AppLocale.deleteSighting.getString(context),
                    button: true,
                    child: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _showDeleteConfirmation(context),
                      tooltip: AppLocale.deleteSighting.getString(context),
                    ),
                  ),
              ],
            ),
          ),
          // Details content
          Expanded(
            child: SightingDetailContent(
              sighting: sighting,
              showAppBar: false,
            ),
          ),
        ],
      ),
    );
  }
}

/// A widget that displays sighting details content.
///
/// Shows the sighting's images in a carousel, location, date, user information,
/// and editable notes (for owners). Can be used in both full screen and side panel layouts.
class SightingDetailContent extends StatefulWidget {
  /// The sighting data to display.
  final SightingModel sighting;
  
  /// Whether to show an app bar (used in full screen mode).
  final bool showAppBar;

  /// Creates a [SightingDetailContent] widget.
  const SightingDetailContent({
    super.key,
    required this.sighting,
    this.showAppBar = true,
  });

  @override
  State<SightingDetailContent> createState() => _SightingDetailContentState();
}

class _SightingDetailContentState extends State<SightingDetailContent> {
  late TextEditingController _notesController;
  bool _isEditing = false;
  int _currentImageIndex = 0;
  late PageController _pageController;

  static const double _arrowBackgroundAlpha = 0.5;
  static const double _arrowDisabledBackgroundAlpha = 0.2;
  static const double _arrowDisabledForegroundAlpha = 0.3;
  static const Duration _pageTransitionDuration = Duration(milliseconds: 300);
  static const Curve _pageTransitionCurve = Curves.easeInOut;
  static const double _maxImageWidth = 800;
  static const double _imageAspectRatio = 16.0 / 9.0;
  static const double _arrowPadding = 8.0;
  static const double _arrowIconSize = 30.0;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.sighting.notes);
    _pageController = PageController();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  /// Returns whether the current user is the owner of the sighting.
  bool get _isOwner {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    return appState.currentUser?.id == widget.sighting.userId;
  }

  /// Returns whether the current user has the researcher role.
  bool get _isResearcher {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    return appState.currentUser?.isResearcher == true;
  }

  /// Toggles the editing state for the notes field.
  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        _notesController.text = widget.sighting.notes;
      }
    });
  }

  /// Saves the updated notes to the sighting.
  void _saveNotes() {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    appState.updateSightingNotes(widget.sighting.id, _notesController.text);
    setState(() {
      _isEditing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocale.notesUpdatedSuccess.getString(context)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Opens the image viewer in full screen mode starting at the specified index.
  void _openFullScreenImage(int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _FullScreenImageViewer(
          images: widget.sighting.images,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < kDesktopBreakpoint;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _maxImageWidth),
              child: AspectRatio(
                aspectRatio: _imageAspectRatio,
                child: Stack(
                  children: [
                    widget.sighting.images.isNotEmpty
                        ? PageView.builder(
                            controller: _pageController,
                            itemCount: widget.sighting.images.length,
                            onPageChanged: (index) {
                              setState(() {
                                _currentImageIndex = index;
                              });
                            },
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                onTap: () => _openFullScreenImage(index),
                                child: Image.network(
                                  widget.sighting.images[index],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const PlaceholderImage();
                                  },
                                ),
                              );
                            },
                          )
                        : const PlaceholderImage(),
                    // Navigation arrows
                    if (widget.sighting.images.length > 1) ...[
                      // Left arrow
                      Positioned(
                        left: _arrowPadding,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: IconButton(
                            onPressed: _currentImageIndex > 0
                                ? () {
                                    _pageController.previousPage(
                                      duration: _pageTransitionDuration,
                                      curve: _pageTransitionCurve,
                                    );
                                  }
                                : null,
                            icon: const Icon(Icons.arrow_back_ios),
                            iconSize: _arrowIconSize,
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black.withValues(alpha: _arrowBackgroundAlpha),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.black.withValues(alpha: _arrowDisabledBackgroundAlpha),
                              disabledForegroundColor: Colors.white.withValues(alpha: _arrowDisabledForegroundAlpha),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: _arrowPadding,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: IconButton(
                            onPressed: _currentImageIndex < widget.sighting.images.length - 1
                                ? () {
                                    _pageController.nextPage(
                                      duration: _pageTransitionDuration,
                                      curve: _pageTransitionCurve,
                                    );
                                  }
                                : null,
                            icon: const Icon(Icons.arrow_forward_ios),
                            iconSize: _arrowIconSize,
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black.withValues(alpha: _arrowBackgroundAlpha),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.black.withValues(alpha: _arrowDisabledBackgroundAlpha),
                              disabledForegroundColor: Colors.white.withValues(alpha: _arrowDisabledForegroundAlpha),
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (widget.sighting.images.length > 1)
                      Positioned(
                        bottom: 16,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            widget.sighting.images.length,
                            (index) => Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _currentImageIndex == index
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.sighting.flowerName,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildInfoRow(
                    context,
                    Icons.location_on,
                    AppLocale.location.getString(context),
                    widget.sighting.location,
                  ),
                  const SizedBox(height: 12),

                  _buildInfoRow(
                    context,
                    Icons.calendar_today,
                    AppLocale.date.getString(context),
                    widget.sighting.formattedDate,
                  ),
                  const SizedBox(height: 12),

                  _buildInfoRow(
                    context,
                    Icons.person,
                    AppLocale.sightedBy.getString(context),
                    widget.sighting.userName,
                  ),
                  
                  // Display AI model information if available (only for researchers)
                  if (_isResearcher && widget.sighting.aiModelUsed != null) ...[
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      context,
                      Icons.psychology,
                      AppLocale.aiModel.getString(context),
                      widget.sighting.aiModelUsed!,
                    ),
                  ],
                  if (_isResearcher && widget.sighting.aiConfidence != null) ...[
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      context,
                      Icons.verified,
                      AppLocale.confidence.getString(context),
                      '${(widget.sighting.aiConfidence! * 100).toStringAsFixed(1)}%',
                    ),
                  ],
                  
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocale.notes.getString(context),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_isOwner)
                        Row(
                          children: [
                            if (_isEditing) ...[
                              TextButton(
                                onPressed: _toggleEdit,
                                child: Text(AppLocale.cancel.getString(context)),
                              ),
                              const SizedBox(width: 8),
                              FilledButton.icon(
                                onPressed: _saveNotes,
                                icon: const Icon(Icons.save),
                                label: Text(AppLocale.save.getString(context)),
                              ),
                            ] else
                              IconButton(
                                onPressed: _toggleEdit,
                                icon: const Icon(Icons.edit),
                                tooltip: AppLocale.editNotes.getString(context),
                              ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_isEditing)
                    TextField(
                      controller: _notesController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: 'Aggiungi le tue note...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.sighting.notes.isEmpty
                            ? AppLocale.noNotesAvailable.getString(context)
                            : widget.sighting.notes,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a row displaying an icon, label, and value.
  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ],
    );
  }
}

/// A full-screen image viewer widget with zoom and swipe capabilities.
///
/// Displays images in a full-screen PageView with interactive zoom
/// and navigation between multiple images.
class _FullScreenImageViewer extends StatefulWidget {
  /// List of image URLs to display.
  final List<String> images;
  
  /// The index of the image to display initially.
  final int initialIndex;

  /// Creates a [_FullScreenImageViewer] widget.
  const _FullScreenImageViewer({
    required this.images,
    required this.initialIndex,
  });

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer> {
  late PageController _pageController;
  late int _currentIndex;
  late TransformationController _transformationController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _transformationController = TransformationController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${_currentIndex + 1} / ${widget.images.length}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.images.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
            // Reset zoom when changing images
            _transformationController.value = Matrix4.identity();
          });
        },
        itemBuilder: (context, index) {
          return InteractiveViewer(
            transformationController: _transformationController,
            minScale: 1.0,
            maxScale: 4.0,
            child: Center(
              child: Image.network(
                widget.images[index],
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.black,
                    child: const Icon(
                      Icons.local_florist,
                      size: 100,
                      color: Colors.white,
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
