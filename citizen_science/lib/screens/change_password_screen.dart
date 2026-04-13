import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localization/flutter_localization.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../providers/app_state_provider.dart';
import '../dto/change_password_request.dart';
import '../l10n/app_locale.dart';
import '../utils/error_handler.dart';

/// Screen for changing the user's password.
///
/// Requires the user to enter their old password, a new password,
/// and confirm the new password. Validates that the new password
/// is different from the old one and that both new password fields match.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Validates form inputs and submits the password change request.
  ///
  /// On success, navigates back to the settings screen with a success message.
  /// On failure, displays an error message.
  Future<void> _handleChangePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final appState = Provider.of<AppStateProvider>(context, listen: false);
      final request = ChangePasswordRequest(
        oldPassword: _oldPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      await appState.apiService.changePassword(request);

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocale.passwordChangedSuccess.getString(context)),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      // Go back to settings
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
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocale.changePasswordTitle.getString(context)),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16 : 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          AppLocale.changePasswordTitle.getString(context),
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppLocale.enterOldAndNew.getString(context),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                        ),
                        const SizedBox(height: 24),
                        CustomTextField(
                          controller: _oldPasswordController,
                          label: AppLocale.oldPassword.getString(context),
                          hint: AppLocale.enterOldPassword.getString(context),
                          isObscured: true,
                          prefixIcon: Icons.lock_outline,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return AppLocale.enterOldPassword.getString(
                                context,
                              );
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _newPasswordController,
                          label: AppLocale.newPassword.getString(context),
                          hint: AppLocale.enterNewPassword.getString(context),
                          isObscured: true,
                          prefixIcon: Icons.lock,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return AppLocale.enterNewPassword.getString(
                                context,
                              );
                            }
                            if (value.length < 6) {
                              return AppLocale.passwordMinLength.getString(
                                context,
                              );
                            }
                            if (value == _oldPasswordController.text) {
                              return AppLocale.newPasswordMustBeDifferent
                                  .getString(context);
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _confirmPasswordController,
                          label: AppLocale.passwordConfirmation.getString(
                            context,
                          ),
                          hint: AppLocale.confirmPassword.getString(context),
                          isObscured: true,
                          prefixIcon: Icons.lock_clock,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return AppLocale.confirmPassword.getString(
                                context,
                              );
                            }
                            if (value != _newPasswordController.text) {
                              return AppLocale.passwordsDontMatch.getString(
                                context,
                              );
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),
                        CustomButton(
                          text: AppLocale.changePasswordTitle.getString(
                            context,
                          ),
                          onPressed: _handleChangePassword,
                          isLoading: _isLoading,
                          icon: Icons.check,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
