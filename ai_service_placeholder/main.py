"""
Placeholder AI Flower Identification Service.

This FastAPI application is a placeholder for testing multi-container scanning.
It exposes the same endpoints as ai_service (/models and /identify) but returns
hardcoded placeholder values instead of performing real inference.
"""

from fastapi import FastAPI, File, UploadFile, Form
from fastapi.responses import JSONResponse

app = FastAPI(title="Placeholder AI Flower Identification Service")

PLACEHOLDER_MODELS = [
    "placeholder_model_v1.pt",
    "placeholder_model_v2.pt",
]

PLACEHOLDER_FLOWER_NAMES = {
    "placeholder_model_v1.pt": "Rosa Canina (placeholder)",
    "placeholder_model_v2.pt": "Bellis Perennis (placeholder)",
}


@app.get("/")
def read_root():
    """
    Root endpoint for health check.

    Returns:
        dict: Simple status message indicating the service is running.
    """
    return {"message": "Placeholder AI Flower Identification Service is running"}


@app.get("/models")
def list_models():
    """
    List all available placeholder AI models.

    Returns:
        dict: A dictionary containing:
            - models (list): List of placeholder model file names.
    """
    return {"models": PLACEHOLDER_MODELS}


@app.post("/identify")
async def identify_flower(photo: UploadFile = File(...), model_name: str = Form(None)):
    """
    Identify a flower from an uploaded photo using a placeholder model.

    This endpoint accepts an image file and an optional model name, but always
    returns a hardcoded placeholder result without performing real inference.
    Used solely for testing multi-container scanning functionality.

    Args:
        photo: The uploaded image file.
        model_name: Optional name of the model to use.

    Returns:
        dict: A dictionary containing:
            - flower_name (str): A placeholder flower name string.
            - confidence (float): A fixed placeholder confidence score.
            - model_used (str): The name of the model that was used.
            - device_used (str): Always "cpu" for this placeholder service.

    Raises:
        400: If the uploaded file is not an image.
        404: If the specified model is not found in the placeholder list.
    """
    if not photo.content_type or not photo.content_type.startswith("image/"):
        return JSONResponse(
            status_code=400,
            content={"error": "File must be an image"}
        )

    if model_name and model_name not in PLACEHOLDER_MODELS:
        return JSONResponse(
            status_code=404,
            content={"error": f"Model '{model_name}' not found. Available models: {PLACEHOLDER_MODELS}"}
        )

    if not model_name:
        model_name = PLACEHOLDER_MODELS[0]

    flower_name = PLACEHOLDER_FLOWER_NAMES.get(model_name, "Fiore Sconosciuto (placeholder)")

    return {
        "flower_name": flower_name,
        "confidence": 0.99,
        "model_used": model_name,
        "device_used": "cpu",
    }


@app.get("/health")
def health_check():
    """
    Health check endpoint.

    Returns:
        dict: A dictionary with the service health status.
    """
    return {
        "status": "healthy",
        "cuda_available": False,
        "cuda_device": None,
        "device_in_use": "cpu",
    }
