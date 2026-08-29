"""
Analysis pipeline service for DeepTrace.
==========================================
Orchestrates the full analysis pipeline:
  Media Input -> OpenCV -> Frame Extraction -> Face Detection -> AI Inference -> Results

Replaces the mock pipeline with real processing.
"""

import datetime
import hashlib
import logging
import uuid
from pathlib import Path
from typing import Optional

import cv2
import numpy as np

logger = logging.getLogger(__name__)


def create_analysis_id() -> str:
    """Generate a unique analysis ID."""
    return uuid.uuid4().hex


def compute_file_hash(file_path: str) -> str:
    """Compute SHA-256 hash of a file."""
    sha256 = hashlib.sha256()
    with open(file_path, "rb") as f:
        for chunk in iter(lambda: f.read(8192), b""):
            sha256.update(chunk)
    return sha256.hexdigest()


def _format_duration(seconds: float) -> str:
    """Format seconds as 'MM:SS' or 'HH:MM:SS'."""
    total = int(seconds)
    h = total // 3600
    m = (total % 3600) // 60
    s = total % 60
    if h > 0:
        return f"{h:02d}:{m:02d}:{s:02d}"
    return f"{m:02d}:{s:02d}"


# ---------------------------------------------------------------------------
# Image analysis
# ---------------------------------------------------------------------------

def analyze_image(file_path: str) -> dict:
    """
    Full analysis pipeline for a single image.

    Steps:
      1. Read image with OpenCV
      2. Detect faces
      3. Crop faces
      4. Run AI inference on each face
      5. Aggregate results
    """
    from services.face_detector import detect_faces, crop_faces
    from services.ai_detector import get_detector

    # Read image
    img = cv2.imread(file_path, cv2.IMREAD_COLOR)
    if img is None:
        return {
            "status": "failed",
            "message": "Could not read image file.",
            "prediction": "Inconclusive",
            "score": 0,
        }

    h, w = img.shape[:2]

    # Detect faces
    faces = detect_faces(img)
    if not faces:
        return {
            "status": "completed",
            "message": "No face detected in the image. Unable to analyze for manipulation.",
            "prediction": "Inconclusive",
            "score": 0,
            "faces_detected": 0,
            "media_info": {"width": w, "height": h},
        }

    # Crop faces
    cropped = crop_faces(img, faces, padding=0.2)

    # Prepare face crops as RGB numpy arrays for the AI model
    face_crops_rgb = []
    face_boxes = []
    for c in cropped:
        crop_bgr = c["crop"]
        crop_rgb = cv2.cvtColor(crop_bgr, cv2.COLOR_BGR2RGB)
        face_crops_rgb.append(crop_rgb)
        face_boxes.append(list(c["bbox"]))

    # Run AI inference
    detector = get_detector()
    predictions = detector.predict_batch(face_crops_rgb)

    # Aggregate: take the highest manipulation score across all faces
    if predictions:
        scores = [p["manipulation_score"] for p in predictions]
        max_score = max(scores)
        avg_score = sum(scores) / len(scores)
        confidence_scores = [p["confidence"] for p in predictions]

        # Overall prediction based on max score
        if max_score >= 0.65:
            overall_prediction = "Likely Manipulated"
        elif max_score <= 0.35:
            overall_prediction = "Likely Authentic"
        else:
            overall_prediction = "Inconclusive"

        # Build per-face results
        face_results = []
        for i, (pred, box) in enumerate(zip(predictions, face_boxes)):
            face_results.append({
                "face_index": i,
                "bbox": box,
                "manipulation_score": pred["manipulation_score"],
                "prediction": pred["prediction"],
                "confidence": pred["confidence"],
            })
    else:
        max_score = 0.0
        avg_score = 0.0
        overall_prediction = "Inconclusive"
        face_results = []

    return {
        "status": "completed",
        "prediction": overall_prediction,
        "score": round(max_score * 100, 1),
        "manipulation_score": round(max_score, 4),
        "avg_manipulation_score": round(avg_score, 4),
        "faces_detected": len(predictions),
        "face_results": face_results,
        "media_info": {
            "width": w,
            "height": h,
            "format": Path(file_path).suffix.upper().lstrip("."),
        },
        "model": predictions[0]["model"] if predictions else "N/A",
        "model_version": predictions[0]["model_version"] if predictions else "N/A",
    }


# ---------------------------------------------------------------------------
# Video analysis
# ---------------------------------------------------------------------------

def analyze_video(file_path: str, max_frames: int = 30) -> dict:
    """
    Full analysis pipeline for a video.

    Steps:
      1. Extract video metadata
      2. Sample frames (configurable)
      3. For each frame: detect faces -> crop -> AI inference
      4. Aggregate frame-level results into video-level result
      5. Identify suspicious frames and segments
    """
    from services.media_processor import read_video_info, extract_frames
    from services.face_detector import process_video_frames_for_ai
    from services.ai_detector import get_detector

    # Get video metadata
    try:
        video_info = read_video_info(file_path)
    except Exception as e:
        return {
            "status": "failed",
            "message": f"Could not read video: {e}",
            "prediction": "Inconclusive",
            "score": 0,
        }

    duration = video_info["duration"]
    fps = video_info["fps"]
    total_frames = video_info["frame_count"]

    # Calculate frames to sample: aim for ~max_frames evenly spaced
    # Don't exceed total frames or a reasonable processing time
    sample_count = min(max_frames, total_frames)
    if sample_count <= 0:
        return {
            "status": "failed",
            "message": "Video has no readable frames.",
            "prediction": "Inconclusive",
            "score": 0,
        }

    # Extract frames
    try:
        import tempfile
        import shutil
        tmp_dir = tempfile.mkdtemp(prefix="dt_frames_")
        extract_result = extract_frames(
            file_path,
            output_dir=tmp_dir,
            max_frames=sample_count,
        )
        frames = extract_result["frames"]
    except Exception as e:
        return {
            "status": "failed",
            "message": f"Frame extraction failed: {e}",
            "prediction": "Inconclusive",
            "score": 0,
        }

    if not frames:
        return {
            "status": "failed",
            "message": "No frames could be extracted from the video.",
            "prediction": "Inconclusive",
            "score": 0,
        }

    # Process each frame through face detection + AI inference
    frame_results = []
    detector = get_detector()
    total_faces = 0

    for frame_info in frames:
        frame_path = frame_info["path"]
        frame_number = frame_info["frame_number"]
        timestamp = frame_info["timestamp"]

        # Read frame
        img = cv2.imread(frame_path, cv2.IMREAD_COLOR)
        if img is None:
            continue

        # Detect faces in this frame
        from services.face_detector import detect_faces, crop_faces
        faces = detect_faces(img)

        if not faces:
            frame_results.append({
                "frame_number": frame_number,
                "timestamp": timestamp,
                "timestamp_fmt": _format_duration(timestamp),
                "faces_found": 0,
                "manipulation_score": 0.0,
                "prediction": "No face detected",
                "face_boxes": [],
            })
            continue

        total_faces += len(faces)

        # Crop and preprocess faces
        cropped = crop_faces(img, faces, padding=0.2)
        face_crops_rgb = []
        face_boxes = []
        for c in cropped:
            crop_rgb = cv2.cvtColor(c["crop"], cv2.COLOR_BGR2RGB)
            face_crops_rgb.append(crop_rgb)
            face_boxes.append(list(c["bbox"]))

        # Run AI inference on all faces in this frame
        predictions = detector.predict_batch(face_crops_rgb)

        # Aggregate frame score: max across faces
        if predictions:
            scores = [p["manipulation_score"] for p in predictions]
            frame_score = max(scores)
            if frame_score >= 0.65:
                frame_pred = "Likely Manipulated"
            elif frame_score <= 0.35:
                frame_pred = "Likely Authentic"
            else:
                frame_pred = "Inconclusive"
        else:
            frame_score = 0.0
            frame_pred = "Inconclusive"

        frame_results.append({
            "frame_number": frame_number,
            "timestamp": timestamp,
            "timestamp_fmt": _format_duration(timestamp),
            "faces_found": len(predictions),
            "manipulation_score": round(frame_score, 4),
            "prediction": frame_pred,
            "face_boxes": face_boxes,
        })

    # Cleanup extracted frames
    try:
        shutil.rmtree(tmp_dir, ignore_errors=True)
    except Exception:
        pass

    # -----------------------------------------------------------------------
    # Video-level aggregation
    # -----------------------------------------------------------------------
    scored_frames = [f for f in frame_results if f["faces_found"] > 0]

    if not scored_frames:
        return {
            "status": "completed",
            "message": "No faces detected in any sampled frame.",
            "prediction": "Inconclusive",
            "score": 0,
            "frames_analyzed": len(frame_results),
            "faces_detected": 0,
            "frame_results": frame_results,
            "suspicious_frames": [],
            "suspicious_segments": [],
            "media_info": {
                "duration": duration,
                "duration_fmt": _format_duration(duration),
                "fps": fps,
                "total_frames": total_frames,
                "resolution": f"{video_info['width']}x{video_info['height']}",
                "codec": video_info.get("codec", "unknown"),
            },
        }

    scores = [f["manipulation_score"] for f in scored_frames]

    # Aggregation strategies
    avg_score = sum(scores) / len(scores)
    max_score = max(scores)

    # Weighted average: give more weight to high-scoring frames
    # This makes the final score more sensitive to suspicious segments
    sorted_scores = sorted(scores, reverse=True)
    top_k = max(3, len(sorted_scores) // 3)
    top_avg = sum(sorted_scores[:top_k]) / min(top_k, len(sorted_scores))

    # Final score: blend of average and top-k average
    # 60% average + 40% top-k average
    final_score = 0.6 * avg_score + 0.4 * top_avg

    # Overall prediction
    if final_score >= 0.65:
        overall_prediction = "Likely Manipulated"
    elif final_score <= 0.35:
        overall_prediction = "Likely Authentic"
    else:
        overall_prediction = "Inconclusive"

    # Identify suspicious frames (score > 0.6)
    suspicious_threshold = 0.6
    suspicious_frames = [
        {
            "frame": f["frame_number"],
            "timestamp": f["timestamp"],
            "timestamp_fmt": f["timestamp_fmt"],
            "score": f["manipulation_score"],
        }
        for f in scored_frames
        if f["manipulation_score"] >= suspicious_threshold
    ]

    # Group consecutive suspicious frames into segments
    suspicious_segments = []
    if suspicious_frames:
        seg_start = suspicious_frames[0]["timestamp"]
        seg_end = suspicious_frames[0]["timestamp"]
        for sf in suspicious_frames[1:]:
            # If gap is less than 2 seconds, extend the segment
            if sf["timestamp"] - seg_end < 2.0:
                seg_end = sf["timestamp"]
            else:
                suspicious_segments.append({
                    "start": round(seg_start, 2),
                    "end": round(seg_end, 2),
                    "start_fmt": _format_duration(seg_start),
                    "end_fmt": _format_duration(seg_end),
                })
                seg_start = sf["timestamp"]
                seg_end = sf["timestamp"]
        # Close last segment
        suspicious_segments.append({
            "start": round(seg_start, 2),
            "end": round(seg_end, 2),
            "start_fmt": _format_duration(seg_start),
            "end_fmt": _format_duration(seg_end),
        })

    # Findings
    findings = []
    if suspicious_frames:
        findings.append({
            "description": f"{len(suspicious_frames)} frame(s) flagged with high manipulation scores",
            "severity": "critical" if len(suspicious_frames) > 3 else "warning",
        })
    if suspicious_segments:
        for seg in suspicious_segments:
            findings.append({
                "description": f"Suspicious segment: {seg['start_fmt']} - {seg['end_fmt']}",
                "severity": "critical",
            })
    if avg_score > 0.5:
        findings.append({
            "description": f"Average frame manipulation score ({avg_score:.0%}) is elevated",
            "severity": "warning",
        })

    # Media info
    media_info = {
        "duration": duration,
        "duration_fmt": _format_duration(duration),
        "fps": fps,
        "total_frames": total_frames,
        "resolution": f"{video_info['width']}x{video_info['height']}",
        "codec": video_info.get("codec", "unknown"),
    }

    return {
        "status": "completed",
        "prediction": overall_prediction,
        "score": round(final_score * 100, 1),
        "manipulation_score": round(final_score, 4),
        "avg_manipulation_score": round(avg_score, 4),
        "max_frame_score": round(max_score, 4),
        "frames_analyzed": len(scored_frames),
        "total_frames_sampled": len(frame_results),
        "faces_detected": total_faces,
        "frame_results": frame_results,
        "suspicious_frames": suspicious_frames,
        "suspicious_segments": suspicious_segments,
        "findings": findings,
        "media_info": media_info,
        "aggregation": {
            "method": "weighted_average",
            "description": "60% average + 40% top-k average across scored frames",
            "raw_avg": round(avg_score, 4),
            "top_k_avg": round(top_avg, 4),
        },
    }


# ---------------------------------------------------------------------------
# Main pipeline entry point
# ---------------------------------------------------------------------------

async def run_analysis_pipeline(
    file_path: str,
    media_type: str,
    media_category: str,
    filename: str = "",
) -> dict:
    """
    Main entry point for the analysis pipeline.

    Routes to image or video analysis based on media category.
    Returns a standardized response with analysis_id, status, results, etc.
    """
    analysis_id = create_analysis_id()
    file_hash = compute_file_hash(file_path)
    file_size = Path(file_path).stat().st_size

    try:
        if media_category == "image":
            results = analyze_image(file_path)
        elif media_category == "video":
            results = analyze_video(file_path)
        else:
            results = {
                "status": "failed",
                "message": f"Unsupported media category: {media_category}",
                "prediction": "Inconclusive",
                "score": 0,
            }
    except Exception as e:
        logger.error("Analysis failed for %s: %s", file_path, e)
        results = {
            "status": "failed",
            "message": f"Analysis pipeline error: {e}",
            "prediction": "Inconclusive",
            "score": 0,
        }

    return {
        "analysis_id": analysis_id,
        "status": results.get("status", "failed"),
        "media_type": media_type,
        "media_category": media_category,
        "filename": filename,
        "prediction": results.get("prediction", "Inconclusive"),
        "score": results.get("score", 0),
        "message": results.get("message", ""),
        "faces_detected": results.get("faces_detected", 0),
        "frames_analyzed": results.get("frames_analyzed", 0),
        "suspicious_frames": results.get("suspicious_frames", []),
        "suspicious_segments": results.get("suspicious_segments", []),
        "findings": results.get("findings", []),
        "media_info": results.get("media_info", {}),
        "face_results": results.get("face_results", []),
        "frame_results": results.get("frame_results", []),
        "aggregation": results.get("aggregation", {}),
        "file_hash": file_hash,
        "file_size": file_size,
        "file_size_mb": round(file_size / (1024 * 1024), 2),
        "model": results.get("model", "EfficientNet-B4"),
        "model_version": results.get("model_version", "1.0.0"),
        "timestamp": datetime.datetime.now(datetime.timezone.utc).isoformat(),
    }
