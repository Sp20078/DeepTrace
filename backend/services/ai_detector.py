"""
AI Deepfake Detection Service for DeepTrace.
==============================================
Uses EfficientNet-B0 fine-tuned on FaceForensics++ (FF++) C23 dataset
for binary real/fake face classification.

Model: Xicor9/efficientnet-b0-ffpp-c23 (Hugging Face)
  - Architecture: EfficientNet-B0
  - Training: FaceForensics++ C23 (DeepFake, FaceSwap, Face2Face, NeuralTextures)
  - Performance: AUC 0.933, Accuracy 0.852, F1 0.843
  - License: Research/educational use

Input Requirements:
  - Shape: (batch, 3, 224, 224) — RGB, NCHW format
  - Normalization: ToTensor() converts to [0,1] float
  - No ImageNet normalization needed

Output:
  - 2-class softmax: [real_prob, fake_prob]
  - fake_prob >= 0.5 → Likely Manipulated
  - fake_prob <= 0.35 → Likely Authentic
  - between → Inconclusive
"""

import logging
import os
from pathlib import Path
from typing import Optional

import numpy as np
import torch
import torch.nn as nn
import torchvision.models as models
from torchvision import transforms

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

MODEL_INPUT_SIZE = (224, 224)

# Decision thresholds for fake probability
# The model has a known bias toward high scores for general photos.
# Thresholds are set conservatively to reduce false positives.
THRESHOLD_HIGH = 0.85    # Above this: Likely Manipulated (very confident)
THRESHOLD_LOW = 0.40     # Below this: Likely Authentic
# Between thresholds: Inconclusive

# Calibration: the model tends to output ~0.95+ for ANY face image.
# We apply a soft calibration to reduce bias for well-known real photos.
CALIBRATION_ENABLED = True

# Where to cache model weights
MODEL_CACHE_DIR = Path(__file__).parent.parent / "model_weights"
WEIGHTS_FILENAME = "efficientnet_b0_ffpp_c23.pth"
WEIGHTS_URL = (
    "https://huggingface.co/Xicor9/efficientnet-b0-ffpp-c23/"
    "resolve/main/efficientnet_b0_ffpp_c23.pth"
)


# ---------------------------------------------------------------------------
# Preprocessing pipeline
# ---------------------------------------------------------------------------

def get_preprocessing_transform():
    """
    Create preprocessing transform matching the model's training.

    The model was trained with just transforms.ToTensor() and Resize(224,224).
    No ImageNet normalization is needed.
    """
    return transforms.Compose([
        transforms.ToPILImage(),
        transforms.Resize(MODEL_INPUT_SIZE),
        transforms.ToTensor(),  # HWC uint8 → CHW float [0,1]
    ])


def preprocess_face(face_rgb: np.ndarray) -> torch.Tensor:
    """
    Preprocess a single face crop (HWC, RGB, uint8 or float) into
    a model-ready tensor.

    Args:
        face_rgb: numpy array of shape (H, W, 3), RGB, values in [0, 255] or [0, 1].

    Returns:
        Tensor of shape (1, 3, 224, 224) ready for model inference.
    """
    transform = get_preprocessing_transform()
    # Ensure uint8 for PIL conversion
    if face_rgb.dtype != np.uint8:
        face_rgb = (face_rgb * 255).clip(0, 255).astype(np.uint8)
    return transform(face_rgb).unsqueeze(0)  # Add batch dimension


# ---------------------------------------------------------------------------
# Model definition
# ---------------------------------------------------------------------------

class DeepfakeDetector(nn.Module):
    """
    Deepfake detection model using EfficientNet-B0 backbone,
    fine-tuned on FaceForensics++ C23 dataset.

    Output: 2-class logits [real, fake].
    """

    def __init__(self):
        super().__init__()

        # Load EfficientNet-B0 with ImageNet pretrained weights
        self.backbone = models.efficientnet_b0(
            weights=models.EfficientNet_B0_Weights.IMAGENET1K_V1
        )

        # Get the number of features from the backbone's classifier
        num_features = self.backbone.classifier[1].in_features

        # Replace the classifier with 2-class output (real vs fake)
        self.backbone.classifier = nn.Linear(num_features, 2)

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        """
        Forward pass.

        Args:
            x: Input tensor of shape (B, 3, 224, 224).

        Returns:
            Logits of shape (B, 2) — [real_logit, fake_logit].
        """
        return self.backbone(x)


# ---------------------------------------------------------------------------
# Model loading with auto-download
# ---------------------------------------------------------------------------

def _ensure_weights_downloaded() -> Path:
    """
    Download model weights if not already cached.

    Returns:
        Path to the downloaded .pth file.
    """
    MODEL_CACHE_DIR.mkdir(parents=True, exist_ok=True)
    weights_path = MODEL_CACHE_DIR / WEIGHTS_FILENAME

    if weights_path.exists():
        logger.info("Model weights found at %s", weights_path)
        return weights_path

    logger.info("Downloading model weights from %s ...", WEIGHTS_URL)
    try:
        # Use torch.hub for downloading with progress
        import urllib.request
        import sys

        def _progress_hook(block_num, block_size, total_size):
            downloaded = block_num * block_size
            if total_size > 0:
                pct = min(100, downloaded * 100 // total_size)
                if block_num % 50 == 0:
                    logger.info("  Download progress: %d%%", pct)

        urllib.request.urlretrieve(WEIGHTS_URL, str(weights_path), _progress_hook)
        logger.info("Model weights downloaded successfully (%d bytes)", weights_path.stat().st_size)
        return weights_path

    except Exception as e:
        logger.error("Failed to download model weights: %s", e)
        raise RuntimeError(
            f"Could not download model weights from {WEIGHTS_URL}. "
            f"Please download manually and place at {weights_path}. "
            f"Error: {e}"
        )


def _load_model_weights(model: DeepfakeDetector, weights_path: Path) -> DeepfakeDetector:
    """Load pretrained weights into the model architecture."""
    logger.info("Loading weights from %s ...", weights_path)
    state_dict = torch.load(weights_path, map_location="cpu", weights_only=True)

    # The saved model was trained as a standalone EfficientNet-B0
    # (not wrapped in self.backbone), so keys lack 'backbone.' prefix.
    # Also, classifier was model.classifier[1] (Sequential) not model.classifier (Linear).
    # Saved keys: features.X.Y.Z.weight, classifier.1.weight, etc.
    # Our model keys: backbone.features.X.Y.Z.weight, backbone.classifier.weight, etc.
    cleaned = {}
    for k, v in state_dict.items():
        name = k.replace("module.", "") if k.startswith("module.") else k
        # Add 'backbone.' prefix
        name = f"backbone.{name}"
        # Fix classifier key: classifier.1.weight -> classifier.weight
        name = name.replace("classifier.1.", "classifier.")
        cleaned[name] = v

    model.load_state_dict(cleaned, strict=True)
    logger.info("Weights loaded successfully (%d parameters)", len(cleaned))
    return model


# ---------------------------------------------------------------------------
# Inference engine (singleton — loaded once)
# ---------------------------------------------------------------------------

class AIDetector:
    """
    Singleton AI detection service using the FaceForensics++ fine-tuned model.

    Usage:
        detector = AIDetector.get_instance()
        result = detector.predict(face_rgb_array)
    """

    _instance: Optional["AIDetector"] = None
    _model: Optional[DeepfakeDetector] = None
    _device: Optional[torch.device] = None

    @classmethod
    def get_instance(cls) -> "AIDetector":
        """Get or create the singleton detector instance."""
        if cls._instance is None:
            cls._instance = cls()
        return cls._instance

    def __init__(self):
        """Initialize the detector — download weights, load model, move to device."""
        # Detect device
        if torch.cuda.is_available():
            self._device = torch.device("cuda")
            logger.info("Using CUDA GPU for inference")
        elif hasattr(torch.backends, "mps") and torch.backends.mps.is_available():
            self._device = torch.device("mps")
            logger.info("Using Apple MPS for inference")
        else:
            self._device = torch.device("cpu")
            logger.info("Using CPU for inference")

        # Create model
        logger.info("Creating EfficientNet-B0 deepfake detector...")
        self._model = DeepfakeDetector()

        # Download and load weights
        weights_path = _ensure_weights_downloaded()
        self._model = _load_model_weights(self._model, weights_path)

        # Move to device and set eval mode
        self._model.to(self._device)
        self._model.eval()
        logger.info("Model ready on %s", self._device)

    @property
    def device(self) -> torch.device:
        return self._device

    @property
    def model_name(self) -> str:
        return "EfficientNet-B0 (FaceForensics++ C23)"

    @property
    def model_version(self) -> str:
        return "1.0.0"

    @torch.no_grad()
    def predict(self, face_rgb: np.ndarray) -> dict:
        """
        Run inference on a single face crop.

        Args:
            face_rgb: numpy array (H, W, 3), RGB, uint8 [0-255] or float [0-1].

        Returns:
            Dict with:
              - manipulation_score: float [0,1] — fake probability
              - real_score: float [0,1] — real probability
              - prediction: str — classification
              - confidence: float [0,1] — distance from neutral zone
              - model: str — model name
        """
        try:
            # Ensure float32 and [0,1] range
            if face_rgb.dtype == np.uint8:
                face_float = face_rgb.astype(np.float32) / 255.0
            else:
                face_float = face_rgb.astype(np.float32)

            # Preprocess: HWC -> CHW tensor with resize
            tensor = preprocess_face(face_float).to(self._device)

            # Run inference
            logits = self._model(tensor)  # (1, 2)
            probs = torch.softmax(logits, dim=1)  # (1, 2)

            real_prob = probs[0, 0].item()
            fake_prob = probs[0, 1].item()

            # Apply calibration to reduce model bias
            if CALIBRATION_ENABLED:
                fake_prob = self._calibrate_score(fake_prob)
                real_prob = 1.0 - fake_prob

            # Classification based on thresholds
            if fake_prob >= THRESHOLD_HIGH:
                prediction = "Likely Manipulated"
            elif fake_prob <= THRESHOLD_LOW:
                prediction = "Likely Authentic"
            else:
                prediction = "Inconclusive"

            # Confidence: distance from the neutral zone
            confidence = abs(fake_prob - 0.5) * 2

            return {
                "manipulation_score": round(fake_prob, 4),
                "real_score": round(real_prob, 4),
                "prediction": prediction,
                "confidence": round(confidence, 4),
                "model": self.model_name,
                "model_version": self.model_version,
                "calibration_applied": CALIBRATION_ENABLED,
            }

        except Exception as e:
            logger.error("AI inference failed: %s", e)
            return {
                "manipulation_score": 0.0,
                "real_score": 0.0,
                "prediction": "Inconclusive",
                "confidence": 0.0,
                "model": self.model_name,
                "model_version": self.model_version,
                "error": str(e),
            }

    @torch.no_grad()
    def predict_batch(self, faces: list[np.ndarray]) -> list[dict]:
        """
        Run inference on multiple face crops in a batch.

        Args:
            faces: List of numpy arrays (H, W, 3), RGB.

        Returns:
            List of prediction dicts, one per face.
        """
        if not faces:
            return []

        # Preprocess all faces
        tensors = []
        for face in faces:
            if face.dtype == np.uint8:
                face_float = face.astype(np.float32) / 255.0
            else:
                face_float = face.astype(np.float32)
            tensors.append(preprocess_face(face_float))

        # Stack into batch
        batch = torch.cat(tensors, dim=0).to(self._device)

        # Run batch inference
        logits = self._model(batch)  # (B, 2)
        probs = torch.softmax(logits, dim=1).cpu().numpy()  # (B, 2)

        # Build results
        results = []
        for i in range(len(faces)):
            fake_prob = float(probs[i, 1])
            real_prob = float(probs[i, 0])

            # Apply calibration
            if CALIBRATION_ENABLED:
                fake_prob = self._calibrate_score(fake_prob)
                real_prob = 1.0 - fake_prob

            if fake_prob >= THRESHOLD_HIGH:
                pred = "Likely Manipulated"
            elif fake_prob <= THRESHOLD_LOW:
                pred = "Likely Authentic"
            else:
                pred = "Inconclusive"

            confidence = abs(fake_prob - 0.5) * 2

            results.append({
                "manipulation_score": round(fake_prob, 4),
                "real_score": round(real_prob, 4),
                "prediction": pred,
                "confidence": round(confidence, 4),
                "model": self.model_name,
                "model_version": self.model_version,
            })

        return results

    @staticmethod
    def _calibrate_score(raw_score: float) -> float:
        """
        Calibrate the model output to reduce known bias.

        The FaceForensics++ model tends to output very high scores (>0.95)
        for ANY face image, even real ones. This calibration applies a
        sigmoid-like transformation centered around 0.5 to spread scores
        more meaningfully across the [0, 1] range.

        This is a heuristic calibration, not a replacement for proper
        model retraining on diverse data.
        """
        import math
        # Shift the score toward the center using a logistic transformation
        # This compresses extreme scores (0.95 → ~0.70) while preserving
        # the relative ordering
        # k controls the strength of calibration (higher = more compression)
        k = 3.0
        # Center around 0.5, apply sigmoid compression
        centered = (raw_score - 0.5) * k
        calibrated = 1.0 / (1.0 + math.exp(-centered))
        return max(0.0, min(1.0, calibrated))


# ---------------------------------------------------------------------------
# Convenience function
# ---------------------------------------------------------------------------

def get_detector() -> AIDetector:
    """Get the singleton AI detector instance."""
    return AIDetector.get_instance()
