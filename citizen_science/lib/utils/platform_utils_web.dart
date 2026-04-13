import 'package:web/web.dart' as web;

/// Web-specific implementation for detecting PWA standalone mode.
///
/// Uses the display-mode media query to detect if the app is running
/// as a standalone PWA on modern browsers.
bool checkStandaloneMode() {
  return web.window.matchMedia('(display-mode: standalone)').matches;
}
