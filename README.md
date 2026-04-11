# Citizen Science Platform

A multi-container application for recording and identifying wild flower sightings. Researchers and citizen scientists use the mobile-friendly web interface to photograph flowers in the field. Uploaded images are automatically classified by a machine learning service, and all observations are stored with geospatial metadata for later analysis.

## Architecture

The system consists of five services orchestrated via Docker Compose.
The frontend serves a Flutter web application through nginx. All API calls are reverse-proxied to the backend at `/api/`. The backend handles authentication, persists sightings to PostgreSQL (with PostGIS for spatial queries), and delegates flower identification to one or more AI containers. Multiple AI services can be configured to support different classification models.

### Startup Order

1. **postgres** starts first and exposes port 5432 inside the Docker network.
2. **ai_service** and **ai_service_placeholder** start in parallel. Each exposes a `/health` endpoint; the backend waits for both to report healthy.
3. **backend** starts once the database and AI services are ready. It connects to postgres via JDBC and queries AI containers over HTTP.
4. **frontend** can start immediately since it only proxies requests.

### Communication

- Frontend to backend: HTTP via nginx reverse proxy (`/api/` → `http://backend:8080/api/`)
- Backend to database: JDBC over TCP to `postgres:5432`
- Backend to AI services: HTTP calls to `http://<container_name>:8000`

### Shared Resources

- **postgres_data** volume: persists database files across restarts.
- **sighting_images** volume: stores uploaded photos on the backend.
- **ai_models** volume: holds trained PyTorch model weights for the AI service.

## Service Map

- **postgres** – PostgreSQL 16 with PostGIS extension for spatial queries.
- **backend** – Spring Boot REST API managing users, sightings, and AI model selection.
- **frontend** – Flutter web app served via nginx; provides the user interface.
- **ai_service** – FastAPI service running ResNet18 inference for flower classification.
- **ai_service_placeholder** – Lightweight mock of ai_service for testing multi-container scanning.

## Prerequisites

- Docker 20.10 or later
- Docker Compose v2
- At least 4 GB of available RAM (the AI service loads PyTorch models into memory)

Optional for local development without Docker:

- JDK 17+ and Maven 3.9+
- Python 3.11+
- Flutter 3.10+
- PostgreSQL 16 with PostGIS

## Quick Start

1. Clone the repository and enter the project root.

2. Copy the example environment file and configure secrets:

```bash
cp .env.example .env
```

Edit `.env` to set a secure `JWT_SECRET` and database password.

3. Build and start all services:

```bash
docker compose up --build
```

4. Open `http://localhost:8081` in a browser to access the frontend.

5. Register a new account or log in. Users with the "ricercatore" (researcher) role can manage AI models.

## Run Locally

### Running individual services

To iterate on the backend without rebuilding the container:

```bash
cd CitizenScienceBackend
./mvnw spring-boot:run
```

Ensure a local PostgreSQL instance is running and the environment variables are set.

For the frontend:

```bash
cd citizen_science
flutter run -d chrome
```

The Flutter app expects the backend at `http://localhost:8080`.

### Rebuilding a single container

```bash
docker compose build backend
docker compose up -d backend
```

### Viewing logs

```bash
docker compose logs -f backend
docker compose logs -f ai_service
```

## CI/CD and Code Quality

The repository includes multiple GitHub Actions workflows for backend validation and security checks.

| Workflow | File | Trigger | Purpose |
|----------|------|---------|---------|
| Backend Tests | `.github/workflows/backend-tests.yml` | push, pull_request, manual | Runs the backend test suite with Maven (`clean test`). |
| Backend Quality | `.github/workflows/backend-quality.yml` | push, pull_request, manual | Runs backend quality checks with Maven (`clean verify`). |
| CodeQL | `.github/workflows/codeql.yml` | push, pull_request, weekly schedule | Performs static security analysis for Java/Kotlin. |
| Dependency Review | `.github/workflows/dependency-review.yml` | pull_request | Checks dependency changes introduced by PRs. |

Dependency updates are also automated through Dependabot:

- `.github/dependabot.yml` opens periodic PRs for Maven dependencies (`CitizenScienceBackend`) and GitHub Actions versions.

### Recommended branch protection

To enforce quality gates before merge, enable branch protection on `main` and require these checks:

1. `Backend Tests / test-backend`
2. `Backend Quality / quality-backend`
3. `CodeQL / Analyze Java with CodeQL`
4. `Dependency Review / dependency-review`

## Local SonarQube (Optional)

SonarQube is configured for local, on-demand usage via a dedicated Docker Compose profile named `sonar`.
This keeps the default stack lightweight while allowing full local analysis when needed.

### Services and profile behavior

- `sonarqube-db` and `sonarqube` are marked with profile `sonar` in `docker-compose.yml`.
- They are not started by default when running `docker compose up`.

### Run without SonarQube (default)

```bash
docker compose up -d
```

### Run with SonarQube profile enabled

```bash
docker compose --profile sonar up -d
```

### Start only SonarQube services

```bash
docker compose --profile sonar up -d sonarqube-db sonarqube
```

### First-time SonarQube setup

1. Open `http://localhost:9000`.
2. Log in with default credentials (`admin` / `admin`) and change the password.
3. Create a local project (for example `CitizenScienceBackend`).
4. Generate a user token for local analysis.

### Run a local backend analysis (manual)

From the backend directory:

```bash
cd CitizenScienceBackend
./mvnw -B clean verify sonar:sonar -Dsonar.host.url=http://localhost:9000 -Dsonar.token=<YOUR_TOKEN> -Dsonar.projectKey=CitizenScienceBackend
```

On Windows PowerShell:

```powershell
cd CitizenScienceBackend
.\mvnw.cmd -B clean verify sonar:sonar -Dsonar.host.url=http://localhost:9000 -Dsonar.token=<YOUR_TOKEN> -Dsonar.projectKey=CitizenScienceBackend
```

This local SonarQube flow is intentionally separate from GitHub-hosted workflows, so CI quality checks do not depend on a machine running SonarQube.

## Environment Variables

These variables are read from `.env` by Docker Compose. Defaults are shown where applicable.

| Variable | Description |
|----------|-------------|
| `POSTGRES_DB` | Name of the PostgreSQL database (default: `citizenscience`) |
| `POSTGRES_USER` | Database username (default: `postgres`) |
| `POSTGRES_PASSWORD` | Database password (required) |
| `JWT_SECRET` | Secret key for signing JWT tokens (required, min 256 bits) |
| `JWT_EXPIRATION` | Token lifetime in milliseconds (default: `86400000`, 24 hours) |
| `ALLOWED_ORIGINS` | Comma-separated CORS origins |
| `AI_CONTAINERS` | Comma-separated Docker service names exposing `/models` and `/identify` endpoints |

## Networking / Ports

| Service | Internal Port | Exposed Port |
|---------|---------------|--------------|
| postgres | 5432 | 5433 |
| backend | 8080 | 8080 |
| frontend | 80 | 8081 |
| ai_service | 8000 | 8000 |
| ai_service_placeholder | 8000 | 8002 |

All services communicate over the default Docker Compose bridge network. The frontend nginx config proxies `/api/` requests to the backend container.

## Folder Structure

```
.
├── CitizenScienceBackend/   # Spring Boot backend
│   ├── src/
│   │   ├── main/java/com/citizenScience/
│   │   │   ├── controllers/   # REST endpoints
│   │   │   ├── services/      # Business logic
│   │   │   ├── entities/      # JPA entities
│   │   │   └── repositories/  # Data access
│   │   └── resources/
│   │       ├── application.properties
│   │       └── db/migration/  # Flyway scripts
│   ├── Dockerfile
│   └── pom.xml
├── citizen_science/         # Flutter frontend
│   ├── lib/
│   │   ├── screens/         # UI screens
│   │   ├── providers/       # State management
│   │   ├── services/        # HTTP + offline storage
│   │   └── widgets/
│   ├── nginx.conf
│   ├── Dockerfile
│   └── pubspec.yaml
├── ai_service/              # Python AI inference service
│   ├── main.py
│   ├── AiModels/            # Trained model weights + class mappings
│   ├── Dockerfile
│   └── requirements.txt
├── ai_service_placeholder/  # Mock AI service for testing
│   ├── main.py
│   ├── Dockerfile
│   └── requirements.txt
├── docker-compose.yml
└── .env.example
```

## Request Flow

1. A user opens the frontend and logs in. The Flutter app stores the JWT token.
2. The user takes a photo of a flower and submits a sighting with coordinates.
3. The frontend sends a multipart POST request to `/api/sightings` through nginx.
4. The backend saves the image to the `sighting_images` volume, then forwards the photo to the selected AI container's `/identify` endpoint.
5. The AI service returns a predicted flower species and confidence score.
6. The backend persists the sighting (with AI results) to PostgreSQL and responds to the frontend.
7. All sightings can be viewed on a map or filtered by user. Spatial queries use PostGIS.

## Operational Tasks

### Trigger a fresh AI model scan

Researchers can call `POST /api/ai/scan` to query all configured AI containers and update the model registry. This is useful after deploying a new model.

### Add a new AI model

Developers can add more docker containers to grant access to more AI models. To add a new container:

1. Ensure that it exposes at least the endpoints described in `ai_service_placeholder/openapi.yaml`.
2. Add the instructions for the build of the container to the `docker-compose.yml`.
3. Add the name of the service inside the `docker-compose.yml` to the field `AI_CONTAINERS` inside the `.env` file (separeted by comma).

To visualize the new AI models inside the application, you can either:
1. Stop all the currently running containers.
2. Build all the containers with the `docker-compose.yml`.
3. The backend will automatically read the list of the containers from the `.env` file and at the startup will call all the containers to gain information on their models.

Or you can:
1. Keep the currently running containers.
2. Manually update the `.env` file inside the `backend` container.
3. Manually add, build and run the new container inside the docker network.
4. Manually call the endpoint `POST /api/ai/scan/` with a researcher account to update the list of currently available models.
