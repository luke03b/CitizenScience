import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:provider/provider.dart';
import '../widgets/custom_app_bar.dart';
import '../utils/platform_utils.dart';
import '../l10n/app_locale.dart';
import '../providers/locale_provider.dart';
import 'map_screen.dart';
import 'collection_screen.dart';
import 'settings_screen.dart';

/// Main application layout screen with adaptive navigation.
///
/// Provides navigation between Map, Collection, and Settings screens.
/// Adapts UI based on platform: shows a drawer for web browsers and
/// a bottom navigation bar for standalone PWA installations.
class MainLayoutScreen extends StatefulWidget {
  const MainLayoutScreen({super.key});

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    MapScreen(),
    CollectionScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isStandalone = PlatformUtils.isStandalonePWA();

    return Scaffold(
      appBar: CustomAppBar(
        title: AppLocale.citizenScience.getString(context),
        showLogo: true,
        leading: !isStandalone
            ? Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                ),
              )
            : null,
      ),
      drawer: !isStandalone ? _buildDrawer(context) : null,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: isStandalone
          ? _buildBottomNavigationBar(context)
          : null,
    );
  }

  /// Builds the drawer navigation for web browser mode.
  ///
  /// Displays map and collection items at the top, with settings at the bottom.
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // Top menu items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: Icon(
                    _currentIndex == 0 ? Icons.map : Icons.map_outlined,
                  ),
                  title: Text(AppLocale.mapLabel.getString(context)),
                  selected: _currentIndex == 0,
                  onTap: () {
                    setState(() {
                      _currentIndex = 0;
                    });
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: Icon(
                    _currentIndex == 1
                        ? Icons.collections
                        : Icons.collections_outlined,
                  ),
                  title: Text(AppLocale.collectionLabel.getString(context)),
                  selected: _currentIndex == 1,
                  onTap: () {
                    setState(() {
                      _currentIndex = 1;
                    });
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
          // Bottom menu items: Language toggle and Settings
          const Divider(height: 1),
          Consumer<LocaleProvider>(
            builder: (context, localeProvider, child) {
              final isItalian = localeProvider.locale.languageCode == 'it';
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.language,
                      size: 20,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 8),
                    _LanguageToggleButton(
                      flag: '🇮🇹',
                      label: 'ITA',
                      isSelected: isItalian,
                      isLeft: true,
                      onTap: () => localeProvider.setLocale(const Locale('it')),
                    ),
                    _LanguageToggleButton(
                      flag: '🇬🇧',
                      label: 'ENG',
                      isSelected: !isItalian,
                      isLeft: false,
                      onTap: () => localeProvider.setLocale(const Locale('en')),
                    ),
                  ],
                ),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(
              _currentIndex == 2 ? Icons.settings : Icons.settings_outlined,
            ),
            title: Text(AppLocale.settingsLabel.getString(context)),
            selected: _currentIndex == 2,
            onTap: () {
              setState(() {
                _currentIndex = 2;
              });
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  /// Builds the bottom navigation bar for standalone PWA mode.
  ///
  /// Provides quick access to Map, Collection, and Settings screens.
  Widget _buildBottomNavigationBar(BuildContext context) {
    return NavigationBar(
      backgroundColor: Theme.of(context).colorScheme.surface,
      selectedIndex: _currentIndex,
      onDestinationSelected: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.map_outlined),
          selectedIcon: const Icon(Icons.map),
          label: AppLocale.mapLabel.getString(context),
        ),
        NavigationDestination(
          icon: const Icon(Icons.collections_outlined),
          selectedIcon: const Icon(Icons.collections),
          label: AppLocale.collectionLabel.getString(context),
        ),
        NavigationDestination(
          icon: const Icon(Icons.settings_outlined),
          selectedIcon: const Icon(Icons.settings),
          label: AppLocale.settingsLabel.getString(context),
        ),
      ],
    );
  }
}

/// A single button in the ITA / ENG language toggle inside the drawer.
///
/// The left button has a rounded left border and the right button has a
/// rounded right border, giving the pair a pill-shaped toggle appearance.
class _LanguageToggleButton extends StatelessWidget {
  const _LanguageToggleButton({
    required this.flag,
    required this.label,
    required this.isSelected,
    required this.isLeft,
    required this.onTap,
  });

  final String flag;
  final String label;
  final bool isSelected;
  final bool isLeft;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final borderRadius = BorderRadius.horizontal(
      left: isLeft ? const Radius.circular(20) : Radius.zero,
      right: isLeft ? Radius.zero : const Radius.circular(20),
    );

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest,
          borderRadius: borderRadius,
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outline.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(flag, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
