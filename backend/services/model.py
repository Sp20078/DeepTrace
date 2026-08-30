"""
DeepTrace Model Service
=======================
Loads the trained deepfake classifier and runs inference.
Supports EfficientNet-B2 and ViT-B/16 architectures.
Applies Platt scaling calibration when available.
"""

import logging
import math
import pickle
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
CALIBRATOR_PATH = WEIGHTS_DIR / "calibrator.pkl"

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


# ── Model Architectures ────────────────────────────────────────────────────
class EfficientNetB2Classifier(nn.Module):
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


class ViTClassifier(nn.Module):
    """Vision Transformer binary classifier (real vs fake).

    Supports ViT-B/16, ViT-B/32, ViT-L/16 from torchvision.
    """

    VIT_BUILDERS = {
        "vit_b_16": (models.vit_b_16, 768),
        "vit_b_32": (models.vit_b_32, 768),
        "vit_l_16": (models.vit_l_16, 1024),
    }

    def __init__(self, variant: str = "vit_b_16"):
        super().__init__()
        if variant not in self.VIT_BUILDERS:
            raise ValueError(f"Unknown ViT variant: {variant}. "
                             f"Choose from: {list(self.VIT_BUILDERS.keys())}")

        builder, hidden_dim = self.VIT_BUILDERS[variant]
        self.backbone = builder(weights=None)
        # Replace the default 1000-class head with our binary classifier
        self.backbone.heads = nn.Sequential(
            nn.Dropout(p=0.3),
            nn.Linear(hidden_dim, 256),
            nn.ReLU(inplace=True),
            nn.Dropout(p=0.2),
            nn.Linear(256, 2),
        )
        self._variant = variant

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        return self.backbone(x)


# Architecture registry for lookup by name
ARCHITECTURE_REGISTRY = {
    "efficientnet_b2": EfficientNetB2Classifier,
    "vit_b_16": lambda: ViTClassifier("vit_b_16"),
    "vit_b_32": lambda: ViTClassifier("vit_b_32"),
    "vit_l_16": lambda: ViTClassifier("vit_l_16"),
}


def create_classifier(architecture: str = "efficientnet_b2") -> nn.Module:
    """Create a classifier by architecture name."""
    builder = ARCHITECTURE_REGISTRY.get(architecture)
    if builder is None:
        raise ValueError(f"Unknown architecture: {architecture}. "
                         f"Available: {list(ARCHITECTURE_REGISTRY.keys())}")
    return builder()


# ── Inference Engine ───────────────────────────────────────────────────────
class PlattScaler:
    """Platt scaling for probability calibration."""

    def __init__(self, a: float = 1.0, b: float = 0.0):
        self.a = a
        self.b = b
        self.fitted = True if a != 1.0 or b != 0.0 else False

    def calibrate(self, raw_fake_prob: float) -> float:
        """Apply sigmoid calibration to a raw fake probability."""
        if not self.fitted:
            return raw_fake_prob
        logit = self.a * raw_fake_prob + self.b
        return 1.0 / (1.0 + math.exp(-logit))

    @classmethod
    def load(cls, path: Path) -> "PlattScaler":
        try:
            with open(path, "rb") as f:
                data = pickle.load(f)
            return cls(a=float(data["a"]), b=float(data["b"]))
        except Exception as e:
            logger.warning("Failed to load calibrator from %s: %s", path, e)
            return cls()


class DeepfakeModel:
    """Singleton model wrapper for inference."""

    _instance: Optional["DeepfakeModel"] = None
    _model: Optional[nn.Module] = None
    _device: Optional[torch.device] = None
    _calibrator: Optional[PlattScaler] = None

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

        # Find and load weights — auto-detects architecture from checkpoint
        weights_path = self._find_weights()
        self._model, self._model_name = self._load(weights_path)
        self._model.to(self._device)
        self._model.eval()

        # Calibration
        self._calibrator = PlattScaler.load(CALIBRATOR_PATH)
        if self._calibrator.fitted:
            logger.info("Platt scaling calibration loaded (a=%.4f, b=%.4f)",
                        self._calibrator.a, self._calibrator.b)
        else:
            logger.warning("No calibrator found — using raw model outputs")

        logger.info("Model ready on %s (%s)", self._device, self._model_name)

    def _find_weights(self) -> Path:
        """Find the best available model weights."""
        # Prefer ViT weights if they exist
        vit_best = WEIGHTS_DIR / "vit_b_16_deeptrace_best.pth"
        vit_final = WEIGHTS_DIR / "vit_b_16_deeptrace_final.pth"
        if vit_best.exists():
            return vit_best
        if vit_final.exists():
            return vit_final
        # Then EfficientNet-B2
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

    def _load(self, path: Path) -> tuple[nn.Module, str]:
        """Load weights into model. Auto-detects architecture from checkpoint config."""
        logger.info("Loading weights: %s", path)
        ckpt = torch.load(path, map_location=self._device, weights_only=False)
        state_dict = ckpt.get("model_state_dict", ckpt)
        config = ckpt.get("config", {})

        # Auto-detect architecture from checkpoint config
        arch = config.get("architecture", "efficientnet_b2").lower()
        model_name = config.get("model", arch)

        # Map friendly names to registry keys
        arch_map = {
            "efficientnet_b2": "efficientnet_b2",
            "efficientnet-b2": "efficientnet_b2",
            "efficientnet_b0": "efficientnet_b2",  # will fail, triggers fallback
            "vit_b_16": "vit_b_16",
            "vit-b/16": "vit_b_16",
            "vit_b_32": "vit_b_32",
            "vit_l_16": "vit_l_16",
        }
        arch_key = arch_map.get(arch, arch)

        # Try loading with the detected architecture
        if arch_key in ARCHITECTURE_REGISTRY:
            logger.info("Detected architecture: %s", arch_key)
            model = create_classifier(arch_key)
            display_name = config.get("architecture", arch_key).replace("_", "-").upper()

            # Attempt direct load
            try:
                model.load_state_dict(state_dict, strict=True)
                return model, f"{display_name} (Custom)"
            except RuntimeError:
                pass

            # Try with backbone prefix
            try:
                prefixed = {("backbone." + k): v for k, v in state_dict.items()}
                model.load_state_dict(prefixed, strict=True)
                return model, f"{display_name} (Custom)"
            except RuntimeError:
                pass

        # Fallback: try EfficientNet-B2 as default
        logger.info("Architecture '%s' not in registry, trying EfficientNet-B2 fallback", arch_key)
        model = EfficientNetB2Classifier()

        # Direct load
        try:
            model.load_state_dict(state_dict, strict=True)
            return model, "EfficientNet-B2 (Custom)"
        except RuntimeError:
            pass

        # With backbone prefix
        try:
            prefixed = {("backbone." + k): v for k, v in state_dict.items()}
            model.load_state_dict(prefixed, strict=True)
            return model, "EfficientNet-B2 (Custom)"
        except RuntimeError:
            pass

        # Legacy EfficientNet-B0 loading
        logger.info("Trying legacy EfficientNet-B0 loading...")
        model = models.efficientnet_b0(weights=None)
        num_features = model.classifier[1].in_features
        model.classifier = nn.Linear(num_features, 2)

        cleaned = {}
        for k, v in state_dict.items():
            name = k.replace("module.", "") if k.startswith("module.") else k
            if name.startswith("backbone."):
                name = name[len("backbone."):]
            if "num_batches_tracked" in name:
                continue
            name = name.replace("classifier.1.", "classifier.")
            cleaned[name] = v
        model.load_state_dict(cleaned, strict=True)
        return model, "EfficientNet-B0 (Legacy FaceForensics++)"

    @torch.no_grad()
    def predict(self, face_rgb: np.ndarray) -> dict:
        """
        Predict on a single face crop.

        Returns:
            {"fake_prob": float, "real_prob": float, "confidence": float}
        """
        tensor = preprocess_face(face_rgb).to(self._device)
        logits = self._model(tensor)
        probs = torch.softmax(logits, dim=1)[0]

        raw_fake_prob = probs[1].item()

        # Apply Platt scaling calibration if available
        calibrated_fake_prob = self._calibrator.calibrate(raw_fake_prob)
        calibrated_real_prob = 1.0 - calibrated_fake_prob

        return {
            "fake_prob": round(calibrated_fake_prob, 4),
            "real_prob": round(calibrated_real_prob, 4),
            "raw_fake_prob": round(raw_fake_prob, 4),
            "confidence": round(abs(calibrated_fake_prob - 0.5) * 2, 4),
            "calibrated": self._calibrator.fitted,
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
            raw_fake_prob = float(probs[i, 1])
            calibrated_fake_prob = self._calibrator.calibrate(raw_fake_prob)
            calibrated_real_prob = 1.0 - calibrated_fake_prob
            results.append({
                "fake_prob": round(calibrated_fake_prob, 4),
                "real_prob": round(calibrated_real_prob, 4),
                "raw_fake_prob": round(raw_fake_prob, 4),
                "confidence": round(abs(calibrated_fake_prob - 0.5) * 2, 4),
                "calibrated": self._calibrator.fitted,
            })
        return results


def get_model() -> DeepfakeModel:
    return DeepfakeModel.get_instance()
