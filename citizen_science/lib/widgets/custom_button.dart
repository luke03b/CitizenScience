import 'package:flutter/material.dart';

/// A customizable button widget with loading and outlined styles.
///
/// This widget supports both elevated and outlined button styles,
/// optional icons, loading states, and custom colors.
class CustomButton extends StatelessWidget {
  /// The text displayed on the button.
  final String text;
  
  /// Callback function executed when the button is pressed.
  final VoidCallback onPressed;
  
  /// Whether the button is in a loading state, showing a progress indicator.
  final bool isLoading;
  
  /// Whether to use an outlined style instead of elevated.
  final bool isOutlined;
  
  /// Optional icon displayed before the text.
  final IconData? icon;
  
  /// Optional custom background color for the button.
  final Color? color;

  /// Creates a [CustomButton] widget.
  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (isOutlined) {
      return OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _buildChild(),
      );
    }

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: color ?? Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      child: _buildChild(),
    );
  }

  /// Builds the child content of the button.
  ///
  /// Returns a loading indicator if [isLoading] is true,
  /// otherwise returns the text with an optional icon.
  Widget _buildChild() {
    if (isLoading) {
      return const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon),
          const SizedBox(width: 8),
          Text(text),
        ],
      );
    }

    return Text(text);
  }
}
