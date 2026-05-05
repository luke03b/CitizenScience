import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localization/flutter_localization.dart';
import '../providers/app_state_provider.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../l10n/app_locale.dart';
import '../utils/error_handler.dart';
import 'registration_screen.dart';
import 'main_layout_screen.dart';
import '../widgets/themed_logo.dart';

/// Login screen for user authentication.
///
/// Provides email and password fields for users to sign in to their account.
/// Includes validation and navigation to the registration screen for new users.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Validates form inputs and attempts to log in the user.
  ///
  /// On success, navigates to [MainLayoutScreen].
  /// On failure, displays an error message via SnackBar.
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final appState = Provider.of<AppStateProvider>(context, listen: false);
      await appState.login(_emailController.text, _passwordController.text);

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainLayoutScreen()),
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
                      AppLocale.welcomeLogin.getString(context),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 48),
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
                    const SizedBox(height: 32),
                    CustomButton(
                      text: AppLocale.login.getString(context),
                      onPressed: _handleLogin,
                      isLoading: _isLoading,
                      icon: Icons.login,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppLocale.noAccount.getString(context),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const RegistrationScreen(),
                              ),
                            );
                          },
                          child: Text(AppLocale.register.getString(context)),
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
