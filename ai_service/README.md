# ai_service

A FastAPI microservice that performs flower species identification using a ResNet18 convolutional neural network. It loads trained PyTorch model weights and exposes REST endpoints for inference.

## Role in Architecture

This service handles the machine learning workload. When a user submits a sighting, the backend forwards the photo here for classification. The service returns the predicted species name and confidence score. Multiple instances or alternative model containers can be deployed to support different classification tasks.

## Responsibilities

- Loading and caching PyTorch models from the `AiModels` directory
- Preprocessing images to match the model's expected input format
- Running inference on uploaded photos
- Returning predicted class labels and confidence scores
- Exposing a list of available models for the backend to discover
- Providing health check endpoints for orchestration

## Service Dependencies

This service has no runtime dependencies on other containers. It operates independently and waits for HTTP requests from the backend.

## Run Locally

### With Docker

From the repository root:

```bash
docker compose up ai_service
```

### Without Docker

Create a virtual environment and install dependencies:

```bash
cd ai_service
python -m venv venv
source venv/bin/activate  # or venv\Scripts\activate on Windows
pip install -r requirements.txt
```

Run the server:

```bash
uvicorn main:app --host 0.0.0.0 --port 8000
```

Ensure the `AiModels` directory contains at least one `.pt` model file with a corresponding `.json` class mapping.

## Environment Variables

No environment variables are required. Model files are read from the `AiModels` directory.

## Exposed Ports

- **8000** – HTTP API

## Build

Build the Docker image:

```bash
docker build -t citizen-science-ai .
```

The image is based on `python:3.11.14-slim`. Model weights in `AiModels/` are copied into the image at build time; alternatively, mount the directory as a volume to swap models without rebuilding.

## Developer Notes

- Models must be PyTorch `.pt` files containing a state dict compatible with ResNet18.
- Each model requires a JSON file with the same base name. The JSON maps integer class indices to human-readable names. Example:

```json
{
  "0": "O. exaltata",
  "1": "O. garganica",
  "description": "Orchid species classifier"
}
```

- The `description` key is optional but displayed by the backend when listing models.
- Image preprocessing: images are resized to 512×256, converted to tensors, and normalized with dataset-specific mean and std values.
- The service automatically selects CUDA if available, otherwise falls back to CPU.
- Models are cached after the first load. Call `POST /clear_cache` to free memory and force a reload.

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/` | Root health check (returns status message) |
| GET | `/health` | Health status with CUDA availability info |
| GET | `/models` | List available models with descriptions |
| POST | `/identify` | Identify flower from uploaded image |
| POST | `/clear_cache` | Clear model cache and free GPU memory |

### POST /identify

**Request:** `multipart/form-data`

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `photo` | file | yes | Image file (JPEG, PNG, etc.) |
| `model_name` | string | no | Name of the `.pt` model file; defaults to first available |

**Response:**

```json
{
  "flower_name": "O. garganica",
  "confidence": 0.9123,
  "model_used": "model_full_internet_last.pt",
  "device_used": "cuda"
}
```

## Request Flow

1. The backend receives a sighting with a photo.
2. It calls `POST /identify` on this service, attaching the image and optionally a model name.
3. The service loads the requested model (or the first available one).
4. The image is preprocessed and passed through the network.
5. Softmax probabilities are computed; the class with the highest probability is returned along with its confidence score.
6. The backend stores the result and responds to the frontend.
