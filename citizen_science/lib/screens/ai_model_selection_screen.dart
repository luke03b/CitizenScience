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
///
/// When [onModelSelected] is provided the screen operates in "pick" mode:
/// confirming a selection calls the callback with the chosen model name and
/// pops the route WITHOUT persisting the choice as the user's default.
/// When [onModelSelected] is null (the default) the screen operates in
/// "save default" mode, showing two tabs:
///   - "Il tuo modello" tab: persists the user's personal model choice.
///   - "Modello Globale" tab: sets the global default model for all users.
class AiModelSelectionScreen extends StatefulWidget {
  /// Optional callback used when the screen is opened from the sighting
  /// creation flow.  Receives the chosen model name and is called instead
  /// of persisting the selection to the backend.
  final void Function(String modelName)? onModelSelected;

  const AiModelSelectionScreen({super.key, this.onModelSelected});

  @override
  State<AiModelSelectionScreen> createState() => _AiModelSelectionScreenState();
}

class _AiModelSelectionScreenState extends State<AiModelSelectionScreen> {
  List<Map<String, dynamic>> _models = [];
  String? _selectedModel;
  String? _selectedGlobalModel;
  String? _defaultModel;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isSavingGlobal = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadModels();
  }

  /// Fetches the list of available AI models from the backend.
  /// Also retrieves the currently selected model and the current global default.
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

      final models = results[0] as List<Map<String, dynamic>>;
      final selectedModel = results[1] as String?;

      if (!mounted) return;

      // Find the model marked as default in the backend
      final defaultEntry = models.firstWhere(
        (m) => m['isDefault'] == true,
        orElse: () => {},
      );
      final defaultModelName = defaultEntry.isNotEmpty
          ? defaultEntry['name'] as String?
          : null;

      setState(() {
        _models = models;
        _defaultModel = defaultModelName;
        // Pre-select the current global default in the global model tab
        _selectedGlobalModel = defaultModelName;
        // Set the currently selected model if it exists in the available models
        if (selectedModel != null &&
            models.any((m) => m['name'] == selectedModel)) {
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

  /// Confirms the selected personal AI model ("Il tuo modello" tab).
  ///
  /// In "save default" mode (no [onModelSelected] callback) the choice is
  /// persisted to the backend and the screen pops.
  /// In "pick" mode (callback provided) the callback is invoked with the
  /// chosen model name and the screen pops WITHOUT touching the user's default.
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

    // "Pick" mode – return the selected model to the caller without saving.
    if (widget.onModelSelected != null) {
      widget.onModelSelected!(_selectedModel!);
      if (mounted) Navigator.of(context).pop();
      return;
    }

    // "Save default" mode – persist the selection to the backend.
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

  /// Saves the global model selection ("Modello Globale" tab).
  ///
  /// Persists [_selectedGlobalModel] as the new global default model.
  Future<void> _saveGlobalModel() async {
    if (_isSavingGlobal) return;
    if (_selectedGlobalModel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocale.selectModelPrompt.getString(context)),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSavingGlobal = true);

    try {
      final appState = Provider.of<AppStateProvider>(context, listen: false);
      await appState.apiService.setDefaultAiModel(_selectedGlobalModel!);

      if (!mounted) return;

      setState(() {
        _defaultModel = _selectedGlobalModel;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocale.setDefaultSuccess.getString(context)),
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
        setState(() => _isSavingGlobal = false);
      }
    }
  }

  /// Shows a dialog with the description of the given AI model.
  /// If no description is available, an informative message is shown instead.
  void _showModelInfoDialog(Map<String, dynamic> model) {
    final description = model['description'] as String?;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocale.modelInfoTitle.getString(context)),
        content: Text(
          description != null && description.isNotEmpty
              ? description
              : AppLocale.noModelDescription.getString(context),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppLocale.close.getString(context)),
          ),
        ],
      ),
    );
  }

  /// Builds the scrollable list of models with radio buttons for one tab.
  ///
  /// [isGlobalTab] controls which selection state and save action are used:
  /// - Personal tab (`isGlobalTab: false`): uses [_selectedModel] / [_saveModel].
  ///   The "Predefinito" badge is shown on the current global default for context.
  /// - Global tab (`isGlobalTab: true`): uses [_selectedGlobalModel] / [_saveGlobalModel].
  Widget _buildModelListView(
    BuildContext context,
    bool isMobile, {
    required bool isGlobalTab,
  }) {
    final groupValue = isGlobalTab ? _selectedGlobalModel : _selectedModel;
    final isBusy = isGlobalTab ? _isSavingGlobal : _isSaving;

    return SingleChildScrollView(
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
                        RadioGroup<String>(
                          groupValue: groupValue,
                          onChanged: (value) {
                            setState(() {
                              if (isGlobalTab) {
                                _selectedGlobalModel = value;
                              } else {
                                _selectedModel = value;
                              }
                            });
                          },
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _models.length,
                            itemBuilder: (context, index) {
                              final model = _models[index];
                              final modelName = model['name'] as String;
                              // In the personal tab show the "Predefinito" badge
                              // on the current global default for context.
                              final showDefaultBadge =
                                  !isGlobalTab && _defaultModel == modelName;
                              return RadioListTile<String>(
                                title: Row(
                                  children: [
                                    Expanded(child: Text(modelName)),
                                    if (showDefaultBadge)
                                      Container(
                                        margin: const EdgeInsets.only(left: 8),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primaryContainer,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          AppLocale.useDefaultModel.getString(
                                            context,
                                          ),
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onPrimaryContainer,
                                              ),
                                        ),
                                      ),
                                  ],
                                ),
                                value: modelName,
                                secondary: IconButton(
                                  icon: const Icon(Icons.info_outline),
                                  tooltip: AppLocale.modelInfoTitle.getString(
                                    context,
                                  ),
                                  onPressed: () => _showModelInfoDialog(model),
                                ),
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 24),
                      CustomButton(
                        text: AppLocale.confirmSelectionButton.getString(
                          context,
                        ),
                        icon: Icons.check,
                        isLoading: isBusy,
                        onPressed: isGlobalTab ? _saveGlobalModel : _saveModel,
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
    );
  }

  Widget _buildErrorOrLoading(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Center(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final isLoadingOrError = _isLoading || _error != null;

    // "Pick" mode: single view without tabs (global model selection not needed).
    if (widget.onModelSelected != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(AppLocale.aiModelSelection.getString(context)),
        ),
        body: isLoadingOrError
            ? _buildErrorOrLoading(context)
            : _buildModelListView(context, isMobile, isGlobalTab: false),
      );
    }

    // "Save default" mode: two tabs – personal model and global model.
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocale.aiModelSelection.getString(context)),
          bottom: TabBar(
            tabs: [
              Tab(text: AppLocale.yourModel.getString(context)),
              Tab(text: AppLocale.globalModel.getString(context)),
            ],
          ),
        ),
        body: isLoadingOrError
            ? _buildErrorOrLoading(context)
            : TabBarView(
                children: [
                  _buildModelListView(context, isMobile, isGlobalTab: false),
                  _buildModelListView(context, isMobile, isGlobalTab: true),
                ],
              ),
      ),
    );
  }
}
