"""
AI Flower Identification Service.

This FastAPI application provides endpoints for identifying flowers from photos
and managing AI models. It serves as the AI microservice for EcoFlora, an application built for citizen science.
"""

from fastapi import FastAPI, File, UploadFile, Form
from fastapi.responses import JSONResponse
import logging
import os
import re
import torch
import torch.nn as nn
from torchvision import models, transforms
from PIL import Image
import io
import json

logger = logging.getLogger(__name__)

app = FastAPI(title="AI Flower Identification Service")

PLACEHOLDER_FLOWER_NAME = "Fiore Sconosciuto"
MODELS_DIR = "./AiModels"

# Cache for loaded models to avoid reloading
model_cache = {}


def load_device():
    """
    Load the appropriate device (CUDA or CPU).
    Automatically selects CUDA if available, otherwise falls back to CPU.
    
    Returns:
        torch.device: The device to use for inference.
    """
    if torch.cuda.is_available():
        device = torch.device('cuda')
        print(f"Using CUDA device: {torch.cuda.get_device_name(0)}")
    else:
        device = torch.device('cpu')
        print("CUDA not available, using CPU")
    return device


def get_available_models():
    """Get list of available .pt model files in AiModels directory."""
    if not os.path.exists(MODELS_DIR):
        return []
    return [f for f in os.listdir(MODELS_DIR) if f.endswith(".pt")]


def _validate_model_name(model_name: str) -> None:
    """
    Validate a model name to prevent path traversal attacks.

    Only filenames matching the pattern '<name>.pt' with alphanumeric,
    underscore, or hyphen characters are accepted. The resolved path is
    also checked to ensure it stays within MODELS_DIR.

    Raises:
        ValueError: If the model name is invalid or resolves outside MODELS_DIR.
    """
    if not re.match(r'^[a-zA-Z0-9_\-]+\.pt$', model_name):
        raise ValueError("Invalid model name")
    models_dir_real = os.path.realpath(os.path.abspath(MODELS_DIR))
    model_path_real = os.path.realpath(os.path.abspath(os.path.join(MODELS_DIR, model_name)))
    if os.path.commonpath([models_dir_real, model_path_real]) != models_dir_real:
        raise ValueError("Invalid model path")


def load_class_mapping(model_name):
    """
    Load class index to name mapping from JSON file.
    JSON file should have the same name as the .pt file.
    Format: {"0": "Class Name 0", "1": "Class Name 1", ...}
    Uses 0-based indexing to match PyTorch output.
    Non-integer keys (e.g. "description") are silently ignored.
    """
    _validate_model_name(model_name)
    json_path = os.path.join(MODELS_DIR, os.path.splitext(model_name)[0] + '.json')
    if not os.path.exists(json_path):
        return None

    with open(json_path, 'r', encoding='utf-8') as f:
        mapping = json.load(f)
    
    # Convert string keys to integers (0-based indexing); skip non-integer keys
    result = {}
    for k, v in mapping.items():
        try:
            result[int(k)] = v
        except (ValueError, TypeError):
            pass
    return result


def load_model(model_name):
    """
    Load a ResNet18 model from .pt file.
    Automatically uses CUDA if available, otherwise CPU.
    Returns tuple of (model, class_mapping, num_classes, device)
    """
    # Check cache first
    if model_name in model_cache:
        return model_cache[model_name]

    # Validate model name to prevent path traversal
    _validate_model_name(model_name)

    # Load device (automatic selection)
    device = load_device()

    # Construct full path to model file
    model_path = os.path.join(MODELS_DIR, model_name)

    if not os.path.exists(model_path):
        raise FileNotFoundError(f"Model file not found: {model_path}")

    # Load class mapping
    class_mapping = load_class_mapping(model_name)
    if class_mapping is None:
        raise FileNotFoundError(f"Class mapping JSON not found for model: {model_name}")

    num_classes = len(class_mapping)

    # Initialize ResNet18 model
    model = models.resnet18()
    model.fc = nn.Linear(model.fc.in_features, num_classes)

    # Load weights - handle both direct state_dict and checkpoint dict formats
    checkpoint = torch.load(model_path, map_location=device, weights_only=True)
    if isinstance(checkpoint, dict) and 'model' in checkpoint:
        model.load_state_dict(checkpoint['model'])
    else:
        model.load_state_dict(checkpoint)
    
    # Move model to device
    model.to(device)
    
    # Set to evaluation mode
    model.eval()
    
    # Cache the model
    model_cache[model_name] = (model, class_mapping, num_classes, device)
    
    return model, class_mapping, num_classes, device


def get_transforms():
    """
    Get image preprocessing transforms for ResNet18.
    Uses custom mean and std values for the specific dataset.
    Image size: 256x512 (width x height)
    """
    return transforms.Compose([
        transforms.Resize((512, 256)),  # height x width
        transforms.ToTensor(),
        transforms.Normalize(
            mean=[0.5099895000457764, 0.5119377970695496, 0.3384477198123932],
            std=[0.21787366271018982, 0.23693887889385223, 0.2062586098909378]
        )
    ])


def predict_image(image_bytes, model_name):
    """
    Predict flower class from image bytes using specified model.
    Automatically uses CUDA if available.
    Returns tuple of (predicted_class_name, confidence)
    """
    # Load model (device selection is automatic)
    model, class_mapping, num_classes, device = load_model(model_name)
    
    # Load and preprocess image
    image = Image.open(io.BytesIO(image_bytes)).convert('RGB')
    transform = get_transforms()
    image_tensor = transform(image).unsqueeze(0)  # Add batch dimension
    
    # Move image to device
    image_tensor = image_tensor.to(device)
    
    # Perform inference
    model.eval()
    with torch.no_grad():
        outputs = model(image_tensor)
        probabilities = torch.nn.functional.softmax(outputs, dim=1)
        confidence, predicted = torch.max(probabilities, 1)
    
    # Map index to class name (0-based indexing)
    predicted_index = predicted.item()
    predicted_class = class_mapping.get(predicted_index, "Unknown")
    confidence_score = confidence.item()
    
    return predicted_class, confidence_score


@app.get("/")
def read_root():
    """
    Root endpoint for health check.

    Returns:
        dict: Simple status message indicating the service is running.
    """
    return {"message": "AI Flower Identification Service is running"}


@app.post("/identify")
async def identify_flower(photo: UploadFile = File(...), model_name: str = Form(None)):
    """
    Identify a flower from an uploaded photo using ResNet18 model.

    This endpoint receives an image file and an optional model name.
    If no model is specified, it uses the first available model in the AiModels directory.
    Device selection (CUDA/CPU) is handled automatically.

    Args:
        photo: The uploaded image file.
        model_name: Optional name of the .pt model file to use.

    Returns:
        dict: A dictionary containing:
            - flower_name (str): The identified flower species.
            - confidence (float): Confidence score between 0 and 1.
            - model_used (str): The name of the model that was used.
            - device_used (str): The device used for inference (cuda or cpu).

    Raises:
        400: If the uploaded file is not an image.
        404: If the specified model is not found.
        500: If there's an error during model loading or inference.
    """
    if not photo.content_type or not photo.content_type.startswith("image/"):
        return JSONResponse(
            status_code=400,
            content={"error": "File must be an image"}
        )

    try:
        # Get available models
        available_models = get_available_models()
        
        if not available_models:
            return JSONResponse(
                status_code=500,
                content={"error": "No models available in AiModels directory"}
            )
        
        # Determine which model to use
        if model_name and model_name not in available_models:
            # Return error if explicitly requested model is not found
            return JSONResponse(
                status_code=404,
                content={"error": f"Model '{model_name}' not found. Available models: {available_models}"}
            )
        
        if not model_name:
            # Use first available model if none specified
            model_name = available_models[0]
        
        # Read image bytes
        image_bytes = await photo.read()
        
        # Perform prediction (device selection is automatic)
        predicted_class, confidence = predict_image(image_bytes, model_name)
        
        # Get device info from cache
        _, _, _, device = model_cache[model_name]
        
        return {
            "flower_name": predicted_class,
            "confidence": float(confidence),
            "model_used": model_name,
        }
        
    except Exception:
        logger.exception("Error during inference")
        return JSONResponse(
            status_code=500,
            content={"error": "An internal error occurred during inference"}
        )


@app.get("/models")
def list_models():
    """
    List all available AI models with their descriptions.

    Scans the AiModels directory for PyTorch model files (.pt) and reads
    the optional description from the corresponding JSON mapping file.

    Returns:
        dict: A dictionary containing:
            - models (list): List of objects with:
                - name (str): Model file name (with .pt extension).
                - description (str | null): Human-readable description if available.

    Raises:
        500: If there's an error reading the models directory.
    """
    models_dir = "./AiModels"

    if not os.path.exists(models_dir):
        return {"models": []}

    try:
        model_files = [
            f for f in os.listdir(models_dir)
            if f.endswith(".pt")
        ]
        result = []
        for model_file in model_files:
            description = None
            json_path = os.path.join(models_dir, os.path.splitext(model_file)[0] + '.json')
            if os.path.exists(json_path):
                with open(json_path, 'r', encoding='utf-8') as f:
                    data = json.load(f)
                    description = data.get('description')
            result.append({"name": model_file, "description": description})
        return {"models": result}
    except Exception:
        logger.exception("Error reading models directory")
        return JSONResponse(
            status_code=500,
            content={"error": "An internal error occurred while reading the models directory"}
        )


@app.get("/health")
def health_check():
    """
    Health check endpoint.

    Returns the health status of the service for monitoring and orchestration tools.

    Returns:
        dict: A dictionary with the service health status.
    """
    return {
        "status": "healthy"
    }


@app.post("/clear_cache")
def clear_model_cache():
    """
    Clear the model cache.
    
    Useful for freeing up memory or forcing a model reload.
    
    Returns:
        dict: Confirmation message with number of models removed from cache.
    """
    global model_cache
    cache_size = len(model_cache)
    model_cache.clear()
    
    # Force garbage collection to free GPU memory if CUDA is available
    if torch.cuda.is_available():
        torch.cuda.empty_cache()
    
    return {
        "message": f"Cache cleared. {cache_size} model(s) removed from cache.",
        "cuda_memory_freed": torch.cuda.is_available()
    }
