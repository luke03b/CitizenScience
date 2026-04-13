# CitizenScienceBackend

The backend service for the Citizen Science platform. Built with Spring Boot 4, it exposes a REST API for user authentication, sighting management, and AI model orchestration.

## Role in Architecture

This service acts as the central coordinator. It authenticates users, persists data to PostgreSQL, stores uploaded images, and delegates flower identification to external AI containers. The frontend communicates exclusively with this service; it never talks directly to the database or AI services.

## Responsibilities

- User registration and authentication (JWT-based)
- CRUD operations for sightings, including photo uploads
- Geospatial queries via PostGIS
- Scanning and registering AI models from multiple containers
- Forwarding images to AI services for classification
- Managing per-user and system-wide default AI model selection

## Service Dependencies

| Service | Purpose |
|---------|---------|
| postgres | Primary data store (PostgreSQL 16 with PostGIS) |
| ai_service | Flower classification inference |
| ai_service_placeholder | Secondary AI container for testing multi-model support |

The backend waits for all three dependencies to report healthy before starting.

## Run Locally

### With Docker

From the repository root:

```bash
docker compose up backend
```

### Without Docker

Ensure PostgreSQL is running locally and the PostGIS extension is enabled. Create an `.env` file in the backend directory:

Then run:

```bash
./mvnw spring-boot:run
```

The application starts on port 8080 by default.

## Testing

The backend includes an automated test suite focused on:

- Spring context smoke checks
- Controller layer tests (including security-related behavior)
- Service and exception handling validation

### Run all tests

From `CitizenScienceBackend`:

```bash
./mvnw test
```

On Windows PowerShell:

```powershell
.\mvnw.cmd test
```

### Run a single test suite

```bash
./mvnw -Dtest=AuthControllerTest test
```

### Test suites and coverage

| Test suite | Brief description |
|------------|-------------------|
| `CitizenScienceBackendApplicationTests` | Spring Boot context load smoke test and core bean wiring validation. |
| `AuthControllerTest` | Authentication endpoints behavior (`register`, `login`, `change-password`) and request/response validation. |
| `UserControllerTest` | Current-user profile retrieval/update endpoints, including access control scenarios. |
| `SightingControllerTest` | Sighting API contract for creation, listing, filtering, updates, and deletion paths. |
| `AiModelControllerTest` | AI model endpoints for scan/list/select/default configuration, including role/authorization checks. |
| `AuthServiceTest` | Authentication business logic: registration, login, password change, and error handling. |
| `UserServiceTest` | User domain operations and validations (lookup/update and related failure cases). |
| `AvvistamentoServiceTest` | Sighting service logic: persistence, photo handling, filters, ownership checks, and update/delete flows. |
| `AiServiceTest` | AI container integration logic: model scan, selection fallback, and classification handling. |
| `JwtUtilTest` | JWT generation/parsing/validation (claims, expiration, malformed token scenarios). |
| `GlobalExceptionHandlerTest` | Mapping of backend exceptions to HTTP status codes and error payload structure. |

### Test reports

After execution, Maven Surefire reports are available in:

- `target/surefire-reports/`

This test suite is also executed in CI through `.github/workflows/backend-tests.yml` on push and pull request.

Additional backend quality checks run through `.github/workflows/backend-quality.yml`, which executes `./mvnw -B -ntp clean verify`.

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `SPRING_PROFILES_ACTIVE` | Active Spring profile (`docker` or none) | – |
| `SPRING_DATASOURCE_URL` | JDBC connection string | `jdbc:postgresql://localhost:5432/citizenscience` |
| `SPRING_DATASOURCE_USERNAME` | Database user | `postgres` |
| `SPRING_DATASOURCE_PASSWORD` | Database password | – |
| `JWT_SECRET` | Key for signing tokens | – |
| `JWT_EXPIRATION` | Token lifetime in milliseconds | `86400000` |
| `ALLOWED_ORIGINS` | CORS whitelist | `http://localhost:3000,http://localhost:8080` |
| `AI_CONTAINERS` | Comma-separated AI service names | `ai_service` |

## Exposed Ports

- **8080** – HTTP API

## Developer Notes

- The project uses Lombok for boilerplate reduction.
- Flyway manages database migrations. Scripts live in `src/main/resources/db/migration/`.
- Hibernate validates the schema on startup (`ddl-auto=validate`), so migrations must be applied first.
- The `spring-dotenv` library allows loading variables from a `.env` file during local development.
- OpenAPI documentation is available at `/swagger-ui.html` when the server is running.

## API Endpoints

### Authentication

| Method | Path | Description |
|--------|------|-------------|
| POST | `/api/auth/register` | Register a new user |
| POST | `/api/auth/login` | Authenticate and receive JWT |
| PUT | `/api/auth/change-password` | Change password (authenticated) |

### Users

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/users/me` | Get current user profile |
| PUT | `/api/users/me` | Update current user profile |

### Sightings

| Method | Path | Description |
|--------|------|-------------|
| POST | `/api/sightings` | Create sighting with photo (multipart) |
| GET | `/api/sightings` | List all sightings |
| GET | `/api/sightings/user/{userId}` | List sightings by user |
| GET | `/api/sightings/location?lat=&lng=&radiusKm=` | Spatial query |
| PUT | `/api/sightings/{id}/notes` | Update notes |
| DELETE | `/api/sightings/{id}` | Delete sighting |

### Photos

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/photos/{avvistamentoId}/{filename}` | Retrieve sighting photo |

### AI Models (Researcher only)

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/ai/models` | List registered AI models |
| POST | `/api/ai/scan` | Force scan all AI containers |
| POST | `/api/ai/models/select` | Select model for current user |
| GET | `/api/ai/models/selected` | Get current user's selected model |
| POST | `/api/ai/models/set-default` | Set system-wide default model |

## Request Flow

1. The frontend sends a `POST /api/sightings` request with a photo and coordinates.
2. `SightingController` delegates to `AvvistamentoService`.
3. The service saves the photo to `uploads/sightings/` and records metadata.
4. `AiService` is invoked to identify the flower. It reads the user's selected model (or the system default) and calls the corresponding AI container's `/identify` endpoint.
5. The AI container returns `{ flower_name, confidence, model_used }`.
6. The sighting record is updated with the AI result and persisted via JPA.
7. A response DTO is returned to the frontend.

## Database Schema (Flyway)

The initial migration (`V1__init_schema.sql`) creates:

- `users` – account data with roles (`utente`, `ricercatore`)
- `avvistamenti` – sightings with PostGIS geometry column
- `foto_avvistamenti` – photos linked to sightings
- `ai_model_selection` – per-user model preference
- `ai_container_models` – registry of models discovered from AI containers
