"""
Analysis router for DeepTrace.
================================
Defines the POST /analyze endpoint for running forensic analysis.

This endpoint accepts a media file, validates it, saves it, and
kicks off the analysis pipeline (currently mock; will become real
OpenCV + AI in future phases).
"""

from fastapi import APIRouter, File, UploadFile, HTTPException

from services.file_handler import (
    UploadError,
    validate_file,
    save_file,
    get_media_category,
)
from services.analysis import run_analysis_pipeline

router = APIRouter()


@router.post("/analyze", tags=["Analysis"])
async def analyze_media(file: UploadFile = File(...)):
    """
    Upload and analyze an image or video for deepfake detection.

    **This endpoint combines upload + analysis in a single call.**

    **Supported formats:**
    - Images: JPEG, PNG, WebP, BMP, TIFF
    - Videos: MP4, MOV, AVI, WebM, MKV

    **Max file size:** 100 MB

    **Returns:** JSON with analysis results including risk score,
    component breakdowns, and evidence flags.
    """
    # ------------------------------------------------------------------
    # 1. Read the uploaded file
    # ------------------------------------------------------------------
    content = await file.read()
    file_size = len(content)

    # ------------------------------------------------------------------
    # 2. Validate the file (reuse the same validation as /upload)
    # ------------------------------------------------------------------
    try:
        validate_file(
            content_type=file.content_type,
            file_size=file_size,
            filename=file.filename,
        )
    except UploadError as e:
        raise HTTPException(status_code=400, detail=str(e))

    # ------------------------------------------------------------------
    # 3. Save the file to disk
    # ------------------------------------------------------------------
    # The analysis pipeline needs a file path to read from.
    try:
        saved = save_file(filename=file.filename, file_bytes=content)
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to save file: {e}",
        )

    # ------------------------------------------------------------------
    # 4. Run the analysis pipeline
    # ------------------------------------------------------------------
    # This is where the real OpenCV + AI pipeline will plug in.
    # Currently it runs the mock analysis.
    try:
        media_category = get_media_category(file.content_type)
        result = await run_analysis_pipeline(
            file_path=saved["stored_path"],
            media_type=file.content_type,
            media_category=media_category,
        )
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Analysis pipeline failed: {e}",
        )

    # ------------------------------------------------------------------
    # 5. Return the analysis result
    # ------------------------------------------------------------------
    # The response shape is stable — the frontend can rely on these
    # fields regardless of whether the pipeline is mock or real.
    return result
