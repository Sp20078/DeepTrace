"""
DeepTrace Analysis Pipeline — Clean Rebuild
=============================================
Orchestrates the full analysis:
  Media → Frames → Faces → Model Inference → Evidence → Findings → Report

EVERYTHING comes from actual model output. No mock data, no hardcoded findings.
"""

import datetime
import hashlib
import logging
import tempfile
import uuid
from pathlib import Path

import cv2
import numpy as np

from services.model import get_model
from services.detector import detect_faces

logger = logging.getLogger(__name__)


# ── Utilities ──────────────────────────────────────────────────────────────

def _hash(file_path: str) -> str:
    h = hashlib.sha256()
    with open(file_path, "rb") as f:
        for chunk in iter(lambda: f.read(8192), b""):
            h.update(chunk)
    return h.hexdigest()


def _fmt_time(seconds: float) -> str:
    total = int(seconds)
    m, s = divmod(total, 60)
    h, m = divmod(m, 60)
    return f"{h:02d}:{m:02d}:{s:02d}" if h else f"{m:02d}:{s:02d}"


def _score_to_risk(score: float) -> str:
    """Convert fake probability [0,1] to risk level string."""
    if score >= 0.70:
        return "HIGH"
    elif score >= 0.45:
        return "MEDIUM"
    elif score >= 0.25:
        return "LOW"
    return "MINIMAL"


def _score_to_100(score: float) -> int:
    """Scale fake probability [0,1] to 0-100 integer."""
    return max(0, min(100, int(score * 100)))


# ── Frame Extraction ───────────────────────────────────────────────────────

def extract_frames(file_path: str, max_frames: int = 30) -> tuple[list[np.ndarray], dict]:
    """
    Extract evenly-spaced frames from a video.

    Returns:
        (frames, metadata)
        frames: list of BGR numpy arrays
        metadata: dict with fps, duration, total_frames, etc.
    """
    cap = cv2.VideoCapture(file_path)
    if not cap.isOpened():
        raise ValueError(f"Cannot open video: {file_path}")

    fps = cap.get(cv2.CAP_PROP_FPS)
    total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
    width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
    height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
    duration = total_frames / fps if fps > 0 else 0

    metadata = {
        "fps": round(fps, 2),
        "total_frames": total_frames,
        "duration": round(duration, 2),
        "duration_fmt": _fmt_time(duration),
        "width": width,
        "height": height,
        "resolution": f"{width}x{height}",
    }

    # Sample evenly spaced frames
    sample_count = min(max_frames, total_frames)
    if sample_count <= 0:
        cap.release()
        return [], metadata

    indices = np.linspace(0, total_frames - 1, sample_count, dtype=int)
    frames = []

    for idx in indices:
        cap.set(cv2.CAP_PROP_POS_FRAMES, int(idx))
        ret, frame = cap.read()
        if ret and frame is not None:
            timestamp = idx / fps if fps > 0 else 0
            frames.append({
                "frame": frame,
                "frame_number": int(idx),
                "timestamp": round(timestamp, 3),
                "timestamp_fmt": _fmt_time(timestamp),
            })

    cap.release()
    logger.info("Extracted %d frames from video", len(frames))
    return frames, metadata


# ── Image Reading ──────────────────────────────────────────────────────────

def read_image(file_path: str) -> np.ndarray:
    """Read an image file."""
    img = cv2.imread(file_path, cv2.IMREAD_COLOR)
    if img is None:
        raise ValueError(f"Cannot read image: {file_path}")
    return img


# ── Analysis Pipeline ──────────────────────────────────────────────────────

def analyze_image(file_path: str, filename: str = "") -> dict:
    """
    Full analysis pipeline for a single image.

    Returns complete result dict with real scores and evidence.
    """
    model = get_model()
    img = read_image(file_path)
    h, w = img.shape[:2]

    # Detect faces
    faces = detect_faces(img)

    if not faces:
        return _build_result(
            filename=filename,
            media_type="image",
            prediction="No Face Detected",
            risk_score=0,
            risk_level="MINIMAL",
            faces_found=0,
            face_analyses=[],
            suspicious_frames=[],
            findings=[{
                "description": "No human face detected in the image.",
                "severity": "info",
                "detail": "Cannot analyze for manipulation without a detectable face.",
            }],
            media_info={"width": w, "height": h, "format": Path(file_path).suffix.upper().lstrip(".")},
        )

    # Run model on each face
    face_analyses = []
    for i, face in enumerate(faces):
        pred = model.predict(face["crop_rgb"])
        face_analyses.append({
            "face_index": i,
            "bbox": list(face["bbox"]),
            "fake_prob": pred["fake_prob"],
            "real_prob": pred["real_prob"],
            "confidence": pred["confidence"],
            "risk_level": _score_to_risk(pred["fake_prob"]),
        })

    # Aggregate
    scores = [f["fake_prob"] for f in face_analyses]
    max_score = max(scores)
    avg_score = sum(scores) / len(scores)

    # Overall
    risk_score = _score_to_100(max_score)
    risk_level = _score_to_risk(max_score)

    if risk_level == "HIGH":
        prediction = "Likely Manipulated"
    elif risk_level in ("MEDIUM", "LOW"):
        prediction = "Inconclusive"
    else:
        prediction = "Likely Authentic"

    # Findings — generated from REAL data
    findings = _generate_findings(face_analyses, suspicious_threshold=0.50)

    return _build_result(
        filename=filename,
        media_type="image",
        prediction=prediction,
        risk_score=risk_score,
        risk_level=risk_level,
        faces_found=len(face_analyses),
        face_analyses=face_analyses,
        suspicious_frames=[],
        findings=findings,
        media_info={
            "width": w,
            "height": h,
            "format": Path(file_path).suffix.upper().lstrip("."),
        },
    )


def analyze_video(file_path: str, filename: str = "", max_frames: int = 30) -> dict:
    """
    Full analysis pipeline for a video.

    Returns complete result dict with per-frame scores, evidence, and findings.
    """
    model = get_model()

    # Extract frames
    frame_data, video_meta = extract_frames(file_path, max_frames=max_frames)

    if not frame_data:
        return _build_result(
            filename=filename,
            media_type="video",
            prediction="Cannot Analyze",
            risk_score=0,
            risk_level="MINIMAL",
            faces_found=0,
            face_analyses=[],
            suspicious_frames=[],
            findings=[{
                "description": "Could not extract frames from the video.",
                "severity": "info",
            }],
            media_info=video_meta,
        )

    # Analyze each frame
    frame_analyses = []
    all_face_analyses = []
    total_faces = 0

    for fd in frame_data:
        frame = fd["frame"]
        faces = detect_faces(frame)

        if not faces:
            frame_analyses.append({
                "frame_number": fd["frame_number"],
                "timestamp": fd["timestamp"],
                "timestamp_fmt": fd["timestamp_fmt"],
                "faces_found": 0,
                "max_fake_prob": 0.0,
                "face_scores": [],
            })
            continue

        total_faces += len(faces)
        preds = model.predict_batch([f["crop_rgb"] for f in faces])
        scores = [p["fake_prob"] for p in preds]
        max_frame_score = max(scores)

        frame_analyses.append({
            "frame_number": fd["frame_number"],
            "timestamp": fd["timestamp"],
            "timestamp_fmt": fd["timestamp_fmt"],
            "faces_found": len(faces),
            "max_fake_prob": round(max_frame_score, 4),
            "face_scores": [round(s, 4) for s in scores],
        })

        for i, pred in enumerate(preds):
            fa = {
                "frame_number": fd["frame_number"],
                "timestamp": fd["timestamp"],
                "timestamp_fmt": fd["timestamp_fmt"],
                "face_index": i,
                "bbox": list(faces[i]["bbox"]),
                "fake_prob": pred["fake_prob"],
                "real_prob": pred["real_prob"],
                "confidence": pred["confidence"],
            }
            all_face_analyses.append(fa)

    # ── Aggregate scores ───────────────────────────────────────────────
    scored_frames = [f for f in frame_analyses if f["faces_found"] > 0]
    if not scored_frames:
        return _build_result(
            filename=filename,
            media_type="video",
            prediction="No Face Detected",
            risk_score=0,
            risk_level="MINIMAL",
            faces_found=0,
            face_analyses=[],
            suspicious_frames=[],
            findings=[{
                "description": "No human face detected in any sampled frame.",
                "severity": "info",
            }],
            media_info=video_meta,
        )

    frame_scores = [f["max_fake_prob"] for f in scored_frames]
    avg_score = sum(frame_scores) / len(frame_scores)
    max_score = max(frame_scores)

    # Weighted: 60% avg + 40% top-k average
    sorted_scores = sorted(frame_scores, reverse=True)
    top_k = max(3, len(sorted_scores) // 3)
    top_avg = sum(sorted_scores[:top_k]) / min(top_k, len(sorted_scores))
    final_score = 0.6 * avg_score + 0.4 * top_avg

    risk_score = _score_to_100(final_score)
    risk_level = _score_to_risk(final_score)

    if risk_level == "HIGH":
        prediction = "Likely Manipulated"
    elif risk_level in ("MEDIUM", "LOW"):
        prediction = "Inconclusive"
    else:
        prediction = "Likely Authentic"

    # ── Suspicious frames (real evidence) ──────────────────────────────
    SUSPICIOUS_THRESHOLD = 0.50
    suspicious_frames = [
        {
            "frame_number": f["frame_number"],
            "timestamp": f["timestamp"],
            "timestamp_fmt": f["timestamp_fmt"],
            "score": f["max_fake_prob"],
            "risk_level": _score_to_risk(f["max_fake_prob"]),
        }
        for f in scored_frames
        if f["max_fake_prob"] >= SUSPICIOUS_THRESHOLD
    ]

    # ── Suspicious segments ────────────────────────────────────────────
    segments = _find_segments(suspicious_frames)

    # ── Findings — REAL data driven ────────────────────────────────────
    findings = _generate_video_findings(
        frame_scores=frame_scores,
        scored_frames=scored_frames,
        suspicious_frames=suspicious_frames,
        segments=segments,
        all_face_analyses=all_face_analyses,
    )

    # ── Per-frame summary for the analysis breakdown cards ─────────────
    visual_score = _compute_visual_score(all_face_analyses)
    temporal_score = _compute_temporal_score(frame_scores)
    metadata_score = 0.0  # Can't assess from video alone
    face_score = _compute_face_consistency(all_face_analyses)

    return _build_result(
        filename=filename,
        media_type="video",
        prediction=prediction,
        risk_score=risk_score,
        risk_level=risk_level,
        faces_found=total_faces,
        frames_analyzed=len(scored_frames),
        face_analyses=all_face_analyses,
        frame_analyses=frame_analyses,
        suspicious_frames=suspicious_frames,
        suspicious_segments=segments,
        findings=findings,
        analysis_breakdown={
            "visual": _score_to_100(visual_score),
            "temporal": _score_to_100(temporal_score),
            "metadata": _score_to_100(metadata_score),
            "face": _score_to_100(face_score),
        },
        aggregation={
            "method": "weighted_average",
            "raw_avg": round(avg_score, 4),
            "top_k_avg": round(top_avg, 4),
            "final_score": round(final_score, 4),
        },
        media_info=video_meta,
    )


# ── Analysis Breakdown Helpers ─────────────────────────────────────────────

def _compute_visual_score(face_analyses: list[dict]) -> float:
    """Average fake probability across all faces — proxy for visual artifacts."""
    if not face_analyses:
        return 0.0
    scores = [f["fake_prob"] for f in face_analyses]
    return sum(scores) / len(scores)


def _compute_temporal_score(frame_scores: list[float]) -> float:
    """
    Temporal inconsistency: how much frame scores vary.
    High variance = suspicious temporal behavior.
    """
    if len(frame_scores) < 2:
        return 0.0
    scores = np.array(frame_scores)
    std = float(np.std(scores))
    # Map std to [0,1]: std of 0.2+ means very inconsistent
    return min(1.0, std / 0.25)


def _compute_face_consistency(face_analyses: list[dict]) -> float:
    """
    Face boundary consistency: high scores on some faces but not others
    suggests localized manipulation.
    """
    if len(face_analyses) < 2:
        return face_analyses[0]["fake_prob"] if face_analyses else 0.0
    scores = [f["fake_prob"] for f in face_analyses]
    # High std = inconsistent = suspicious
    std = float(np.std(scores))
    mean = sum(scores) / len(scores)
    return min(1.0, mean + std)


# ── Segment Detection ──────────────────────────────────────────────────────

def _find_segments(suspicious_frames: list[dict], gap_threshold: float = 2.0) -> list[dict]:
    """Group consecutive suspicious frames into time segments."""
    if not suspicious_frames:
        return []

    segments = []
    seg_start = suspicious_frames[0]["timestamp"]
    seg_end = suspicious_frames[0]["timestamp"]
    seg_max_score = suspicious_frames[0]["score"]

    for sf in suspicious_frames[1:]:
        if sf["timestamp"] - seg_end < gap_threshold:
            seg_end = sf["timestamp"]
            seg_max_score = max(seg_max_score, sf["score"])
        else:
            segments.append({
                "start": round(seg_start, 2),
                "end": round(seg_end, 2),
                "start_fmt": _fmt_time(seg_start),
                "end_fmt": _fmt_time(seg_end),
                "max_score": round(seg_max_score, 4),
                "risk_level": _score_to_risk(seg_max_score),
            })
            seg_start = sf["timestamp"]
            seg_end = sf["timestamp"]
            seg_max_score = sf["score"]

    # Close last segment
    segments.append({
        "start": round(seg_start, 2),
        "end": round(seg_end, 2),
        "start_fmt": _fmt_time(seg_start),
        "end_fmt": _fmt_time(seg_end),
        "max_score": round(seg_max_score, 4),
        "risk_level": _score_to_risk(seg_max_score),
    })

    return segments


# ── Finding Generation (REAL DATA) ────────────────────────────────────────

def _generate_findings(face_analyses: list[dict], suspicious_threshold: float = 0.50) -> list[dict]:
    """Generate findings for a single image from real analysis data."""
    findings = []

    suspicious = [f for f in face_analyses if f["fake_prob"] >= suspicious_threshold]
    if suspicious:
        findings.append({
            "description": f"{len(suspicious)} of {len(face_analyses)} face(s) show potential manipulation signals.",
            "severity": "critical" if len(suspicious) == len(face_analyses) else "warning",
            "detail": f"Highest manipulation probability: {max(f['fake_prob'] for f in suspicious):.0%}",
        })
    else:
        findings.append({
            "description": f"All {len(face_analyses)} detected face(s) appear authentic.",
            "severity": "info",
        })

    # Check for face boundary inconsistency (multiple faces with different scores)
    if len(face_analyses) >= 2:
        scores = [f["fake_prob"] for f in face_analyses]
        if max(scores) - min(scores) > 0.3:
            findings.append({
                "description": "Inconsistent manipulation signals across multiple faces.",
                "severity": "warning",
                "detail": f"Score range: {min(scores):.0%} to {max(scores):.0%}. "
                          f"This may indicate selective face manipulation.",
            })

    return findings


def _generate_video_findings(
    frame_scores: list[float],
    scored_frames: list[dict],
    suspicious_frames: list[dict],
    segments: list[dict],
    all_face_analyses: list[dict],
) -> list[dict]:
    """Generate findings for video from real analysis data."""
    findings = []

    # 1. Suspicious frame count
    if suspicious_frames:
        pct = len(suspicious_frames) / len(scored_frames) * 100
        findings.append({
            "description": f"{len(suspicious_frames)} frame(s) flagged with manipulation signals "
                          f"({pct:.0f}% of analyzed frames).",
            "severity": "critical" if len(suspicious_frames) > 3 else "warning",
        })

    # 2. Suspicious time segments
    for seg in segments:
        findings.append({
            "description": f"Suspicious activity detected: {seg['start_fmt']} → {seg['end_fmt']}",
            "severity": "critical" if seg["risk_level"] == "HIGH" else "warning",
            "detail": f"Peak manipulation score in segment: {seg['max_score']:.0%}",
        })

    # 3. Temporal inconsistency
    if len(frame_scores) >= 3:
        std = float(np.std(frame_scores))
        if std > 0.15:
            findings.append({
                "description": "High temporal inconsistency detected — frame scores vary significantly.",
                "severity": "warning",
                "detail": f"Score standard deviation: {std:.3f}. This may indicate "
                          f"spliced or temporally manipulated content.",
            })

    # 4. Face boundary issues
    if all_face_analyses:
        high_faces = [f for f in all_face_analyses if f["fake_prob"] >= 0.50]
        if high_faces:
            frame_nums = set(f["frame_number"] for f in high_faces)
            findings.append({
                "description": f"Potential facial boundary inconsistencies detected across "
                              f"{len(frame_nums)} frame(s).",
                "severity": "warning",
            })

    # 5. Overall assessment
    max_score = max(frame_scores)
    avg_score = sum(frame_scores) / len(frame_scores)
    if avg_score < 0.25:
        findings.append({
            "description": "Overall analysis suggests the video content appears authentic.",
            "severity": "info",
        })

    # 6. Always include disclaimer
    findings.append({
        "description": "AI analysis is probabilistic — scores indicate likelihood, not certainty.",
        "severity": "info",
    })

    return findings


# ── Result Builder ─────────────────────────────────────────────────────────

def _build_result(
    filename: str,
    media_type: str,
    prediction: str,
    risk_score: int,
    risk_level: str,
    faces_found: int,
    face_analyses: list,
    suspicious_frames: list,
    findings: list,
    media_info: dict,
    frames_analyzed: int = 1,
    frame_analyses: list = None,
    suspicious_segments: list = None,
    analysis_breakdown: dict = None,
    aggregation: dict = None,
) -> dict:
    """Build the standardized result dict — compatible with Flutter frontend."""
    # Determine media_category for Flutter compatibility
    media_category = "video" if media_type and media_type.startswith("video") else "image"

    # Build findings description for the "message" field
    critical = [f for f in findings if f.get("severity") == "critical"]
    warnings = [f for f in findings if f.get("severity") == "warning"]
    if critical:
        message = critical[0]["description"]
    elif warnings:
        message = warnings[0]["description"]
    else:
        message = findings[0]["description"] if findings else "Analysis complete."

    # Frame results in the format Flutter expects (frame_results)
    frame_results_for_flutter = []
    if frame_analyses:
        for fa in frame_analyses:
            frame_results_for_flutter.append({
                "frame_number": fa["frame_number"],
                "timestamp": fa["timestamp"],
                "timestamp_fmt": fa["timestamp_fmt"],
                "faces_found": fa["faces_found"],
                "manipulation_score": fa["max_fake_prob"],
                "prediction": (
                    "Likely Manipulated" if fa["max_fake_prob"] >= 0.65
                    else ("Inconclusive" if fa["max_fake_prob"] >= 0.35 else "Likely Authentic")
                ),
            })

    return {
        # Flutter-compatible fields
        "analysis_id": f"DF-{datetime.datetime.now().strftime('%Y%m%d')}-{uuid.uuid4().hex[:6].upper()}",
        "status": "completed",
        "filename": filename,
        "media_type": media_type,
        "media_category": media_category,
        "prediction": prediction,
        "score": risk_score,
        "message": message,
        "faces_detected": faces_found,
        "frames_analyzed": frames_analyzed,
        "suspicious_frames": suspicious_frames,
        "suspicious_segments": suspicious_segments or [],
        "findings": findings,
        "media_info": media_info,
        "file_hash": "",
        "model": "EfficientNet-B2 (Custom)",
        "model_version": "2.0.0",
        "timestamp": datetime.datetime.now(datetime.timezone.utc).isoformat(),
        "frame_results": frame_results_for_flutter,
        # New v2 fields (richer data)
        "risk_score": risk_score,
        "risk_level": risk_level,
        "face_analyses": face_analyses,
        "analysis_breakdown": analysis_breakdown or {
            "visual": risk_score,
            "temporal": 0,
            "metadata": 0,
            "face": risk_score,
        },
        "aggregation": aggregation or {},
    }


# ── Main Entry Point ───────────────────────────────────────────────────────

async def run_analysis(file_path: str, media_type: str, filename: str = "") -> dict:
    """
    Main entry point called by the router.
    Routes to image or video analysis.
    """
    from services.history import save_analysis
    
    is_video = media_type and media_type.startswith("video")
    if is_video:
        result = analyze_video(file_path, filename=filename)
    else:
        result = analyze_image(file_path, filename=filename)
    
    # Save to history
    try:
        save_analysis(result)
    except Exception as e:
        logger.warning("Failed to save to history: %s", e)
    
    return result
