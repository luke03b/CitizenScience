# ai_service_placeholder

A lightweight FastAPI mock of the main AI service used by EcoFlora, an application built for citizen science. It exposes the same endpoints (`/models`, `/identify`, `/health`) but returns hardcoded placeholder values instead of running real inference. This container exists solely for testing multi-container AI scanning in development environments.

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

## API Endpoints Overview

This service implements three core endpoints that follow the OpenAPI 3.0.3 specification. All responses are in JSON format. Developers implementing a custom AI service should follow this contract to ensure compatibility with the rest of the application.

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/health` | Health check and compute device information |
| GET | `/models` | List available AI models |
| POST | `/identify` | Classify an image using a specified or default model |

---

### 1. GET /health

**Purpose:** Health check endpoint for orchestration tools and load-balancers to verify service readiness and availability.

**Request Parameters:** None

**Response Status Codes:**
- `200 OK` - Service is healthy and ready to serve requests

**Response Schema:**

```json
{
  "status": "healthy"
}
```

**Response Fields:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `status` | string | Yes | Current health status. Must be `"healthy"` when the service is operational and ready to accept requests. |

**Example Response:**

```json
{
  "status": "healthy"
}
```

**Implementation Notes:**
- This endpoint should respond quickly and be polled frequently by orchestration tools and load-balancers.
- Always return `"status": "healthy"` when the service is ready to serve requests.
- Return appropriate HTTP error codes (e.g., `503 Service Unavailable`) if the service is not ready.

---

### 2. GET /models

**Purpose:** List all AI models currently available in the service for inference tasks.

**Request Parameters:** None

**Response Status Codes:**
- `200 OK` - Models retrieved successfully
- `500 Internal Server Error` - Error reading the models directory

**Response Schema (Success):**

```json
{
  "models": [
    {
      "name": "classifier_v1",
      "description": "Version 1 of the image classifier"
    },
    {
      "name": "classifier_v2",
      "description": null
    }
  ]
}
```

**Response Fields:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `models` | array | Yes | Array of available model information objects. |
| `models[].name` | string | Yes | Unique identifier or file name of the model (e.g., `"model_v1.pt"`, `"efficientnet_b3"`). Used as the `model_name` parameter in `/identify` requests. |
| `models[].description` | string \| null | Yes | Human-readable description explaining what the model does, its training data, or version notes. Can be `null` if no description is available. |

**Error Response Schema (500):**

```json
{
  "error": "Error reading the models directory"
}
```

**Implementation Notes:**
- Models can be in any format (PyTorch `.pt`, TensorFlow `.pb`, ONNX, etc.).
- The model name must be unique within the service.
- Return an empty `models` array if no models are available.
- This endpoint is called by the backend during service discovery (`/api/ai/scan`). Each discovered model is stored for later use.

**Example Response:**

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

---

### 3. POST /identify

**Purpose:** Classify/identify an image using a specified AI model or the first available model.

**Request Format:** `multipart/form-data`

**Request Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `photo` | file (binary) | Yes | Image file to classify. Must be a valid image with MIME type starting with `image/*` (e.g., `image/jpeg`, `image/png`, `image/webp`). |
| `model_name` | string | No | Name of the model to use for inference. Must match one of the names returned by `GET /models`. If omitted or `null`, the service should use the first available model. |

**Example Request (cURL):**

```bash
# Using a specific model
curl -X POST \
  -F "photo=@flower.jpg" \
  -F "model_name=classifier_v1" \
  http://localhost:8000/identify

# Using the default (first available) model
curl -X POST \
  -F "photo=@flower.jpg" \
  http://localhost:8000/identify
```

**Response Status Codes:**

| Code | Description |
|------|-------------|
| `200 OK` | Image classified successfully |
| `400 Bad Request` | The uploaded file is not an image |
| `404 Not Found` | The requested model was not found |
| `500 Internal Server Error` | No models available or error during inference |

**Response Schema (Success - 200):**

```json
{
  "label": "example_class",
  "confidence": 0.9423,
  "model_used": "classifier_v1",
  "device_used": "cpu"
}
```

**Response Fields (Success):**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `label` | string | Yes | Predicted class label returned by the model (e.g., `"Rosa Canina"`, `"Daisy"`). This is the main classification result. |
| `confidence` | number (float) | Yes | Confidence score of the prediction. Must be between `0.0` and `1.0`, where `0.0` is lowest confidence and `1.0` is highest. |
| `model_used` | string | Yes | Identifier of the model that was actually used for inference (same as the `name` field from `GET /models`). |


**Error Response Schema (400):**

```json
{
  "error": "File must be an image"
}
```

**Error Response Schema (404):**

```json
{
  "error": "Model 'unknown_model' not found. Available models: ['classifier_v1']"
}
```

**Error Response Schema (500):**

```json
{
  "error": "No models available"
}
```

**Example Successful Response:**

```json
{
  "label": "Rosa Canina (placeholder)",
  "confidence": 0.99,
  "model_used": "placeholder_model_v1.pt"
}
```

**Implementation Notes:**
- Always validate that the uploaded file is a valid image before processing.
- If `model_name` is not provided, select the first model from the `GET /models` list.
- If `model_name` is provided but not found, return a `404` error with a helpful message listing available models.
- Ensure the confidence score is normalized to the range `[0.0, 1.0]`.

---

### Implementation Guide for Developers

When implementing a custom AI service that replaces this placeholder, ensure:

1. **All three endpoints are implemented** (`/health`, `/models`, `/identify`) with exact request/response schemas.
2. **Status codes are correct** - Use appropriate HTTP status codes as specified above.
3. **Model discovery** - The `GET /models` endpoint must return a list of available models; the backend uses this for service discovery.
4. **Image validation** - Reject non-image files with a `400` error.
5. **Model selection** - Default to the first model if `model_name` is not provided.
6. **Error messages** - Provide clear, actionable error messages in the `error` field.
7. **Confidence normalization** - Ensure confidence scores are floats between 0 and 1.
8. **Performance** - The `/health` endpoint should be fast and non-blocking; it is called frequently by load-balancers.

---

## Request Flow

1. The backend scans AI containers via `POST /api/ai/scan`.
2. This service responds to `GET /models` with hardcoded entries.
3. The backend persists these models in `ai_container_models`.
4. When a sighting is created with a placeholder model selected, the backend calls `POST /identify` here.
5. The service returns a fixed result without performing actual inference.

---

## Placeholder-Specific Implementation

This service is a minimal reference implementation. It demonstrates how to satisfy the API contract while using hardcoded behavior:

### Placeholder Behavior

| Endpoint | Behavior |
|----------|----------|
| **GET /health** | Always returns `status: "healthy"` |
| **GET /models** | Returns exactly two hardcoded models: `placeholder_model_v1.pt` and `placeholder_model_v2.pt` with test descriptions |
| **POST /identify** | Returns a deterministic flower name regardless of the input image. The flower name depends on the selected model. Confidence is always `0.99`, model_used reflects the model selected. |

**Note:** Developers implementing production AI services should replace the hardcoded values with actual model loading, real inference logic, and accurate device/confidence reporting while maintaining the same request/response schemas.
