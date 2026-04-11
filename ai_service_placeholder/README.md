# ai_service_placeholder

A lightweight FastAPI mock of the main AI service. It exposes the same endpoints (`/models`, `/identify`, `/health`) but returns hardcoded placeholder values instead of running real inference. This container exists solely for testing multi-container AI scanning in development environments.

## Role in Architecture

During development and testing, it can be useful to verify that the backend correctly discovers and routes requests to multiple AI containers without deploying heavyweight models. This placeholder service fulfills that role. It allows developers to confirm that the scanning mechanism works and that the frontend can display models from more than one source.

## Responsibilities

- Exposing the same API surface as `ai_service`
- Returning fixed placeholder model names and descriptions
- Returning a deterministic flower name and confidence for any uploaded image
- Reporting healthy status to Docker health checks

## Service Dependencies

This service has no dependencies. It operates standalone and responds to HTTP requests from the backend.

## Run Locally

### With Docker

From the repository root:

```bash
docker compose up ai_service_placeholder
```

### Without Docker

```bash
cd ai_service_placeholder
python -m venv venv
source venv/bin/activate  # or venv\Scripts\activate on Windows
pip install -r requirements.txt
uvicorn main:app --host 0.0.0.0 --port 8000
```

## Environment Variables

None required.

## Exposed Ports

- **8000** (inside container) mapped to **8002** on the host

## Build

```bash
docker build -t citizen-science-ai-placeholder .
```

The image is based on `python:3.11.14-slim` and includes only FastAPI, Uvicorn, and `python-multipart`.

## Developer Notes

- The placeholder models are defined directly in `main.py`. No model files are needed.
- Any image upload to `/identify` returns one of two fixed flower names depending on the selected model.
- Confidence is always `0.99`.
- Device is always reported as `cpu`.

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/` | Root health check |
| GET | `/health` | Health status (always reports healthy) |
| GET | `/models` | Returns hardcoded placeholder models |
| POST | `/identify` | Returns a fixed flower name for any image |

### GET /models

```json
{
  "models": [
    {
      "name": "placeholder_model_v1.pt",
      "description": "Placeholder model version 1 for testing multi-container scanning."
    },
    {
      "name": "placeholder_model_v2.pt",
      "description": "Placeholder model version 2 for testing multi-container scanning."
    }
  ]
}
```

### POST /identify

**Request:** `multipart/form-data` with `photo` (required) and optional `model_name`.

**Response:**

```json
{
  "flower_name": "Rosa Canina (placeholder)",
  "confidence": 0.99,
  "model_used": "placeholder_model_v1.pt",
  "device_used": "cpu"
}
```

## Request Flow

1. The backend scans AI containers via `POST /api/ai/scan`.
2. This service responds to `GET /models` with hardcoded entries.
3. The backend persists these models in `ai_container_models`.
4. When a sighting is created with a placeholder model selected, the backend calls `POST /identify` here.
5. The service returns a fixed result without performing actual inference.
