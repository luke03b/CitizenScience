import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localization/flutter_localization.dart';
import '../providers/app_state_provider.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../widgets/themed_logo.dart';
import '../l10n/app_locale.dart';
import '../utils/error_handler.dart';
import 'main_layout_screen.dart';

/// Registration screen for new user account creation.
///
/// Collects user information including first name, last name, email, password,
/// and role (researcher or regular user). Validates all inputs before submitting.
class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isResearcher = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Validates form inputs and creates a new user account.
  ///
  /// On success, navigates to [MainLayoutScreen] and clears navigation stack.
  /// On failure, displays an error message via SnackBar.
  Future<void> _handleRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final appState = Provider.of<AppStateProvider>(context, listen: false);
      await appState.register(
        _firstNameController.text,
        _lastNameController.text,
        _emailController.text,
        _passwordController.text,
        ruolo: _isResearcher ? 'ricercatore' : 'utente',
      );

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MainLayoutScreen()),
        (route) => false,
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

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 24 : 48,
              vertical: 24,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo
                    ThemedLogo(width: 80, height: 80, fit: BoxFit.contain),
                    const SizedBox(height: 16),
                    Text(
                      AppLocale.citizenScience.getString(context),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocale.createAccount.getString(context),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 48),
                    CustomTextField(
                      controller: _firstNameController,
                      label: AppLocale.firstName.getString(context),
                      hint: AppLocale.enterFirstName.getString(context),
                      prefixIcon: Icons.person,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return AppLocale.enterFirstName.getString(context);
                        }
                        if (value.length < 2) {
                          return AppLocale.firstNameMinLength.getString(
                            context,
                          );
                        }
                        if (!RegExp(r'^[a-zA-Z]+$').hasMatch(value)) {
                          return AppLocale.firstNameOnlyLetters.getString(
                            context,
                          );
                        }
                        if (value.length > 50) {
                          return AppLocale.firstNameMaxLength.getString(
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
                      hint: AppLocale.enterLastName.getString(context),
                      prefixIcon: Icons.person_outline,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return AppLocale.enterLastName.getString(context);
                        }
                        if (value.length < 2) {
                          return AppLocale.lastNameMinLength.getString(context);
                        }
                        if (!RegExp(r'^[a-zA-Z]+$').hasMatch(value)) {
                          return AppLocale.lastNameOnlyLetters.getString(
                            context,
                          );
                        }
                        if (value.length > 50) {
                          return AppLocale.lastNameMaxLength.getString(context);
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _emailController,
                      label: AppLocale.email.getString(context),
                      hint: AppLocale.enterEmail.getString(context),
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.email,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return AppLocale.enterEmail.getString(context);
                        }
                        if (!RegExp(
                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                        ).hasMatch(value)) {
                          return AppLocale.enterValidEmail.getString(context);
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _passwordController,
                      label: AppLocale.password.getString(context),
                      hint: AppLocale.enterPassword.getString(context),
                      isObscured: true,
                      prefixIcon: Icons.lock,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return AppLocale.enterPassword.getString(context);
                        }
                        if (value.length < 6) {
                          return AppLocale.passwordMinLength.getString(context);
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Researcher checkbox
                    Row(
                      children: [
                        Checkbox(
                          value: _isResearcher,
                          onChanged: (value) {
                            setState(() {
                              _isResearcher = value ?? false;
                            });
                          },
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _isResearcher = !_isResearcher;
                              });
                            },
                            child: Text(
                              AppLocale.iAmResearcher.getString(context),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    CustomButton(
                      text: AppLocale.register.getString(context),
                      onPressed: _handleRegistration,
                      isLoading: _isLoading,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppLocale.alreadyHaveAccount.getString(context),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text(AppLocale.login.getString(context)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
