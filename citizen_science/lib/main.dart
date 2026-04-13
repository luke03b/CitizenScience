import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'providers/theme_provider.dart';
import 'providers/app_state_provider.dart';
import 'providers/locale_provider.dart';
import 'l10n/app_locale.dart';
import 'screens/splash_screen.dart';

/// Entry point for the Citizen Science Flutter application.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterLocalization.instance.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AppStateProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

/// Root widget of the Citizen Science application.
///
/// Sets up the MaterialApp with theme management, localization and navigation.
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final FlutterLocalization _localization = FlutterLocalization.instance;
  bool _localeLoaded = false;

  @override
  void initState() {
    super.initState();
    _localization.init(
      mapLocales: AppLocale.locales,
      initLanguageCode: AppLocale.it,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Load saved locale only once after dependencies are available
    if (!_localeLoaded) {
      _localeLoaded = true;
      context.read<LocaleProvider>().loadLocale();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, LocaleProvider>(
      builder: (context, themeProvider, localeProvider, child) {
        // Update localization when locale changes
        _localization.translate(localeProvider.locale.languageCode);

        return MaterialApp(
          title: 'Citizen Science',
          debugShowCheckedModeBanner: false,
          theme: themeProvider.currentTheme,
          supportedLocales: _localization.supportedLocales,
          localizationsDelegates: _localization.localizationsDelegates,
          home: const SplashScreen(),
        );
      },
    );
  }
}
