"""
DeepTrace Model Service — Clean Rebuild
=========================================
Loads the trained EfficientNet-B2 and runs inference.
No hacks, no calibration workarounds — just clean model output.
"""

import logging
from pathlib import Path
from typing import Optional

import numpy as np
import torch
import torch.nn as nn
import torchvision.models as models
from torchvision import transforms

logger = logging.getLogger(__name__)

# ── Paths ──────────────────────────────────────────────────────────────────
WEIGHTS_DIR = Path(__file__).parent.parent / "model_weights"
BEST_WEIGHTS = WEIGHTS_DIR / "efficientnet_b2_deeptrace_best.pth"
FINAL_WEIGHTS = WEIGHTS_DIR / "efficientnet_b2_deeptrace_final.pth"
LEGACY_WEIGHTS = WEIGHTS_DIR / "efficientnet_b0_ffpp_c23.pth"
LEGACY_URL = (
    "https://huggingface.co/Xicor9/efficientnet-b0-ffpp-c23/"
    "resolve/main/efficientnet_b0_ffpp_c23.pth"
)

# ── Preprocessing ──────────────────────────────────────────────────────────
INPUT_SIZE = (224, 224)
IMAGENET_MEAN = [0.485, 0.456, 0.406]
IMAGENET_STD = [0.229, 0.224, 0.225]

_transform = transforms.Compose([
    transforms.ToPILImage(),
    transforms.Resize(INPUT_SIZE),
    transforms.ToTensor(),
    transforms.Normalize(mean=IMAGENET_MEAN, std=IMAGENET_STD),
])


def preprocess_face(face_rgb: np.ndarray) -> torch.Tensor:
    """Preprocess a face crop (HWC RGB uint8) → model-ready tensor."""
    if face_rgb.dtype != np.uint8:
        face_rgb = (face_rgb * 255).clip(0, 255).astype(np.uint8)
    return _transform(face_rgb).unsqueeze(0)


# ── Model Architecture ────────────────────────────────────────────────────
class DeepfakeClassifier(nn.Module):
    """EfficientNet-B2 binary classifier (real vs fake)."""

    def __init__(self):
        super().__init__()
        self.backbone = models.efficientnet_b2(weights=None)
        num_features = self.backbone.classifier[1].in_features
        self.backbone.classifier = nn.Sequential(
            nn.Dropout(p=0.3, inplace=True),
            nn.Linear(num_features, 256),
            nn.ReLU(inplace=True),
            nn.Dropout(p=0.2),
            nn.Linear(256, 2),
        )

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        return self.backbone(x)


# ── Inference Engine ───────────────────────────────────────────────────────
class DeepfakeModel:
    """Singleton model wrapper for inference."""

    _instance: Optional["DeepfakeModel"] = None
    _model: Optional[DeepfakeClassifier] = None
    _device: Optional[torch.device] = None

    @classmethod
    def get_instance(cls) -> "DeepfakeModel":
        if cls._instance is None:
            cls._instance = cls()
        return cls._instance

    def __init__(self):
        # Device
        if torch.cuda.is_available():
            self._device = torch.device("cuda")
            logger.info("GPU: %s", torch.cuda.get_device_name(0))
        elif hasattr(torch.backends, "mps") and torch.backends.mps.is_available():
            self._device = torch.device("mps")
        else:
            self._device = torch.device("cpu")
            logger.info("Using CPU")

        # Model
        self._model = DeepfakeClassifier()
        weights_path = self._find_weights()
        self._load(weights_path)
        self._model.to(self._device)
        self._model.eval()
        logger.info("Model ready on %s", self._device)

    def _find_weights(self) -> Path:
        """Find the best available model weights. Returns (path, is_legacy)."""
        # Prefer custom model
        if BEST_WEIGHTS.exists():
            return BEST_WEIGHTS
        if FINAL_WEIGHTS.exists():
            return FINAL_WEIGHTS
        # Fallback to legacy
        if LEGACY_WEIGHTS.exists():
            return LEGACY_WEIGHTS
        # Try to download legacy
        try:
            import urllib.request
            LEGACY_WEIGHTS.parent.mkdir(parents=True, exist_ok=True)
            logger.info("Downloading legacy model weights...")
            urllib.request.urlretrieve(LEGACY_URL, str(LEGACY_WEIGHTS))
            return LEGACY_WEIGHTS
        except Exception as e:
            raise FileNotFoundError(
                f"No model weights found. Train: python -m training.train --data data/processed"
            )

    def _load(self, path: Path):
        """Load weights into model. Handles both custom B2 and legacy B0."""
        logger.info("Loading weights: %s", path)
        ckpt = torch.load(path, map_location=self._device, weights_only=False)
        state_dict = ckpt.get("model_state_dict", ckpt)

        # Try direct load (custom model — backbone-wrapped keys)
        try:
            self._model.load_state_dict(state_dict, strict=True)
            self._model_name = "EfficientNet-B2 (Custom)"
            logger.info("Custom model loaded successfully")
            return
        except RuntimeError:
            pass

        # Try with backbone prefix (training saves raw, inference wraps in backbone)
        try:
            prefixed = {("backbone." + k): v for k, v in state_dict.items()}
            self._model.load_state_dict(prefixed, strict=True)
            self._model_name = "EfficientNet-B2 (Custom)"
            logger.info("Custom model loaded (backbone prefix added)")
            return
        except RuntimeError:
            pass

        # Try legacy EfficientNet-B0 loading
        logger.info("Trying legacy model loading...")
        # Replace the classifier to match legacy architecture
        self._model = models.efficientnet_b0(weights=None)
        num_features = self._model.classifier[1].in_features
        self._model.classifier = nn.Linear(num_features, 2)

        cleaned = {}
        for k, v in state_dict.items():
            name = k.replace("module.", "") if k.startswith("module.") else k
            # Strip 'backbone.' prefix (legacy weights have it, bare EfficientNet-B0 doesn't)
            if name.startswith("backbone."):
                name = name[len("backbone."):]
            # Skip num_batches_tracked (not a parameter)
            if "num_batches_tracked" in name:
                continue
            # Fix classifier key: classifier.1.weight -> classifier.weight
            name = name.replace("classifier.1.", "classifier.")
            cleaned[name] = v
        self._model.load_state_dict(cleaned, strict=True)
        self._model_name = "EfficientNet-B0 (Legacy FaceForensics++)"
        logger.info("Legacy model loaded successfully")

    @torch.no_grad()
    def predict(self, face_rgb: np.ndarray) -> dict:
        """
        Predict on a single face crop.

        Returns:
            {"fake_prob": float, "real_prob": float, "prediction": str}
        """
        tensor = preprocess_face(face_rgb).to(self._device)
        logits = self._model(tensor)
        probs = torch.softmax(logits, dim=1)[0]

        real_prob = probs[0].item()
        fake_prob = probs[1].item()

        return {
            "fake_prob": round(fake_prob, 4),
            "real_prob": round(real_prob, 4),
            "confidence": round(abs(fake_prob - 0.5) * 2, 4),
        }

    @torch.no_grad()
    def predict_batch(self, faces: list[np.ndarray]) -> list[dict]:
        """Predict on a batch of face crops."""
        if not faces:
            return []

        tensors = torch.cat([preprocess_face(f) for f in faces]).to(self._device)
        logits = self._model(tensors)
        probs = torch.softmax(logits, dim=1).cpu().numpy()

        results = []
        for i in range(len(faces)):
            fake_prob = float(probs[i, 1])
            real_prob = float(probs[i, 0])
            results.append({
                "fake_prob": round(fake_prob, 4),
                "real_prob": round(real_prob, 4),
                "confidence": round(abs(fake_prob - 0.5) * 2, 4),
            })
        return results


def get_model() -> DeepfakeModel:
    return DeepfakeModel.get_instance()
