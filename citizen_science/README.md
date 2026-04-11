# citizen_science

A Flutter web application for citizen scientists and researchers to record, view, and manage flower sightings. The app is designed as a Progressive Web App with offline caching support, enabling field work without a reliable internet connection.

## Role in Architecture

This service provides the user interface for the platform. It renders interactive maps, handles photo capture, manages authentication state, and communicates with the backend through a reverse proxy. The compiled Flutter assets are served by nginx.

## Responsibilities

- User registration, login, and password management
- Capturing or selecting photos for new sightings
- Recording geolocation via device GPS
- Displaying sightings on an interactive map with marker clustering
- Caching data offline using IndexedDB
- Allowing researchers to select and manage AI models
- Supporting multiple languages (Italian, English)

## Service Dependencies

| Service | Purpose |
|---------|---------|
| backend | All data operations are routed through the backend REST API |

The frontend does not communicate with the database or AI services directly. All requests go through nginx to `/api/`, which proxies to the backend container.

## Run Locally

### With Docker

From the repository root:

```bash
docker compose up frontend
```

The app is available at `http://localhost:8081`.

### Without Docker

Ensure Flutter 3.10+ is installed. From the `citizen_science` directory:

```bash
flutter pub get
flutter run -d chrome
```

By default the app expects the backend at `http://localhost:8080`. Adjust API URLs in the code if your backend runs elsewhere.

## Environment Variables

The frontend does not require environment variables at runtime. Build-time configuration (API base URL) is handled in the Dart code. If deploying to a different domain, update the nginx proxy configuration or Flutter constants accordingly.

## Exposed Ports

- **80** (inside container) mapped to **8081** on the host

## Build

Build the Flutter web release:

```bash
flutter build web --release
```

Output is placed in `build/web/`. The Dockerfile copies this into an nginx image.

Build the Docker image:

```bash
docker build -t citizen-science-frontend .
```

The Dockerfile uses a two-stage build:

1. The Flutter SDK compiles the application.
2. The `nginx:alpine` image serves the static files.

## Developer Notes

- State management uses the Provider package. Key providers include `ThemeProvider`, `AppStateProvider`, and `LocaleProvider`.
- Localization strings are defined in `lib/l10n/`. The app supports Italian and English.
- Offline storage leverages `idb_shim` for IndexedDB. See `lib/services/offline_storage_service_web.dart`.
- Maps are rendered with `flutter_map` and OpenStreetMap tiles. Marker clustering is provided by `flutter_map_marker_cluster`.
- JWT tokens are decoded client-side using `jwt_decoder` to extract user information.
- Photos are captured or selected via `image_picker`.

## Main Screens

| Screen | Description |
|--------|-------------|
| `SplashScreen` | Initial loading and authentication check |
| `LoginScreen` | User login form |
| `RegistrationScreen` | New user registration |
| `MainLayoutScreen` | Bottom navigation host |
| `MapScreen` | Interactive map with clustered sighting markers |
| `CollectionScreen` | List of user's own sightings |
| `CreateSightingScreen` | Form to submit a new sighting with photo |
| `SightingDetailScreen` | View and edit a single sighting |
| `SettingsScreen` | Theme, language, and account settings |
| `ChangePasswordScreen` | Password change form |
| `AiModelSelectionScreen` | Researcher-only screen to select AI models |

## Request Flow

1. User navigates to `CreateSightingScreen` and takes a photo.
2. The device's GPS provides coordinates via `geolocator`.
3. The user submits the form, which triggers an HTTP multipart POST to `/api/sightings`.
4. The backend processes the image and returns a response containing the AI-predicted flower species.
5. The sighting appears on the map and in the user's collection.
6. If offline, the sighting is queued in IndexedDB and synced when connectivity is restored.
