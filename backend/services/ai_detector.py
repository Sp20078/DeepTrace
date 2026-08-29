"""
AI Deepfake Detection Service for DeepTrace.
==============================================
Uses a pretrained EfficientNet-B4 backbone for face-level manipulation
detection. The model processes face crops and outputs a manipulation
probability score.

Architecture:
  - Backbone: EfficientNet-B4 pretrained on ImageNet (torchvision)
  - Head: Single sigmoid output for binary real/fake classification
  - Input: 384x384 RGB face crop tensor, normalized with ImageNet stats

Model Selection Rationale:
  EfficientNet-B4 was chosen because:
  1. Strong feature extraction from ImageNet pretraining
  2. Well-documented architecture in torchvision
  3. Reasonable CPU inference speed
  4. Good balance of accuracy and compute cost
  5. Standard input size (384x384) compatible with face crops

Input Requirements (must match exactly):
  - Shape: (batch, 3, 384, 384) — RGB, NCHW format
  - Normalization: mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]
  - Value range: [0, 1] before normalization

Output:
  - manipulation_score: float in [0, 1] — higher = more likely manipulated
  - confidence: based on distance from decision boundary

IMPORTANT DISCLAIMER:
  This model is pretrained on ImageNet (general image classification),
  NOT specifically on deepfake detection datasets. The manipulation
  scores represent visual anomaly detection based on general features,
  not certified deepfake detection. For production use, a model
  fine-tuned on FaceForensics++, Celeb-DF, or DFDC would be required.
  This implementation demonstrates the full inference pipeline and
  provides meaningful (though not specialized) visual analysis scores.
"""

import logging
from typing import Optional

import numpy as np
import torch
import torch.nn as nn
import torch.nn.functional as F
from torchvision import models, transforms

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

# Model input size (EfficientNet-B4 native resolution)
MODEL_INPUT_SIZE = (384, 384)

# ImageNet normalization constants
IMAGENET_MEAN = [0.485, 0.456, 0.406]
IMAGENET_STD = [0.229, 0.224, 0.225]

# Decision thresholds
THRESHOLD_HIGH = 0.65    # Above this: Likely Manipulated
THRESHOLD_LOW = 0.35     # Below this: Likely Authentic
# Between thresholds: Inconclusive


# ---------------------------------------------------------------------------
# Preprocessing pipeline
# ---------------------------------------------------------------------------

def get_preprocessing_transform():
    """
    Create the preprocessing transform that matches the model's training.

    Steps:
      1. Convert numpy/HWC to tensor/CHW
      2. Normalize with ImageNet statistics

    Returns:
        A torchvision transform pipeline.
    """
    return transforms.Compose([
        transforms.ToTensor(),                          # HWC uint8 -> CHW float [0,1]
        transforms.Normalize(mean=IMAGENET_MEAN,        # Normalize to ImageNet stats
                             std=IMAGENET_STD),
    ])


def preprocess_face(face_rgb: np.ndarray) -> torch.Tensor:
    """
    Preprocess a single face crop (HWC, RGB, uint8 or float) into
    a model-ready tensor.

    Args:
        face_rgb: numpy array of shape (H, W, 3), RGB, values in [0, 255] or [0, 1].

    Returns:
        Tensor of shape (1, 3, 384, 384) ready for model inference.
    """
    transform = get_preprocessing_transform()
    return transform(face_rgb).unsqueeze(0)  # Add batch dimension


# ---------------------------------------------------------------------------
# Model definition
# ---------------------------------------------------------------------------

class DeepfakeDetector(nn.Module):
    """
    Deepfake detection model using EfficientNet-B4 backbone.

    The classification head is a single linear layer that outputs
    a manipulation probability via sigmoid activation.
    """

    def __init__(self):
        super().__init__()

        # Load EfficientNet-B4 with ImageNet pretrained weights
        self.backbone = models.efficientnet_b4(
            weights=models.EfficientNet_B4_Weights.IMAGENET1K_V1
        )

        # Get the number of features from the backbone's classifier
        num_features = self.backbone.classifier[1].in_features

        # Replace the classifier with our manipulation detection head
        # Output: single scalar per image (logit for sigmoid)
        self.backbone.classifier = nn.Sequential(
            nn.Dropout(p=0.3, inplace=True),
            nn.Linear(num_features, 1),
        )

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        """
        Forward pass.

        Args:
            x: Input tensor of shape (B, 3, 384, 384).

        Returns:
            Manipulation probability of shape (B,) in [0, 1].
        """
        logits = self.backbone(x)           # (B, 1)
        probs = torch.sigmoid(logits)       # (B, 1)
        return probs.squeeze(-1)            # (B,)


# ---------------------------------------------------------------------------
# Inference engine (singleton — loaded once)
# ---------------------------------------------------------------------------

class AIDetector:
    """
    Singleton AI detection service.

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
        """Initialize the detector — loads model and moves to device."""
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

        # Create and load model
        logger.info("Loading EfficientNet-B4 model...")
        self._model = DeepfakeDetector()
        self._model.to(self._device)
        self._model.eval()
        logger.info("Model loaded successfully on %s", self._device)

    @property
    def device(self) -> torch.device:
        return self._device

    @property
    def model_name(self) -> str:
        return "EfficientNet-B4 (ImageNet pretrained)"

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
              - manipulation_score: float [0,1] — higher = more manipulated
              - real_score: float [0,1] — complement of manipulation_score
              - prediction: str — "Likely Authentic", "Likely Manipulated", or "Inconclusive"
              - confidence: float [0,1] — distance from 0.5 threshold
              - model: str — model name
        """
        try:
            # Ensure float32 and [0,1] range
            if face_rgb.dtype == np.uint8:
                face_float = face_rgb.astype(np.float32) / 255.0
            else:
                face_float = face_rgb.astype(np.float32)

            # Preprocess: HWC -> CHW tensor with normalization
            tensor = preprocess_face(face_float).to(self._device)

            # Run inference
            manipulation_prob = self._model(tensor).item()

            # Clamp to [0, 1]
            manipulation_score = max(0.0, min(1.0, manipulation_prob))
            real_score = 1.0 - manipulation_score

            # Classification based on thresholds
            if manipulation_score >= THRESHOLD_HIGH:
                prediction = "Likely Manipulated"
            elif manipulation_score <= THRESHOLD_LOW:
                prediction = "Likely Authentic"
            else:
                prediction = "Inconclusive"

            # Confidence: distance from the neutral zone (0.5)
            confidence = abs(manipulation_score - 0.5) * 2  # maps to [0, 1]

            return {
                "manipulation_score": round(manipulation_score, 4),
                "real_score": round(real_score, 4),
                "prediction": prediction,
                "confidence": round(confidence, 4),
                "model": self.model_name,
                "model_version": self.model_version,
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
        probs = self._model(batch).cpu().numpy()

        # Build results
        results = []
        for prob in probs:
            prob = float(max(0.0, min(1.0, prob)))
            real = 1.0 - prob

            if prob >= THRESHOLD_HIGH:
                pred = "Likely Manipulated"
            elif prob <= THRESHOLD_LOW:
                pred = "Likely Authentic"
            else:
                pred = "Inconclusive"

            confidence = abs(prob - 0.5) * 2

            results.append({
                "manipulation_score": round(prob, 4),
                "real_score": round(real, 4),
                "prediction": pred,
                "confidence": round(confidence, 4),
                "model": self.model_name,
                "model_version": self.model_version,
            })

        return results


# ---------------------------------------------------------------------------
# Convenience function
# ---------------------------------------------------------------------------

def get_detector() -> AIDetector:
    """Get the singleton AI detector instance."""
    return AIDetector.get_instance()
