# Citizen Science App

A Flutter web application for citizen science observations with backend integration. This application is designed exclusively for web platforms as a Progressive Web App (PWA) with offline caching capabilities.

## Platform Support

This application is **web-only** and designed to run as a Progressive Web App. It does not support native mobile platforms (Android/iOS) or desktop platforms.

## Features

- User authentication (login/register) with JWT tokens
- Auto-login with token validation
- User roles: regular users and researchers
- Create sightings with photos, location, and date
- User profile management
- Password change functionality

## Getting Started

### Prerequisites

- Flutter SDK (>= 3.10.4)
- Dart SDK
- CitizenScienceBackend running (default: http://localhost:8080)

### Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```

### Backend Configuration

The app connects to the backend API. The base URL is configured in:
`lib/providers/api_service.dart`

```dart
static const String _baseUrl = 'http://localhost:8080/api';
```

**Important**: Update this URL based on your environment:
- For local development: `http://localhost:8080/api`
- For production: `https://your-production-domain.com/api`

### Running the App

```bash
# Run in web browser (Chrome recommended)
flutter run -d chrome

# Or use web-server mode
flutter run -d web-server
```

## API Integration

The app integrates with the CitizenScienceBackend providing the following endpoints:

### Authentication
- `POST /api/auth/register` - Register new user (with role: utente/ricercatore)
- `POST /api/auth/login` - Login user
- `PUT /api/auth/change-password` - Change password

### User Management
- `GET /api/users/me` - Get current user info
- `PUT /api/users/me` - Update user profile

### Sightings
- `POST /api/sightings` - Create sighting with photos
- `GET /api/sightings` - Get all sightings
- `GET /api/sightings/user/{userId}` - Get user's sightings
- `GET /api/sightings/location` - Get sightings by location
- `PUT /api/sightings/{id}/notes` - Update sighting notes
- `DELETE /api/sightings/{id}` - Delete sighting

## Key Features Implementation

### JWT Token Management
- Tokens are stored in `SharedPreferences` on login
- Automatically included in API requests via `Authorization` header
- Token expiration checked on app startup
- Auto-logout if token is expired

### Registration with Researcher Role
- Registration screen includes "Sei un ricercatore?" checkbox
- Sends role as "utente" or "ricercatore" to backend

### Sighting Creation
- Date picker pre-filled with current date/time
- Location automatically fetched from GPS
- Manual latitude/longitude entry available
- Multiple photo upload support
- Notes field (optional)

## Project Structure

```
lib/
├── dto/                    # Data Transfer Objects matching backend
├── models/                 # Local data models
├── providers/             # State management and API service
├── screens/               # UI screens
└── widgets/               # Reusable UI components
```

## Dependencies

- `http` - HTTP client for API calls
- `provider` - State management
- `shared_preferences` - Local storage for JWT token and offline data
- `jwt_decoder` - JWT token validation
- `image_picker` - Photo selection (web support)
- `geolocator` - Location services (web support)
- `flutter_map` - Map display
- `connectivity_plus` - Network connectivity monitoring
- `idb_shim` - IndexedDB storage for web offline caching

## Development Notes

- The app uses Provider for state management
- API service is centralized in `api_service.dart`
- JWT tokens are handled automatically by the API service
- Location permissions are requested when creating sightings
- Offline functionality caches user data and pending sightings

## Offline Functionality

### Features

The app supports offline mode as a Progressive Web App with the following capabilities:

1. **Cached User Information**: User profile data (name, surname, email) is cached locally and available offline
2. **Pending Sightings**: Sightings created offline are saved locally with status "In attesa di rete" (Waiting for network)
3. **Automatic Sync**: When network connection is restored, pending sightings are automatically uploaded
4. **Network Status Monitoring**: Real-time monitoring of network connectivity
5. **User Feedback**: Clear messages when offline ("Nessuna connessione di rete. Riprova")
6. **IndexedDB Storage**: Photos are stored in the browser's IndexedDB for reliable offline access

### Offline Behavior

**When Offline:**
- ✅ View cached user profile information
- ✅ Create new sightings (saved as pending)
- ❌ Load map sightings (shows "Nessuna connessione di rete. Riprova")
- ❌ Update profile information (shows "Nessuna connessione di rete. Riprova")
- ❌ Load user's sightings list (shows error message)

**When Connection Restored:**
- ✅ Pending sightings automatically sync to server
- ✅ User can manually trigger sync from collection screen
- ✅ All API operations resume normal functionality

### Technical Implementation

**Services:**
- `ConnectivityService`: Monitors network status using `connectivity_plus`
- `OfflineStorageService`: Manages local storage of user data and pending sightings (web-only)
- `OfflineStorageServicePlatform`: Web-specific implementation using IndexedDB

**Models:**
- `PendingSightingModel`: Represents sightings waiting to be uploaded

**Storage:**
- User data cached in `SharedPreferences`
- Pending sighting metadata in `SharedPreferences`
- Photos stored in IndexedDB as base64-encoded strings for web persistence

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/).


### **11. DEPENDENCIES & PACKAGES**

```yaml
# Core Flutter
flutter:
  sdk: flutter

# State Management
provider: ^6.1.5+1         # Provider pattern for app state

# Authentication & Storage
jwt_decoder: ^2.0.1        # JWT token validation
shared_preferences: ^2.5.4 # Local storage for tokens and offline data
idb_shim: ^2.8.2+2        # IndexedDB for web offline storage

# Network & Connectivity
http: ^1.6.0              # HTTP client
http_parser: ^4.1.2       # Multipart form data parsing
connectivity_plus: ^7.0.0 # Network connectivity monitoring

# Maps & Location
flutter_map: ^8.2.2                    # Interactive maps
flutter_map_marker_cluster: ^8.2.2    # Marker clustering
latlong2: ^0.9.1                       # GPS coordinates
geolocator: ^14.0.2                    # Location services (web support)

# Media
image_picker: ^1.2.1       # Camera & gallery access (web support)

# UI & Utilities
cupertino_icons: ^1.0.8    # iOS-style icons
```

---

## 📱 Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| **Web** | ✅ Full Support | Progressive Web App with offline caching via IndexedDB |
| **Android** | ❌ Not Supported | This app is web-only |
| **iOS** | ❌ Not Supported | This app is web-only |
| **Desktop** | ❌ Not Supported | This app is web-only |

---

## 🎨 Theming & UI

### Color Scheme

**Light Theme:**
- Primary: Green RGB(10, 113, 13)
- Background: White
- Text: Dark grey/black

**Dark Theme:**
- Primary: Light green
- Background: Dark grey/black
- Text: White/light grey

**Toggle**: Settings screen → "Tema scuro" switch

### Responsive Breakpoints

```dart
Mobile:  < 600px   - Single column, bottom nav
Tablet:  600-900px - Two columns, drawer nav
Desktop: > 1200px  - Three columns, drawer + side panel
```

### Typography

- **Headers**: Bold, 24-32px
- **Body**: Regular, 14-16px
- **Captions**: Light, 12px

---

## 🗺️ Map Configuration

### Default Location
```dart
Latitude: 45.4642  (Milan, Italy)
Longitude: 9.1900
Zoom: 13
```

### Tile Layer
```dart
urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png"
maxZoom: 19
```

### Marker Clustering

**Cluster Sizes:**
- Small: 1-10 markers → Small circle
- Medium: 11-50 markers → Medium circle
- Large: 50+ markers → Large circle

**Zoom Behavior:**
- Tap cluster → Zoom in
- Tap marker → Show sighting details

---

## 🔧 Configuration

### API Base URL

**File**: `lib/providers/api_service.dart`

```dart
static const String _baseUrl = 'http://localhost:8080/api';
```

**Environment-specific URLs:**

| Environment | URL |
|----------|-----|
| **Local Development** | `http://localhost:8080/api` |
| **Production** | `https://yourdomain.com/api` |

### Permissions

**Web** - No special permissions configuration needed. The browser will prompt users for:
- Location access (when creating sightings)
- Camera/file access (when uploading photos)

These are handled automatically by the browser's built-in permission system.

---

## 🏗️ Build & Deployment

### Development Build

```bash
# Web (Chrome)
flutter run -d chrome

# Web (Firefox)
flutter run -d firefox

# Web (Edge)
flutter run -d edge

# Web server mode
flutter run -d web-server

# List available devices
flutter devices
```

### Production Build

**Web**:
```bash
flutter build web --release
# Output: build/web/

# Deploy to server
cp -r build/web/* /var/www/html/
```

### Docker Build

**Dockerfile** (already exists):
```dockerfile
FROM nginx:alpine
COPY build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

**Build & Run**:
```bash
# Build Flutter web
flutter build web --release

# Build Docker image
docker build -t citizen-science-frontend .

# Run container
docker run -p 8081:80 citizen-science-frontend
```

---

## 🧪 Testing

### Unit Tests

**Run tests**:
```bash
flutter test
```

**Test file location**: `test/`

**Example test**:
```dart
test('ValidationUtils validates coordinates correctly', () {
  var result = ValidationUtils.validateCoordinates('45.4642', '9.1900');
  expect(result.isValid, true);
  
  result = ValidationUtils.validateCoordinates('invalid', '9.1900');
  expect(result.isValid, false);
});
```

### Widget Tests

```dart
testWidgets('Login screen renders correctly', (tester) async {
  await tester.pumpWidget(MaterialApp(home: LoginScreen()));
  
  expect(find.text('Email'), findsOneWidget);
  expect(find.text('Password'), findsOneWidget);
  expect(find.byType(ElevatedButton), findsWidgets);
});
```

### Integration Tests

**Directory**: `integration_test/`

```bash
flutter test integration_test/app_test.dart
```

---

## 🐛 Troubleshooting

### Common Issues

#### **1. "Unable to load asset" Error**

**Solution**:
```bash
flutter clean
flutter pub get
flutter run
```

#### **2. HTTP Connection Refused**

**Error**: `Connection refused: http://localhost:8080`

**Solutions**:
- ✅ Ensure backend is running
- ✅ Check firewall allows port 8080
- ✅ Verify backend is accessible from browser

**Test backend**:
```bash
curl http://localhost:8080/api/test
```

#### **3. Location Permission Denied**

**Web**: Browser will show a permission prompt. Click "Allow" to grant location access.

If denied:
- Check browser settings → Site Settings → Location
- Ensure location services are enabled in your OS

#### **4. Images Not Uploading**

**Check**:
- File size < 10MB
- File type is image (JPEG, PNG, GIF, WebP)
- Backend file upload enabled

**Debug**:
```dart
print('Image path: ${image.path}');
print('Image size: ${await image.length()} bytes');
```

#### **5. JWT Token Issues**

**Error**: `401 Unauthorized`

**Solutions**:
- Token expired → Re-login
- Token invalid → Clear storage and login again

**Clear token**:
```dart
SharedPreferences prefs = await SharedPreferences.getInstance();
await prefs.remove('jwt_token');
```

#### **6. Map Not Loading**

**Solutions**:
- Check internet connection
- Verify OpenStreetMap is accessible
- Check for JavaScript errors (Web platform)

**Alternative tile server**:
```dart
urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
```

#### **7. Build Fails**

**Web**:
```bash
flutter clean
flutter pub get
flutter build web --release
```

If issues persist, try:
```bash
# Clear Flutter cache
flutter clean
rm -rf .dart_tool/
rm pubspec.lock

# Reinstall dependencies
flutter pub get
```

### Debug Mode

**Enable Flutter DevTools**:
```bash
flutter pub global activate devtools
flutter pub global run devtools
```

**Logging**:
```dart
import 'package:flutter/foundation.dart';

if (kDebugMode) {
  print('Debug message');
}
```

---

## 📚 Additional Resources

- **Flutter Docs**: https://docs.flutter.dev/
- **Provider Package**: https://pub.dev/packages/provider
- **Flutter Map**: https://pub.dev/packages/flutter_map
- **Geolocator**: https://pub.dev/packages/geolocator
- **Image Picker**: https://pub.dev/packages/image_picker

---

## 🤝 Contributing

1. Fork the repository
2. Create feature branch: `git checkout -b feature/my-feature`
3. Make changes and test thoroughly
4. Commit: `git commit -m "Add my feature"`
5. Push: `git push origin feature/my-feature`
6. Create Pull Request

**Coding Standards**:
- Follow Dart style guide
- Use meaningful variable names
- Add comments for complex logic
- Write tests for new features
- Update documentation

---

## 📄 License

MIT License

---

## 🌟 Acknowledgments

- **Flutter Team** - Framework
- **OpenStreetMap** - Map tiles
- **Provider Package** - State management
- **PostGIS** - Geospatial backend support
