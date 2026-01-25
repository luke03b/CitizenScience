import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import 'main_layout_screen.dart';

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

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    final appState = Provider.of<AppStateProvider>(context, listen: false);
    appState.register(
      _firstNameController.text,
      _lastNameController.text,
      _emailController.text,
      _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const MainLayoutScreen()),
      (route) => false,
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
                      'Crea il tuo account',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 48),
                    CustomTextField(
                      controller: _firstNameController,
                      label: 'Nome',
                      hint: 'inserisci il tuo nome',
                      prefixIcon: Icons.person,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Inserisci il tuo nome';
                        }
                        if (value.length < 2) {
                          return 'Il nome deve essere di almeno 2 caratteri';
                        }
                        if (!RegExp(r'^[a-zA-Z]+$').hasMatch(value)) {
                          return 'Il nome può contenere solo lettere';
                        }
                        if (value.length > 50) {
                          return 'Il nome non può superare i 50 caratteri';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _lastNameController,
                      label: 'Cognome',
                      hint: 'inserisci il tuo cognome',
                      prefixIcon: Icons.person_outline,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Inserisci il tuo cognome';
                        }
                        if (value.length < 2) {
                          return 'Il cognome deve essere di almeno 2 caratteri';
                        }
                        if (!RegExp(r'^[a-zA-Z]+$').hasMatch(value)) {
                          return 'Il cognome può contenere solo lettere';
                        }
                        if (value.length > 50) {
                          return 'Il cognome non può superare i 50 caratteri';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
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
                      text: 'Registrati',
                      onPressed: _handleRegistration,
                      isLoading: _isLoading,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Hai già un account? ',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('Accedi'),
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
