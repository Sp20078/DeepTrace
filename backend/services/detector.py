"""
DeepTrace Face Detector — Clean Rebuild
=========================================
MTCNN face detection with OpenCV fallback.
"""

import logging
from pathlib import Path

import cv2
import numpy as np

logger = logging.getLogger(__name__)

# ── MTCNN (primary) ───────────────────────────────────────────────────────

_mtcnn = None


def _get_mtcnn():
    global _mtcnn
    if _mtcnn is None:
        try:
            from facenet_pytorch import MTCNN as _MTCNN
            _mtcnn = _MTCNN(
                keep_all=True,
                device="cpu",
                min_face_size=30,
                thresholds=[0.9, 0.9, 0.9],
                post_process=True,
            )
            logger.info("MTCNN initialized")
        except ImportError:
            logger.warning("facenet-pytorch not installed, using Haar cascades")
    return _mtcnn


# ── Detection ──────────────────────────────────────────────────────────────

def detect_faces(frame: np.ndarray, padding: float = 0.2) -> list[dict]:
    """
    Detect faces in a BGR frame.

    Returns list of dicts:
        {"bbox": (x, y, w, h), "crop_rgb": np.ndarray, "confidence": float}
    """
    mtcnn = _get_mtcnn()
    if mtcnn is not None:
        return _detect_mtcnn(frame, mtcnn, padding)
    return _detect_haar(frame, padding)


def _detect_mtcnn(frame: np.ndarray, mtcnn, padding: float) -> list[dict]:
    """MTCNN detection + crop."""
    from PIL import Image

    rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    pil_img = Image.fromarray(rgb)

    try:
        boxes, probs = mtcnn.detect(pil_img)
    except Exception as e:
        logger.warning("MTCNN failed: %s, falling back to Haar", e)
        return _detect_haar(frame, padding)

    faces = []
    fh, fw = frame.shape[:2]

    if boxes is not None:
        for box, prob in zip(boxes, probs):
            if prob < 0.85:
                continue

            x1, y1, x2, y2 = box.astype(int)
            w, h = x2 - x1, y2 - y1
            if w < 20 or h < 20:
                continue

            # Apply padding
            pad_w, pad_h = int(w * padding), int(h * padding)
            px1 = max(0, x1 - pad_w)
            py1 = max(0, y1 - pad_h)
            px2 = min(fw, x2 + pad_w)
            py2 = min(fh, y2 + pad_h)

            # Crop face as RGB
            crop_rgb = rgb[py1:py2, px1:px2].copy()

            faces.append({
                "bbox": (int(x1), int(y1), int(w), int(h)),
                "padded_bbox": (px1, py1, px2 - px1, py2 - py1),
                "crop_rgb": crop_rgb,
                "confidence": float(prob),
                "area": int(w * h),
            })

    faces.sort(key=lambda f: f["area"], reverse=True)
    logger.debug("MTCNN: %d faces", len(faces))
    return faces


def _detect_haar(frame: np.ndarray, padding: float) -> list[dict]:
    """Haar cascade fallback."""
    cascade_path = str(Path(cv2.data.haarcascades) / "haarcascade_frontalface_default.xml")
    cascade = cv2.CascadeClassifier(cascade_path)
    gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
    rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)

    raw = cascade.detectMultiScale(gray, 1.1, 5, minSize=(30, 30))
    fh, fw = frame.shape[:2]

    faces = []
    for (x, y, w, h) in raw:
        pad_w, pad_h = int(w * padding), int(h * padding)
        px1 = max(0, x - pad_w)
        py1 = max(0, y - pad_h)
        px2 = min(fw, x + w + pad_w)
        py2 = min(fh, y + h + pad_h)

        crop_rgb = rgb[py1:py2, px1:px2].copy()

        faces.append({
            "bbox": (int(x), int(y), int(w), int(h)),
            "padded_bbox": (px1, py1, px2 - px1, py2 - py1),
            "crop_rgb": crop_rgb,
            "confidence": 0.5,
            "area": int(w * h),
        })

    faces.sort(key=lambda f: f["area"], reverse=True)
    logger.debug("Haar: %d faces", len(faces))
    return faces
