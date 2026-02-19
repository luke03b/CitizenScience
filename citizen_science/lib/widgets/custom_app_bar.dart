import 'package:flutter/material.dart';

/// A custom application bar widget with optional logo and actions.
///
/// This widget provides a consistent app bar design throughout the app,
/// featuring an optional science icon logo and customizable actions.
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// The title text displayed in the app bar.
  final String title;
  
  /// Whether to show the science icon logo next to the title.
  final bool showLogo;
  
  /// Optional list of action widgets displayed on the right side.
  final List<Widget>? actions;
  
  /// Optional widget displayed on the left side, typically a back button.
  final Widget? leading;

  /// Creates a [CustomAppBar] widget.
  const CustomAppBar({
    super.key,
    required this.title,
    this.showLogo = true,
    this.actions,
    this.leading,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.surface,
      leading: leading,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showLogo) ...[
            Icon(
              Icons.science,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 8),
          ],
          Text(title),
        ],
      ),
      actions: actions,
    );
  }
}
