"""
Face detection and AI-ready preprocessing for DeepTrace.
=========================================================
Detects faces in images/frames and prepares crops for a future
deepfake detection model.

This module provides:
  - Face detection using OpenCV Haar cascade classifiers
  - Face cropping with bounding box metadata
  - Configurable resizing and color-space conversion
  - A clean preprocessing interface for the future AI model

This module does NOT:
  - Run any AI/deepfake model
  - Perform classification or scoring
  - Make any predictions

Architecture separation:
  media_processor.py  ->  reading, metadata, frame extraction
  face_detector.py    ->  face detection, cropping, preprocessing
  (future) ai_model.py ->  model loading, inference, scoring
"""

import logging
from pathlib import Path
from typing import Optional, Union

import cv2
import numpy as np

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Exceptions
# ---------------------------------------------------------------------------

class FaceDetectionError(Exception):
    """Raised when face detection or preprocessing fails."""
    pass


# ---------------------------------------------------------------------------
# Haar cascade loader (singleton pattern -- load once, reuse)
# ---------------------------------------------------------------------------

# Path to the built-in Haar cascade XML that ships with OpenCV.
# No download required -- it is bundled with opencv-python.
_HAAR_CASCADE_DIR = cv2.data.haarcascades
_HAAR_FRONTFACE_DEFAULT = "haarcascade_frontalface_default.xml"
_HAAR_FRONTFACE_ALT = "haarcascade_frontalface_alt.xml"

# Cache the loaded classifier to avoid re-loading on every call
_cascade_cache: dict[str, cv2.CascadeClassifier] = {}


def _get_cascade(name: str = _HAAR_FRONTFACE_DEFAULT) -> cv2.CascadeClassifier:
    """
    Load (and cache) a Haar cascade classifier.

    Args:
        name: Filename of the cascade XML (looked up in cv2.data.haarcascades).

    Returns:
        A loaded CascadeClassifier instance.

    Raises:
        FaceDetectionError: if the cascade file cannot be loaded.
    """
    if name not in _cascade_cache:
        path = str(Path(_HAAR_CASCADE_DIR) / name)
        cascade = cv2.CascadeClassifier(path)
        if cascade.empty():
            raise FaceDetectionError(
                f"Failed to load Haar cascade from: {path}. "
                f"OpenCV may not be installed correctly."
            )
        _cascade_cache[name] = cascade
        logger.info("Loaded Haar cascade: %s", name)
    return _cascade_cache[name]


# ---------------------------------------------------------------------------
# Face detection
# ---------------------------------------------------------------------------

def detect_faces(
    frame: np.ndarray,
    scale_factor: float = 1.1,
    min_neighbors: int = 5,
    min_size: tuple[int, int] = (30, 30),
    cascade_name: str = _HAAR_FRONTFACE_DEFAULT,
) -> list[dict]:
    """
    Detect faces in a single BGR frame using a Haar cascade classifier.

    Args:
        frame:          OpenCV BGR image (numpy array, HxWxC).
        scale_factor:   How much the image size is reduced at each scale.
                        Larger values = faster but less accurate.
        min_neighbors:  How many neighbors each candidate rectangle should
                        have to retain it. Higher = fewer false positives.
        min_size:       Minimum possible face size as (width, height).
        cascade_name:   Which Haar cascade to use.

    Returns:
        A list of face dicts, one per detected face:
          - bbox:        (x, y, w, h) bounding box in pixels
          - x, y, w, h: individual bounding box values
          - confidence:  approximate confidence (based on neighbors)
          - area:        bounding box area in pixels

        Returns an empty list if no faces are detected.
    """
    if frame is None or frame.size == 0:
        return []

    cascade = _get_cascade(cascade_name)

    # Haar cascades work on grayscale -- convert for detection
    gray = _to_grayscale(frame)

    # Detect faces
    raw_faces = cascade.detectMultiScale(
        gray,
        scaleFactor=scale_factor,
        minNeighbors=min_neighbors,
        minSize=min_size,
        flags=cv2.CASCADE_SCALE_IMAGE,
    )

    if len(raw_faces) == 0:
        return []

    # Convert to list of dicts with metadata
    faces = []
    for (x, y, w, h) in raw_faces:
        area = w * h
        # Approximate confidence: higher min_neighbors count in detection
        # means higher confidence. We use neighbors as a rough proxy.
        faces.append({
            "bbox": (int(x), int(y), int(w), int(h)),
            "x": int(x),
            "y": int(y),
            "w": int(w),
            "h": int(h),
            "area": area,
        })

    # Sort largest-first (most likely to be a real face)
    faces.sort(key=lambda f: f["area"], reverse=True)

    logger.debug("Detected %d face(s) in frame", len(faces))
    return faces


def detect_faces_in_image(
    image_path: str,
    **kwargs,
) -> tuple[np.ndarray, list[dict]]:
    """
    Load an image and detect faces in it.

    Args:
        image_path: Path to the image file.
        **kwargs:   Passed to detect_faces() (scale_factor, min_neighbors, etc.)

    Returns:
        A tuple of (image, faces) where faces is the list from detect_faces().

    Raises:
        FaceDetectionError: if the image cannot be read.
    """
    img = cv2.imread(str(image_path), cv2.IMREAD_COLOR)
    if img is None:
        raise FaceDetectionError(f"Could not read image: {image_path}")

    faces = detect_faces(img, **kwargs)
    return img, faces


# ---------------------------------------------------------------------------
# Face cropping
# ---------------------------------------------------------------------------

def crop_faces(
    frame: np.ndarray,
    faces: list[dict],
    padding: float = 0.2,
) -> list[dict]:
    """
    Crop face regions from a frame, with optional padding around each face.

    Args:
        frame:   OpenCV BGR image.
        faces:   List of face dicts from detect_faces().
        padding: Fraction of face size to add as padding on each side.
                 E.g. 0.2 adds 20% padding. Clamped to frame bounds.

    Returns:
        A list of dicts, one per face:
          - crop:        numpy array of the cropped face region (BGR)
          - bbox:        original (x, y, w, h)
          - padded_bbox: (px, py, pw, ph) after padding
          - crop_size:   (width, height) of the crop
    """
    if not faces:
        return []

    fh, fw = frame.shape[:2]
    cropped = []

    for face in faces:
        x, y, w, h = face["bbox"]

        # Calculate padded bounding box
        pad_w = int(w * padding)
        pad_h = int(h * padding)
        px = max(0, x - pad_w)
        py = max(0, y - pad_h)
        pw = min(fw - px, w + 2 * pad_w)
        ph = min(fh - py, h + 2 * pad_h)

        # Crop the face region
        crop = frame[py:py + ph, px:px + pw]

        cropped.append({
            "crop": crop,
            "bbox": face["bbox"],
            "padded_bbox": (px, py, pw, ph),
            "crop_size": (pw, ph),
        })

    return cropped


# ---------------------------------------------------------------------------
# Preprocessing for AI model
# ---------------------------------------------------------------------------

def preprocess_face(
    face_crop: np.ndarray,
    target_size: tuple[int, int] = (224, 224),
    color_mode: str = "bgr",
    normalize: bool = True,
    output_dtype: np.dtype = np.float32,
) -> np.ndarray:
    """
    Preprocess a face crop for the future AI model.

    This function is intentionally generic and configurable so that
    the future model can specify its own input requirements.

    Steps:
      1. Resize to target_size (width, height)
      2. Convert color space if needed
      3. Normalize pixel values to [0, 1] or [0, 255]
      4. Return as a numpy array ready for model input

    Args:
        face_crop:    BGR numpy array from crop_faces().
        target_size:  (width, height) to resize to. Default 224x224
                      (common for CNNs like ResNet, EfficientNet).
        color_mode:   Target color space:
                        "bgr"  -- keep OpenCV default
                        "rgb"  -- convert to RGB (needed for most PyTorch models)
                        "gray" -- convert to single-channel grayscale
        normalize:    If True, scale pixel values to [0.0, 1.0] (float32).
                      If False, keep as uint8 [0, 255].
        output_dtype: Numpy dtype for the output array.

    Returns:
        A numpy array with shape depending on color_mode:
          - "bgr"/"rgb": (H, W, 3)
          - "gray":      (H, W) or (H, W, 1)
    """
    if face_crop is None or face_crop.size == 0:
        raise FaceDetectionError("Empty face crop provided for preprocessing.")

    # 1. Resize
    resized = cv2.resize(face_crop, target_size, interpolation=cv2.INTER_LINEAR)

    # 2. Color conversion
    if color_mode == "rgb":
        processed = cv2.cvtColor(resized, cv2.COLOR_BGR2RGB)
    elif color_mode == "gray":
        processed = cv2.cvtColor(resized, cv2.COLOR_BGR2GRAY)
    elif color_mode == "bgr":
        processed = resized
    else:
        raise FaceDetectionError(
            f"Unknown color_mode: '{color_mode}'. "
            f"Expected 'bgr', 'rgb', or 'gray'."
        )

    # 3. Normalize
    if normalize:
        processed = processed.astype(output_dtype) / 255.0

    return processed


def preprocess_faces(
    face_crops: list[dict],
    target_size: tuple[int, int] = (224, 224),
    color_mode: str = "rgb",
    normalize: bool = True,
) -> list[dict]:
    """
    Preprocess multiple face crops and attach the result to each dict.

    Takes the output of crop_faces() and adds an "ai_input" key to each
    dict containing the preprocessed array ready for the model.

    Args:
        face_crops:  List of dicts from crop_faces() (each has a "crop" key).
        target_size: (width, height) for the model input.
        color_mode:  "bgr", "rgb", or "gray".
        normalize:   Scale to [0, 1] float32.

    Returns:
        The same list, with each dict gaining:
          - ai_input: numpy array ready for model inference
          - ai_input_shape: shape of the array
          - ai_input_dtype: dtype of the array
    """
    results = []
    for entry in face_crops:
        processed = preprocess_face(
            face_crop=entry["crop"],
            target_size=target_size,
            color_mode=color_mode,
            normalize=normalize,
        )
        enriched = dict(entry)  # shallow copy -- don't mutate original
        enriched["ai_input"] = processed
        enriched["ai_input_shape"] = processed.shape
        enriched["ai_input_dtype"] = str(processed.dtype)
        # Remove the raw crop to save memory (the AI input replaces it)
        del enriched["crop"]
        results.append(enriched)
    return results


# ---------------------------------------------------------------------------
# High-level pipeline: video -> faces -> AI-ready data
# ---------------------------------------------------------------------------

def process_frame_for_ai(
    frame: np.ndarray,
    frame_number: int = 0,
    timestamp: float = 0.0,
    target_size: tuple[int, int] = (224, 224),
    color_mode: str = "rgb",
    normalize: bool = True,
    face_padding: float = 0.2,
) -> dict:
    """
    Full pipeline for a single frame: detect faces -> crop -> preprocess.

    This is the main entry point that the analysis pipeline will call
    for each extracted video frame.

    Args:
        frame:         OpenCV BGR image (from video or image file).
        frame_number:  Source frame number in the video.
        timestamp:     Time in seconds within the video.
        target_size:   (width, height) for AI model input.
        color_mode:    "bgr", "rgb", or "gray".
        normalize:     Scale to [0, 1] float32.
        face_padding:  Padding around face crops.

    Returns:
        A dict with:
          - frame_number:  source frame number
          - timestamp:     time in seconds
          - timestamp_fmt: human-readable time
          - frame_size:    (width, height) of original frame
          - faces_found:   number of faces detected
          - faces:         list of face dicts, each with:
              - bbox, padded_bbox, crop_size
              - ai_input:      preprocessed numpy array
              - ai_input_shape: shape of the array
          - ai_inputs:     flat list of just the ai_input arrays
                            (convenient for batch model inference)
    """
    fh, fw = frame.shape[:2]

    # Step 1: Detect faces
    faces = detect_faces(frame)

    # Step 2: Crop faces
    cropped = crop_faces(frame, faces, padding=face_padding)

    # Step 3: Preprocess for AI
    if cropped:
        preprocessed = preprocess_faces(
            cropped,
            target_size=target_size,
            color_mode=color_mode,
            normalize=normalize,
        )
    else:
        preprocessed = []

    # Build the result
    from services.media_processor import _format_duration

    return {
        "frame_number": frame_number,
        "timestamp": round(timestamp, 3),
        "timestamp_fmt": _format_duration(timestamp),
        "frame_size": (fw, fh),
        "faces_found": len(preprocessed),
        "faces": preprocessed,
        # Flat list of ai_input arrays for batch inference
        "ai_inputs": [f["ai_input"] for f in preprocessed],
    }


def process_image_for_ai(
    image_path: str,
    target_size: tuple[int, int] = (224, 224),
    color_mode: str = "rgb",
    normalize: bool = True,
    face_padding: float = 0.2,
) -> dict:
    """
    Full pipeline for a single image file: load -> detect -> crop -> preprocess.

    Args:
        image_path:    Path to the image file.
        target_size:   (width, height) for AI model input.
        color_mode:    "bgr", "rgb", or "gray".
        normalize:     Scale to [0, 1] float32.
        face_padding:  Padding around face crops.

    Returns:
        Same structure as process_frame_for_ai().

    Raises:
        FaceDetectionError: if the image cannot be read.
    """
    img = cv2.imread(str(image_path), cv2.IMREAD_COLOR)
    if img is None:
        raise FaceDetectionError(f"Could not read image: {image_path}")

    return process_frame_for_ai(
        frame=img,
        frame_number=0,
        timestamp=0.0,
        target_size=target_size,
        color_mode=color_mode,
        normalize=normalize,
        face_padding=face_padding,
    )


def process_video_frames_for_ai(
    frames: list[dict],
    target_size: tuple[int, int] = (224, 224),
    color_mode: str = "rgb",
    normalize: bool = True,
    face_padding: float = 0.2,
) -> list[dict]:
    """
    Process a list of extracted video frames through the face detection
    and preprocessing pipeline.

    This is designed to receive the output of media_processor.extract_frames()
    and run each frame through detect -> crop -> preprocess.

    Args:
        frames:        List of frame dicts from extract_frames().
                       Each must have a "path" key pointing to a saved frame.
        target_size:   (width, height) for AI model input.
        color_mode:    "bgr", "rgb", or "gray".
        normalize:     Scale to [0, 1] float32.
        face_padding:  Padding around face crops.

    Returns:
        A list of result dicts (same structure as process_frame_for_ai).
        Frames where no face is detected still appear in the output
        (with faces_found=0) so the pipeline can track which timestamps
        had no detectable faces.
    """
    results = []
    for frame_info in frames:
        frame_path = frame_info.get("path")
        if not frame_path or not Path(frame_path).exists():
            logger.warning("Skipping frame with missing path: %s", frame_path)
            continue

        img = cv2.imread(str(frame_path), cv2.IMREAD_COLOR)
        if img is None:
            logger.warning("Could not read frame image: %s", frame_path)
            continue

        result = process_frame_for_ai(
            frame=img,
            frame_number=frame_info.get("frame_number", 0),
            timestamp=frame_info.get("timestamp", 0.0),
            target_size=target_size,
            color_mode=color_mode,
            normalize=normalize,
            face_padding=face_padding,
        )
        results.append(result)

    logger.info(
        "Processed %d frames: %d total faces found",
        len(results),
        sum(r["faces_found"] for r in results),
    )
    return results


# ---------------------------------------------------------------------------
# Utility
# ---------------------------------------------------------------------------

def _to_grayscale(frame: np.ndarray) -> np.ndarray:
    """Convert a BGR frame to grayscale for Haar cascade detection."""
    if len(frame.shape) == 2:
        return frame  # Already grayscale
    return cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
