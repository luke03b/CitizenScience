import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localization/flutter_localization.dart';
import '../l10n/app_locale.dart';
import '../models/sighting_model.dart';
import '../providers/app_state_provider.dart';
import '../widgets/sighting_detail_content.dart';
import '../utils/error_handler.dart';

/// Detail screen for viewing a single flower sighting.
/// 
/// Displays comprehensive information about the sighting and allows the owner
/// to delete it. Shows an app bar with delete action if the current user
/// is the owner of the sighting.
class SightingDetailScreen extends StatelessWidget {
  final SightingModel sighting;

  const SightingDetailScreen({
    super.key,
    required this.sighting,
  });

  /// Shows a confirmation dialog before deleting the sighting.
  Future<void> _showDeleteConfirmation(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(AppLocale.confirmDelete.getString(context)),
          content: Text(AppLocale.deleteConfirmationMessage.getString(context)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(AppLocale.cancel.getString(context)),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _deleteSighting(context);
              },
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: Text(AppLocale.deleteAction.getString(context)),
            ),
          ],
        );
      },
    );
  }

  /// Deletes the sighting from the backend and updates the UI.
  /// 
  /// Shows a loading dialog during deletion and displays success/error
  /// messages. Navigates back to the previous screen on success.
  Future<void> _deleteSighting(BuildContext context) async {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    
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
                    Text(AppLocale.deleteInProgress.getString(context)),
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
      
      // Show success message and navigate back
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(AppLocale.sightingDeleted.getString(context)),
          duration: const Duration(seconds: 2),
        ),
      );
      navigator.pop();
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
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final isOwner = appState.currentUser?.id == sighting.userId;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocale.sightingDetails.getString(context)),
        actions: [
          if (isOwner)
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: AppLocale.deleteSightingTooltip.getString(context),
              onPressed: () => _showDeleteConfirmation(context),
            ),
        ],
      ),
      body: SightingDetailContent(sighting: sighting),
    );
  }
}
