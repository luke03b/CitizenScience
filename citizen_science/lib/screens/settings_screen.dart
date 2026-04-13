import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localization/flutter_localization.dart';
import '../providers/app_state_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/locale_provider.dart';
import '../l10n/app_locale.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../utils/error_handler.dart';
import 'login_screen.dart';
import 'change_password_screen.dart';
import 'ai_model_selection_screen.dart';

/// Settings screen for user profile and app preferences management.
///
/// Allows users to edit their profile information, toggle dark mode,
/// change password, and log out. Researchers have an additional option
/// to select AI models.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    _firstNameController = TextEditingController(
      text: appState.currentUser?.firstName ?? '',
    );
    _lastNameController = TextEditingController(
      text: appState.currentUser?.lastName ?? '',
    );
    _emailController = TextEditingController(
      text: appState.currentUser?.email ?? '',
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  /// Toggles edit mode and resets form fields on cancel.
  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        // Reset controllers on cancel
        final appState = Provider.of<AppStateProvider>(context, listen: false);
        _firstNameController.text = appState.currentUser?.firstName ?? '';
        _lastNameController.text = appState.currentUser?.lastName ?? '';
        _emailController.text = appState.currentUser?.email ?? '';
      }
    });
  }

  /// Validates and saves user profile changes to the backend.
  ///
  /// On success, exits edit mode and shows a success message.
  /// On failure, displays an error message.
  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final appState = Provider.of<AppStateProvider>(context, listen: false);
      await appState.updateUserInfoApi(
        _firstNameController.text,
        _lastNameController.text,
        _emailController.text,
      );

      if (!mounted) return;

      setState(() {
        _isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocale.infoUpdatedSuccess.getString(context)),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
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
        setState(() => _isLoading = false);
      }
    }
  }

  /// Shows a confirmation dialog and logs out the user.
  ///
  /// On confirmation, clears the navigation stack and returns to login screen.
  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocale.confirmLogout.getString(context)),
        content: Text(AppLocale.confirmLogoutMessage.getString(context)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocale.cancel.getString(context)),
          ),
          FilledButton(
            onPressed: () async {
              final dialogContext = context;
              final rootNavigator = Navigator.of(this.context);
              Navigator.of(dialogContext).pop(); // Close dialog
              final appState = Provider.of<AppStateProvider>(
                this.context,
                listen: false,
              );
              await appState.logout();
              if (!mounted) return;
              rootNavigator.pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            child: Text(AppLocale.exit.getString(context)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // User info card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              AppLocale.userInfo.getString(context),
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            if (!_isEditing)
                              IconButton(
                                onPressed: _toggleEdit,
                                icon: const Icon(Icons.edit),
                                tooltip: AppLocale.edit.getString(context),
                              ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        CustomTextField(
                          controller: _firstNameController,
                          label: AppLocale.firstName.getString(context),
                          hint: AppLocale.yourFirstName.getString(context),
                          prefixIcon: Icons.person,
                          isEnabled: _isEditing,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return AppLocale.enterFirstName.getString(
                                context,
                              );
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _lastNameController,
                          label: AppLocale.lastName.getString(context),
                          hint: AppLocale.yourLastName.getString(context),
                          prefixIcon: Icons.person_outline,
                          isEnabled: _isEditing,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return AppLocale.enterLastName.getString(context);
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _emailController,
                          label: AppLocale.email.getString(context),
                          hint: AppLocale.yourEmail.getString(context),
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: Icons.email,
                          isEnabled: _isEditing,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return AppLocale.enterEmail.getString(context);
                            }
                            if (!value.contains('@')) {
                              return AppLocale.enterValidEmail.getString(
                                context,
                              );
                            }
                            return null;
                          },
                        ),
                        if (_isEditing) ...[
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: _toggleEdit,
                                child: Text(
                                  AppLocale.cancel.getString(context),
                                ),
                              ),
                              const SizedBox(width: 8),
                              FilledButton.icon(
                                onPressed: _isLoading ? null : _saveChanges,
                                icon: _isLoading
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.save),
                                label: Text(AppLocale.save.getString(context)),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Dark mode toggle and language selector
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
                        AppLocale.appearance.getString(context),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Consumer<ThemeProvider>(
                        builder: (context, themeProvider, child) {
                          return SwitchListTile(
                            title: Text(
                              AppLocale.darkMode.getString(context),
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            subtitle: Text(
                              AppLocale.toggleDarkMode.getString(context),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                            ),
                            value: themeProvider.isDarkMode,
                            onChanged: (value) {
                              themeProvider.toggleTheme();
                            },
                            secondary: Icon(
                              themeProvider.isDarkMode
                                  ? Icons.dark_mode
                                  : Icons.light_mode,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          );
                        },
                      ),
                      const Divider(),
                      Consumer<LocaleProvider>(
                        builder: (context, localeProvider, child) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.language,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        AppLocale.language.getString(context),
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyLarge,
                                      ),
                                      Text(
                                        AppLocale.selectLanguage.getString(
                                          context,
                                        ),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withValues(alpha: 0.6),
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primaryContainer
                                        .withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .outline
                                          .withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: DropdownButton<String>(
                                    value: localeProvider.locale.languageCode,
                                    underline: const SizedBox(),
                                    isDense: true,
                                    borderRadius: BorderRadius.circular(12),
                                    items: [
                                      DropdownMenuItem(
                                        value: 'it',
                                        child: Text(
                                          AppLocale.italian.getString(context),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w500,
                                              ),
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'en',
                                        child: Text(
                                          AppLocale.english.getString(context),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w500,
                                              ),
                                        ),
                                      ),
                                    ],
                                    onChanged: (String? newValue) {
                                      if (newValue != null) {
                                        localeProvider.setLocale(
                                          Locale(newValue),
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // AI Model Selection (only for researchers)
              Consumer<AppStateProvider>(
                builder: (context, appState, child) {
                  if (appState.currentUser?.isResearcher != true) {
                    return const SizedBox.shrink();
                  }

                  return Column(
                    children: [
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const AiModelSelectionScreen(),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.smart_toy,
                                  size: 32,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        AppLocale.selectAiModel.getString(
                                          context,
                                        ),
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyLarge,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        AppLocale.configureAiModel.getString(
                                          context,
                                        ),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w500,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.5),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  );
                },
              ),

              // Logout button
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
                        AppLocale.account.getString(context),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      CustomButton(
                        text: AppLocale.changePassword.getString(context),
                        icon: Icons.lock_reset,
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  const ChangePasswordScreen(),
                            ),
                          );
                        },
                        isOutlined: false,
                      ),
                      const SizedBox(height: 12),
                      CustomButton(
                        text: AppLocale.logout.getString(context),
                        icon: Icons.logout,
                        onPressed: _handleLogout,
                        isOutlined: false,
                        color: Theme.of(context).colorScheme.error,
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
}
