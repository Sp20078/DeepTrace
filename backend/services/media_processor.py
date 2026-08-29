"""
Media processing service for DeepTrace.
==========================================
Uses OpenCV to safely read images and videos and extract metadata.

This module provides pure data-extraction functions. It does NOT:
  - Detect faces
  - Run AI models
  - Extract frames (yet)
  - Perform any classification

Future phases will extend this module to:
  - Extract frames at configurable intervals
  - Detect and isolate face ROIs
  - Preprocess frames for the AI model pipeline
"""

import os
import logging
from pathlib import Path
from typing import Optional

import cv2
import numpy as np

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Custom exceptions
# ---------------------------------------------------------------------------

class MediaError(Exception):
    """Raised when media reading or processing fails."""
    pass


class UnsupportedMediaError(MediaError):
    """Raised when the file format is not supported by OpenCV."""
    pass


# ---------------------------------------------------------------------------
# Image processing
# ---------------------------------------------------------------------------

def read_image_info(file_path: str) -> dict:
    """
    Read an image file using OpenCV and extract basic metadata.

    Returns a dict with:
      - width:          pixel width
      - height:         pixel height
      - channels:       number of color channels (1=gray, 3=BGR, 4=BGRA)
      - format:         file format string (e.g. "JPEG", "PNG")
      - file_size:      file size in bytes
      - is_valid:       True if the image was read successfully

    Raises:
        MediaError: if the file cannot be read or does not exist.
    """
    path = Path(file_path)

    # --- Basic file checks ---
    if not path.exists():
        raise MediaError(f"File not found: {file_path}")

    if not path.is_file():
        raise MediaError(f"Path is not a file: {file_path}")

    file_size = path.stat().st_size
    if file_size == 0:
        raise MediaError(f"File is empty (0 bytes): {file_path}")

    # --- Read with OpenCV ---
    # cv2.imread returns None on failure (corrupted file, unsupported format)
    img = cv2.imread(str(path), cv2.IMREAD_UNCHANGED)

    if img is None:
        raise MediaError(
            f"OpenCV could not read the image. The file may be corrupted "
            f"or in an unsupported format: {file_path}"
        )

    # --- Extract metadata ---
    height, width = img.shape[:2]
    channels = img.shape[2] if len(img.shape) == 3 else 1

    # Determine format from file extension
    ext = path.suffix.lower()
    format_map = {
        ".jpg": "JPEG", ".jpeg": "JPEG",
        ".png": "PNG",
        ".webp": "WebP",
        ".bmp": "BMP",
        ".tiff": "TIFF", ".tif": "TIFF",
    }
    fmt = format_map.get(ext, ext.upper().lstrip("."))

    return {
        "width": width,
        "height": height,
        "channels": channels,
        "format": fmt,
        "file_size": file_size,
        "is_valid": True,
    }


# ---------------------------------------------------------------------------
# Video processing
# ---------------------------------------------------------------------------

def read_video_info(file_path: str) -> dict:
    """
    Open a video file using OpenCV and extract metadata.

    Returns a dict with:
      - width:          frame width in pixels
      - height:         frame height in pixels
      - fps:            frames per second
      - frame_count:    total number of frames
      - duration:       duration in seconds (float)
      - duration_fmt:   human-readable duration "MM:SS" or "HH:MM:SS"
      - codec:          four-character codec code (e.g. "mp4v", "avc1")
      - codec_name:     friendly codec name if available
      - format:         container format (e.g. "MP4")
      - file_size:      file size in bytes
      - is_valid:       True if the video was opened successfully

    Raises:
        MediaError: if the video cannot be opened.
    """
    path = Path(file_path)

    # --- Basic file checks ---
    if not path.exists():
        raise MediaError(f"File not found: {file_path}")

    if not path.is_file():
        raise MediaError(f"Path is not a file: {file_path}")

    file_size = path.stat().st_size
    if file_size == 0:
        raise MediaError(f"File is empty (0 bytes): {file_path}")

    # --- Open with OpenCV ---
    cap = cv2.VideoCapture(str(path))

    if not cap.isOpened():
        raise MediaError(
            f"OpenCV could not open the video. The file may be corrupted "
            f"or in an unsupported format: {file_path}"
        )

    try:
        # --- Extract metadata ---
        width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
        height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
        fps = cap.get(cv2.CAP_PROP_FPS)
        frame_count = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))

        # Calculate duration
        duration = frame_count / fps if fps > 0 else 0.0
        duration_fmt = _format_duration(duration)

        # Codec info
        codec_code = int(cap.get(cv2.CAP_PROP_FOURCC))
        codec = _fourcc_to_string(codec_code)
        codec_name = _get_codec_name(codec)

        # Container format from extension
        ext = path.suffix.lower()
        format_map = {
            ".mp4": "MP4",
            ".mov": "MOV",
            ".avi": "AVI",
            ".webm": "WebM",
            ".mkv": "MKV",
        }
        fmt = format_map.get(ext, ext.upper().lstrip("."))

        return {
            "width": width,
            "height": height,
            "fps": round(fps, 2),
            "frame_count": frame_count,
            "duration": round(duration, 2),
            "duration_fmt": duration_fmt,
            "codec": codec,
            "codec_name": codec_name,
            "format": fmt,
            "file_size": file_size,
            "is_valid": True,
        }
    finally:
        # Always release the capture -- even if an error occurs
        cap.release()


# ---------------------------------------------------------------------------
# Auto-detect and extract info
# ---------------------------------------------------------------------------

def read_media_info(file_path: str) -> dict:
    """
    Auto-detect whether the file is an image or video and extract metadata.

    Uses OpenCV's imread for images and VideoCapture for videos.
    Falls back gracefully if one method fails.

    Returns a dict with:
      - media_category: "image" or "video"
      - file_path:      the original path
      - ... plus all fields from read_image_info or read_video_info

    Raises:
        MediaError: if neither method can read the file.
    """
    path = Path(file_path)
    if not path.exists():
        raise MediaError(f"File not found: {file_path}")

    ext = path.suffix.lower()

    # Heuristic: try image first for known image extensions,
    # try video first for known video extensions.
    image_exts = {".jpg", ".jpeg", ".png", ".webp", ".bmp", ".tiff", ".tif"}
    video_exts = {".mp4", ".mov", ".avi", ".webm", ".mkv"}

    if ext in image_exts:
        try:
            info = read_image_info(file_path)
            info["media_category"] = "image"
            info["file_path"] = file_path
            return info
        except MediaError:
            pass  # Fall through to try video

    if ext in video_exts:
        try:
            info = read_video_info(file_path)
            info["media_category"] = "video"
            info["file_path"] = file_path
            return info
        except MediaError:
            pass  # Fall through

    # Unknown extension -- try both
    for reader, category in [
        (read_image_info, "image"),
        (read_video_info, "video"),
    ]:
        try:
            info = reader(file_path)
            info["media_category"] = category
            info["file_path"] = file_path
            return info
        except MediaError:
            continue

    raise MediaError(
        f"Could not read file as image or video: {file_path}. "
        f"The file may be corrupted or in an unsupported format."
    )


# ---------------------------------------------------------------------------
# Utility helpers
# ---------------------------------------------------------------------------

def _fourcc_to_string(fourcc: int) -> str:
    """Convert an OpenCV FOURCC integer to a 4-character string."""
    chars = []
    for i in range(4):
        char_code = (fourcc >> (8 * i)) & 0xFF
        if 32 <= char_code < 127:
            chars.append(chr(char_code))
        else:
            chars.append("?")
    return "".join(chars)


def _get_codec_name(fourcc_str: str) -> str:
    """Map a FOURCC string to a human-readable codec name."""
    known = {
        "mp4v": "MPEG-4 Part 2",
        "avc1": "H.264 / AVC",
        "h264": "H.264",
        "hevc": "H.265 / HEVC",
        "vp80": "VP8",
        "vp09": "VP9",
        "av01": "AV1",
        "XVID": "Xvid",
        "MJPG": "Motion JPEG",
    }
    return known.get(fourcc_str, fourcc_str)


def _format_duration(seconds: float) -> str:
    """Format seconds as 'MM:SS' or 'HH:MM:SS'."""
    total = int(seconds)
    h = total // 3600
    m = (total % 3600) // 60
    s = total % 60
    if h > 0:
        return f"{h:02d}:{m:02d}:{s:02d}"
    return f"{m:02d}:{s:02d}"
