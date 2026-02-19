import 'package:flutter/material.dart';

/// A placeholder image widget displayed when no image is available.
///
/// Shows a flower icon on a themed background, used as a fallback
/// for sighting images that fail to load or are not provided.
class PlaceholderImage extends StatelessWidget {
  /// Creates a [PlaceholderImage] widget.
  const PlaceholderImage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.local_florist,
        size: 64,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}