import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import '../widgets/custom_app_bar.dart';
import '../utils/platform_utils.dart';
import '../l10n/app_locale.dart';
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
        leading: !isStandalone ? Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ) : null,
      ),
      drawer: !isStandalone ? _buildDrawer(context) : null,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: isStandalone ? _buildBottomNavigationBar(context) : null,
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
                    _currentIndex == 1 ? Icons.collections : Icons.collections_outlined,
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
          // Bottom menu item (Settings)
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
