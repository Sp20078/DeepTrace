"""
File handling service for DeepTrace.
=====================================
Handles file validation, storage, and metadata extraction for uploaded media.

This module is designed to be called by upload endpoints and will later be
extended to feed files into the OpenCV / AI analysis pipeline.
"""

import os
import uuid
from pathlib import Path
from typing import Optional

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

# Directory where uploaded files are stored (relative to this file)
UPLOAD_DIR = Path(__file__).resolve().parent.parent / "uploads"

# Maximum file size: 100 MB (in bytes)
MAX_FILE_SIZE = 100 * 1024 * 1024

# Supported MIME types for images
SUPPORTED_IMAGE_TYPES = {
    "image/jpeg",
    "image/png",
    "image/webp",
    "image/bmp",
    "image/tiff",
}

# Supported MIME types for videos
SUPPORTED_VIDEO_TYPES = {
    "video/mp4",
    "video/quicktime",      # .mov
    "video/x-msvideo",      # .avi
    "video/webm",
    "video/x-matroska",     # .mkv
}

# All supported types combined
SUPPORTED_TYPES = SUPPORTED_IMAGE_TYPES | SUPPORTED_VIDEO_TYPES

# Friendly names for error messages
TYPE_LABELS = {
    "image/jpeg": "JPEG",
    "image/png": "PNG",
    "image/webp": "WebP",
    "image/bmp": "BMP",
    "image/tiff": "TIFF",
    "video/mp4": "MP4",
    "video/quicktime": "MOV",
    "video/x-msvideo": "AVI",
    "video/webm": "WebM",
    "video/x-matroska": "MKV",
}

# Map file extensions to MIME types (for web uploads that send application/octet-stream)
EXTENSION_TO_MIME = {
    ".jpg": "image/jpeg",
    ".jpeg": "image/jpeg",
    ".png": "image/png",
    ".webp": "image/webp",
    ".bmp": "image/bmp",
    ".tiff": "image/tiff",
    ".tif": "image/tiff",
    ".mp4": "video/mp4",
    ".mov": "video/quicktime",
    ".avi": "video/x-msvideo",
    ".webm": "video/webm",
    ".mkv": "video/x-matroska",
}


# ---------------------------------------------------------------------------
# Validation
# ---------------------------------------------------------------------------

class UploadError(Exception):
    """Raised when file upload validation fails."""
    pass


def _infer_mime_type(filename: str, content_type: Optional[str]) -> str:
    """
    Infer the actual MIME type from the filename extension.

    On web, file_picker sends 'application/octet-stream' instead of the real
    MIME type. We detect the actual type from the file extension.
    """
    # If we already have a valid MIME type, use it
    if content_type and content_type in SUPPORTED_TYPES:
        return content_type

    # Try to infer from filename extension
    if filename:
        ext = Path(filename).suffix.lower()
        if ext in EXTENSION_TO_MIME:
            return EXTENSION_TO_MIME[ext]

    # Return whatever we got (will fail validation if unsupported)
    return content_type or ""


def validate_file(
    content_type: Optional[str],
    file_size: int,
    filename: Optional[str] = None,
) -> None:
    """
    Validate an uploaded file before saving.

    Checks:
      1. Content type is supported (image or video)
      2. File size is within the allowed limit
      3. Filename is provided

    Raises:
        UploadError with a descriptive message if validation fails.
    """
    # Check that a filename was provided
    if not filename:
        raise UploadError("No filename provided.")

    # Infer the actual MIME type (handles web's application/octet-stream)
    inferred_type = _infer_mime_type(filename, content_type)

    # Check that the content type is recognized and supported
    if not inferred_type:
        raise UploadError("Could not determine the file type. Please ensure you are uploading a valid image or video.")

    if inferred_type not in SUPPORTED_TYPES:
        supported = ", ".join(sorted(TYPE_LABELS.values()))
        raise UploadError(
            f"Unsupported file type: '{inferred_type}'. "
            f"Supported formats: {supported}"
        )

    # Check file size against the limit
    if file_size > MAX_FILE_SIZE:
        max_mb = MAX_FILE_SIZE // (1024 * 1024)
        actual_mb = file_size / (1024 * 1024)
        raise UploadError(
            f"File too large: {actual_mb:.1f} MB. Maximum allowed size is {max_mb} MB."
        )

    if file_size == 0:
        raise UploadError("Uploaded file is empty (0 bytes).")


# ---------------------------------------------------------------------------
# Storage
# ---------------------------------------------------------------------------

def save_file(filename: str, file_bytes: bytes) -> dict:
    """
    Save uploaded file bytes to the uploads directory.

    Generates a unique filename using a UUID to avoid collisions,
    while preserving the original file extension.

    Returns:
        A dict with metadata about the saved file:
          - original_name: the name the user uploaded
          - stored_name: the unique name on disk
          - stored_path: full path to the saved file
          - file_size: size in bytes
    """
    # Ensure the uploads directory exists
    UPLOAD_DIR.mkdir(parents=True, exist_ok=True)

    # Extract the file extension (e.g. ".jpg") from the original name
    ext = Path(filename).suffix.lower()
    if not ext:
        ext = ".bin"  # Fallback if no extension

    # Generate a unique name: e.g. "a1b2c3d4-....jpg"
    unique_name = f"{uuid.uuid4().hex}{ext}"
    stored_path = UPLOAD_DIR / unique_name

    # Write the bytes to disk
    with open(stored_path, "wb") as f:
        f.write(file_bytes)

    return {
        "original_name": filename,
        "stored_name": unique_name,
        "stored_path": str(stored_path),
        "file_size": len(file_bytes),
    }


def get_media_category(content_type: str) -> str:
    """
    Return 'image' or 'video' based on the MIME type.
    """
    if content_type in SUPPORTED_IMAGE_TYPES:
        return "image"
    elif content_type in SUPPORTED_VIDEO_TYPES:
        return "video"
    return "unknown"
