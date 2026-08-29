"""
Upload router for DeepTrace.
=============================
Defines the POST /upload endpoint for receiving image or video files.

This router will later be extended to trigger the analysis pipeline
after a file is successfully uploaded.
"""

from fastapi import APIRouter, File, UploadFile, HTTPException

from services.file_handler import (
    UploadError,
    validate_file,
    save_file,
    get_media_category,
)

router = APIRouter()

# Size limit constant (imported here for the error response too)
MAX_FILE_SIZE_MB = 100


@router.post("/upload", tags=["Media"])
async def upload_media(file: UploadFile = File(...)):
    """
    Upload an image or video file for analysis.

    **Supported formats:**
    - Images: JPEG, PNG, WebP, BMP, TIFF
    - Videos: MP4, MOV, AVI, WebM, MKV

    **Max file size:** 100 MB

    **Returns:** JSON with upload confirmation and file metadata.
    The `file_id` in the response can be used by future `/analyze` calls.
    """
    # ------------------------------------------------------------------
    # 1. Read the file content
    # ------------------------------------------------------------------
    # We read the full content into memory for validation and saving.
    # For very large files in production, streaming would be preferable.
    content = await file.read()
    file_size = len(content)

    # ------------------------------------------------------------------
    # 2. Validate the file
    # ------------------------------------------------------------------
    # Check type, size, and filename — raises UploadError on failure.
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
    try:
        saved = save_file(filename=file.filename, file_bytes=content)
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to save file to server: {e}",
        )

    # ------------------------------------------------------------------
    # 4. Build and return the response
    # ------------------------------------------------------------------
    # The response includes everything the frontend (and future /analyze)
    # needs to reference this file.
    media_category = get_media_category(file.content_type)

    return {
        "success": True,
        "message": "File uploaded successfully.",
        "file_id": saved["stored_name"],       # UUID-based ID for future use
        "filename": saved["original_name"],     # Original name from user
        "media_type": file.content_type,        # MIME type (e.g. "image/jpeg")
        "media_category": media_category,       # "image" or "video"
        "file_size": saved["file_size"],        # Size in bytes
        "file_size_mb": round(saved["file_size"] / (1024 * 1024), 2),
        "stored_path": saved["stored_path"],    # Server-side path (for /analyze)
    }
