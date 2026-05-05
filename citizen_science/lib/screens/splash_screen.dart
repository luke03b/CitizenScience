import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:provider/provider.dart';
import '../l10n/app_locale.dart';
import '../providers/app_state_provider.dart';
import 'login_screen.dart';
import 'main_layout_screen.dart';
import '../widgets/themed_logo.dart';

/// Initial splash screen displayed when the app launches.
///
/// Shows the app logo and a loading indicator while checking if the user
/// can be automatically logged in via stored credentials.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  /// Waits for 2 seconds, checks auto-login status, then navigates to either
  /// [MainLayoutScreen] or [LoginScreen] based on authentication state.
  Future<void> _navigateToNextScreen() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final appState = Provider.of<AppStateProvider>(context, listen: false);

    // Check if user can auto-login
    final isAutoLoggedIn = await appState.checkAutoLogin();

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) =>
            isAutoLoggedIn ? const MainLayoutScreen() : const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: Center(
                    child: ThemedLogo(
                      width: 80,
                      height: 80,
                      fit: BoxFit.contain,
                      useThemeAsset: false,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            Text(
              AppLocale.citizenScience.getString(context),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 50),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
