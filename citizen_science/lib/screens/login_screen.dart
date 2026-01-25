import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import 'registration_screen.dart';
import 'main_layout_screen.dart';

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

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    final appState = Provider.of<AppStateProvider>(context, listen: false);
    appState.login(_emailController.text, _passwordController.text);

    setState(() => _isLoading = false);

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const MainLayoutScreen()),
    );
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
                    Icon(
                      Icons.science,
                      size: 80,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Citizen Science',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Benvenuto! Accedi per continuare',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 48),
                    CustomTextField(
                      controller: _emailController,
                      label: 'Email',
                      hint: 'inserisci la tua email',
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.email,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Inserisci la tua email';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'Inserisci un\'email valida';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _passwordController,
                      label: 'Password',
                      hint: 'inserisci la tua password',
                      isObscured: true,
                      prefixIcon: Icons.lock,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Inserisci la tua password';
                        }
                        if (value.length < 6) {
                          return 'La password deve essere di almeno 6 caratteri';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    CustomButton(
                      text: 'Accedi',
                      onPressed: _handleLogin,
                      isLoading: _isLoading,
                      icon: Icons.login,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Non hai un account? ',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const RegistrationScreen(),
                              ),
                            );
                          },
                          child: const Text('Registrati'),
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
