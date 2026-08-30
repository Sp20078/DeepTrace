"""
Analysis router for DeepTrace.
================================
POST /analyze endpoint — accepts a media file and runs the full
analysis pipeline: OpenCV -> face detection -> AI inference -> results.
"""

import logging
from fastapi import APIRouter, File, UploadFile, HTTPException

from services.file_handler import (
    UploadError,
    validate_file,
    save_file,
    get_media_category,
    _infer_mime_type,
)
from services.analysis import run_analysis_pipeline

logger = logging.getLogger(__name__)
router = APIRouter()


@router.post("/analyze", tags=["Analysis"])
async def analyze_media(file: UploadFile = File(...)):
    """
    Upload and analyze an image or video for deepfake detection.

    Supported formats:
    - Images: JPEG, PNG, WebP, BMP, TIFF
    - Videos: MP4, MOV, AVI, WebM, MKV

    Max file size: 100 MB

    Returns JSON with analysis results including risk score,
    frame-level predictions, suspicious timestamps, and findings.
    """
    # 1. Read the uploaded file
    content = await file.read()
    file_size = len(content)

    # 2. Validate
    try:
        validate_file(
            content_type=file.content_type,
            file_size=file_size,
            filename=file.filename,
        )
    except UploadError as e:
        raise HTTPException(status_code=400, detail=str(e))

    # 3. Save to disk
    try:
        saved = save_file(filename=file.filename, file_bytes=content)
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to save file: {e}",
        )

    # 4. Run real analysis pipeline
    try:
        # Infer the actual MIME type (handles web's application/octet-stream)
        inferred_type = _infer_mime_type(file.filename, file.content_type)
        media_category = get_media_category(inferred_type)
        result = await run_analysis_pipeline(
            file_path=saved["stored_path"],
            media_type=inferred_type,
            media_category=media_category,
            filename=file.filename,
        )
    except Exception as e:
        logger.exception("Analysis pipeline failed")
        raise HTTPException(
            status_code=500,
            detail=f"Analysis pipeline failed: {e}",
        )

    return result
