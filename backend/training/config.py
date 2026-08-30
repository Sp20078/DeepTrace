"""
DeepTrace Model Training Configuration
=======================================
Supports EfficientNet-B2 and ViT-B/16 for binary deepfake detection.
Tuned for RTX 4060 (8GB VRAM) with mixed precision.
"""

from pathlib import Path

# ── Paths ──────────────────────────────────────────────────────────────────
BASE_DIR = Path(__file__).resolve().parent.parent
RAW_DATA_DIR = BASE_DIR / "data"              # User drops images here
PROCESSED_DIR = BASE_DIR / "data" / "processed"
WEIGHTS_DIR = BASE_DIR / "model_weights"
CHECKPOINTS_DIR = WEIGHTS_DIR / "checkpoints"

# ── Model ──────────────────────────────────────────────────────────────────
ARCHITECTURE = "vit_b_16"                      # efficientnet_b2 | vit_b_16 | vit_b_32 | vit_l_16
NUM_CLASSES = 2                                # real / fake
INPUT_SIZE = 224                               # 224×224 RGB (ViT-B/16 needs ≥224)
PRETRAINED = True                              # ImageNet weights

# Architecture-specific defaults
ARCH_CONFIGS = {
    "efficientnet_b2": {"lr": 3e-4, "batch_size": 16, "freeze_until": 6},
    "vit_b_16":        {"lr": 1e-4, "batch_size": 8,  "freeze_until": 6},
    "vit_b_32":        {"lr": 1e-4, "batch_size": 12, "freeze_until": 6},
    "vit_l_16":        {"lr": 5e-5, "batch_size": 4,  "freeze_until": 8},
}

# ── Dataset ────────────────────────────────────────────────────────────────
TRAIN_RATIO = 0.80
VAL_RATIO = 0.10
TEST_RATIO = 0.10
MIN_IMAGE_SIZE = 64                            # Skip images smaller than this
FACE_DETECTOR = "mtcnn"                        # mtcnn | retinaface | haar
FACE_PADDING = 0.20                            # Padding around detected face
RANDOM_SEED = 42

# ── Training ───────────────────────────────────────────────────────────────
BATCH_SIZE = ARCH_CONFIGS[ARCHITECTURE]["batch_size"]
NUM_WORKERS = 0                                # DataLoader workers (0 = main process, safer on Windows)
NUM_EPOCHS = 20
LEARNING_RATE = ARCH_CONFIGS[ARCHITECTURE]["lr"]
WEIGHT_DECAY = 1e-4
LABEL_SMOOTHING = 0.1
WARMUP_EPOCHS = 2
EARLY_STOP_PATIENCE = 5

# ── Optimizer & Scheduler ──────────────────────────────────────────────────
OPTIMIZER = "adamw"
SCHEDULER = "cosine"                           # cosine | step | plateau
STEP_SIZE = 5
GAMMA = 0.1

# ── Augmentation ───────────────────────────────────────────────────────────
RANDOM_HORIZONTAL_FLIP = 0.5
COLOR_JITTER_BRIGHTNESS = 0.2
COLOR_JITTER_CONTRAST = 0.2
COLOR_JITTER_SATURATION = 0.2
COLOR_JITTER_HUE = 0.1
RANDOM_ERASING_PROB = 0.2

# ── Mixed Precision ────────────────────────────────────────────────────────
USE_AMP = True                                 # Automatic Mixed Precision

# ── Calibration ────────────────────────────────────────────────────────────
CALIBRATION_METHOD = "platt"                   # platt | isotonic
CALIBRATION_SAMPLES = 0.2                      # Fraction of val set for calib

# ── Decision Thresholds (post-calibration) ─────────────────────────────────
THRESHOLD_HIGH = 0.65                          # Above → Likely Manipulated
THRESHOLD_LOW = 0.35                           # Below → Likely Authentic

# ── Logging ────────────────────────────────────────────────────────────────
LOG_EVERY_N_STEPS = 20
SAVE_BEST_N = 3                                # Keep top-N checkpoints

# ── Device ─────────────────────────────────────────────────────────────────
import torch
DEVICE = "cuda" if torch.cuda.is_available() else "cpu"
if DEVICE == "cuda":
    print(f"[OK] Using GPU: {torch.cuda.get_device_name(0)}")
    print(f"  VRAM: {torch.cuda.get_device_properties(0).total_memory / 1e9:.1f} GB")
else:
    print("[WARN] No GPU detected -- training will be slow on CPU")
