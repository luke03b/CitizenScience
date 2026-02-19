import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:provider/provider.dart';
import '../l10n/app_locale.dart';
import '../providers/app_state_provider.dart';
import '../widgets/custom_button.dart';
import '../utils/error_handler.dart';

/// Screen for researchers to select the AI model for flower identification.
/// 
/// Fetches available models from the backend and allows researchers to
/// choose which model should be used for AI-powered flower identification.
/// This screen is only accessible to users with researcher privileges.
class AiModelSelectionScreen extends StatefulWidget {
  const AiModelSelectionScreen({super.key});

  @override
  State<AiModelSelectionScreen> createState() => _AiModelSelectionScreenState();
}

class _AiModelSelectionScreenState extends State<AiModelSelectionScreen> {
  List<String> _models = [];
  String? _selectedModel;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadModels();
  }

  /// Fetches the list of available AI models from the backend.
  /// Also retrieves the currently selected model and sets it as default.
  Future<void> _loadModels() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final appState = Provider.of<AppStateProvider>(context, listen: false);
      
      // Fetch available models and currently selected model in parallel
      final modelsFuture = appState.apiService.getAvailableAiModels();
      final selectedModelFuture = appState.apiService.getSelectedAiModel();
      final results = await Future.wait([modelsFuture, selectedModelFuture]);
      
      final models = results[0] as List<String>;
      final selectedModel = results[1] as String?;
      
      if (!mounted) return;
      
      setState(() {
        _models = models;
        // Set the currently selected model as default if it exists in the available models
        if (selectedModel != null && models.contains(selectedModel)) {
          _selectedModel = selectedModel;
        }
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _error = ErrorHandler.getErrorMessage(context, e);
        _isLoading = false;
      });
    }
  }

  /// Saves the selected AI model to the backend.
  /// 
  /// Validates that a model is selected before submitting.
  /// On success, navigates back to the settings screen.
  /// On failure, displays an error message.
  Future<void> _saveModel() async {
    if (_isSaving) return;
    if (_selectedModel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocale.selectModelPrompt.getString(context)),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final appState = Provider.of<AppStateProvider>(context, listen: false);
      await appState.apiService.selectAiModel(_selectedModel!);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocale.modelSelectedSuccess.getString(context)),
          backgroundColor: Colors.green,
        ),
      );
      
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ErrorHandler.getErrorMessage(context, e)),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocale.aiModelSelection.getString(context)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
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
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _loadModels,
                        icon: const Icon(Icons.refresh),
                        label: Text(AppLocale.retry.getString(context)),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.all(isMobile ? 16 : 32),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppLocale.availableModels.getString(context),
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  if (_models.isEmpty)
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Text(
                                        AppLocale.noModelsAvailable.getString(context),
                                        textAlign: TextAlign.center,
                                      ),
                                    )
                                  else
                                    ListView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: _models.length,
                                      itemBuilder: (context, index) {
                                        final model = _models[index];
                                        return RadioListTile<String>(
                                          title: Text(model),
                                          value: model,
                                          groupValue: _selectedModel,
                                          onChanged: (value) {
                                            setState(() {
                                              _selectedModel = value;
                                            });
                                          },
                                        );
                                      },
                                    ),
                                  const SizedBox(height: 24),
                                  CustomButton(
                                    text: AppLocale.confirmSelectionButton.getString(context),
                                    icon: Icons.check,
                                    onPressed: _saveModel,
                                    isOutlined: false,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }
}
