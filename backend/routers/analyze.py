"""
DeepTrace Analyze Router — Clean Rebuild
==========================================
Single POST /analyze endpoint.
Upload + validate + save + analyze + return results.
"""

import logging
import tempfile
from pathlib import Path

from fastapi import APIRouter, File, UploadFile, HTTPException

from services.analyzer import run_analysis

logger = logging.getLogger(__name__)
router = APIRouter()

# Supported types
SUPPORTED_IMAGES = {"image/jpeg", "image/png", "image/webp", "image/bmp"}
SUPPORTED_VIDEOS = {"video/mp4", "video/quicktime", "video/x-msvideo", "video/webm"}
EXTENSION_MAP = {
    ".jpg": "image/jpeg", ".jpeg": "image/jpeg", ".png": "image/png",
    ".webp": "image/webp", ".bmp": "image/bmp",
    ".mp4": "video/mp4", ".mov": "video/quicktime",
    ".avi": "video/x-msvideo", ".webm": "video/webm",
}
MAX_SIZE = 100 * 1024 * 1024  # 100MB


def _infer_type(filename: str, content_type: str | None) -> str:
    """Infer MIME type from filename extension."""
    if content_type and (content_type in SUPPORTED_IMAGES or content_type in SUPPORTED_VIDEOS):
        return content_type
    if filename:
        ext = Path(filename).suffix.lower()
        if ext in EXTENSION_MAP:
            return EXTENSION_MAP[ext]
    return content_type or ""


@router.post("/analyze", tags=["Analysis"])
async def analyze_media(file: UploadFile = File(...)):
    """
    Upload and analyze an image or video for deepfake detection.

    Returns complete analysis results with:
    - Risk score and level
    - Per-face analysis
    - Suspicious frames (video)
    - Findings generated from real model output
    - Analysis breakdown (visual/temporal/metadata/face)
    """
    # 1. Read file
    content = await file.read()
    file_size = len(content)

    # 2. Validate
    if not file.filename:
        raise HTTPException(status_code=400, detail="No filename provided.")
    if file_size == 0:
        raise HTTPException(status_code=400, detail="File is empty.")
    if file_size > MAX_SIZE:
        raise HTTPException(status_code=400, detail=f"File too large ({file_size / 1e6:.1f}MB). Max: 100MB.")

    mime_type = _infer_type(file.filename, file.content_type)
    is_image = mime_type in SUPPORTED_IMAGES
    is_video = mime_type in SUPPORTED_VIDEOS

    if not is_image and not is_video:
        raise HTTPException(
            status_code=400,
            detail=f"Unsupported file type: {mime_type}. "
                   f"Supported: JPEG, PNG, WebP, BMP, MP4, MOV, AVI, WebM"
        )

    # 3. Save to temp file
    suffix = Path(file.filename).suffix or (".mp4" if is_video else ".jpg")
    with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as tmp:
        tmp.write(content)
        tmp_path = tmp.name

    # 4. Run analysis
    try:
        result = await run_analysis(
            file_path=tmp_path,
            media_type=mime_type,
            filename=file.filename,
        )
    except Exception as e:
        logger.exception("Analysis failed")
        raise HTTPException(status_code=500, detail=f"Analysis failed: {e}")
    finally:
        # Cleanup temp file
        try:
            Path(tmp_path).unlink(missing_ok=True)
        except Exception:
            pass

    return result
