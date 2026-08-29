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


class FrameExtractionError(MediaError):
    """Raised when frame extraction fails."""
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
# Frame extraction
# ---------------------------------------------------------------------------

# Default output directory for extracted frames (relative to this file)
FRAME_OUTPUT_DIR = Path(__file__).resolve().parent.parent / "uploads" / "frames"

# Safety limit: never extract more than this many frames from a single video
MAX_FRAMES = 500


def extract_frames(
    file_path: str,
    output_dir: Optional[str] = None,
    fps: Optional[float] = None,
    interval: Optional[float] = None,
    max_frames: Optional[int] = None,
) -> dict:
    """
    Extract frames from a video with configurable sampling.

    Provides three mutually exclusive sampling strategies:

      1. fps  (float)       -- Extract this many frames per second.
         E.g. fps=2 extracts 2 frames every second.

      2. interval (float)  -- Extract one frame every N seconds.
         E.g. interval=0.5 extracts one frame every 0.5s (= 2 fps).
         interval and fps are inverses; specifying both raises an error.

      3. max_frames (int)  -- Extract exactly N frames, evenly spaced
         across the entire video duration.

    If none is specified, defaults to 1 frame per second.

    Args:
        file_path:   Path to the video file.
        output_dir:  Where to save frame images. If None, a directory
                     is created automatically under uploads/frames/.
        fps:         Frames per second to extract.
        interval:    Seconds between extracted frames.
        max_frames:  Total number of frames to extract (evenly spaced).

    Returns:
        A dict with:
          - video_path:       original video path
          - output_dir:       directory where frames were saved
          - total_frames:     number of frames extracted
          - video_duration:   duration of source video in seconds
          - video_fps:        FPS of source video
          - video_resolution: "WIDTHxHEIGHT"
          - sampling_method:  which strategy was used
          - sampling_value:   the parameter value used
          - frames:           list of frame metadata dicts

    Raises:
        MediaError: on invalid input or if the video cannot be read.
    """
    # --- Validate inputs ---
    if fps is not None and interval is not None:
        raise MediaError(
            "Cannot specify both 'fps' and 'interval'. "
            "They are inverse of each other — use one or the other."
        )

    if fps is not None and fps <= 0:
        raise MediaError(f"fps must be positive, got {fps}")

    if interval is not None and interval <= 0:
        raise MediaError(f"interval must be positive, got {interval}")

    if max_frames is not None and max_frames <= 0:
        raise MediaError(f"max_frames must be positive, got {max_frames}")

    # --- Get video metadata (also validates the file) ---
    video_info = read_video_info(file_path)
    video_fps = video_info["fps"]
    total_video_frames = video_info["frame_count"]
    duration = video_info["duration"]

    if video_fps <= 0 or total_video_frames <= 0:
        raise MediaError("Video has no readable frames.")

    # --- Determine sampling strategy ---
    if fps is not None:
        sampling_method = "fps"
        sampling_value = fps
        # Number of frames to extract per second
        target_fps = fps
    elif interval is not None:
        sampling_method = "interval"
        sampling_value = interval
        target_fps = 1.0 / interval
    elif max_frames is not None:
        sampling_method = "max_frames"
        sampling_value = max_frames
        # Evenly space max_frames across the full duration
        target_fps = max_frames / duration if duration > 0 else 1.0
    else:
        # Default: 1 frame per second
        sampling_method = "fps"
        sampling_value = 1.0
        target_fps = 1.0

    # Calculate which frame numbers to extract
    # We work in terms of source-video frame numbers.
    frame_numbers = _calculate_frame_numbers(
        total_video_frames=total_video_frames,
        source_fps=video_fps,
        target_fps=target_fps,
    )

    # Apply safety limit
    if len(frame_numbers) > MAX_FRAMES:
        logger.warning(
            "Calculated %d frames exceeds limit of %d. Truncating.",
            len(frame_numbers), MAX_FRAMES,
        )
        # Re-sample evenly to stay within limit
        frame_numbers = _evenly_space(len(frame_numbers), MAX_FRAMES,
                                       frame_numbers)

    # --- Set up output directory ---
    if output_dir is not None:
        out_dir = Path(output_dir)
    else:
        # Create a unique subdirectory based on the video filename
        video_stem = Path(file_path).stem
        out_dir = FRAME_OUTPUT_DIR / video_stem

    out_dir.mkdir(parents=True, exist_ok=True)

    # --- Extract frames ---
    cap = cv2.VideoCapture(str(file_path))
    if not cap.isOpened():
        raise MediaError(f"Could not open video for frame extraction: {file_path}")

    extracted_frames = []
    try:
        frame_idx = 0
        target_set = set(frame_numbers)
        target_pos = 0  # pointer into frame_numbers

        while cap.isOpened() and target_pos < len(frame_numbers):
            ret, frame = cap.read()
            if not ret:
                break

            # Check if this is one of the frames we want
            if frame_idx == frame_numbers[target_pos]:
                # Calculate timestamp from frame number
                timestamp = frame_idx / video_fps

                # Build filename: frame_000012.jpg
                fname = f"frame_{frame_idx:06d}.jpg"
                fpath = out_dir / fname

                # Save frame as JPEG (good balance of quality/size)
                cv2.imwrite(str(fpath), frame)

                h, w = frame.shape[:2]
                extracted_frames.append({
                    "frame_number": frame_idx,
                    "timestamp": round(timestamp, 3),
                    "timestamp_fmt": _format_duration(timestamp),
                    "width": w,
                    "height": h,
                    "filename": fname,
                    "path": str(fpath),
                })

                target_pos += 1

            frame_idx += 1
    finally:
        cap.release()

    logger.info(
        "Extracted %d frames from %s (method=%s, value=%s)",
        len(extracted_frames), Path(file_path).name,
        sampling_method, sampling_value,
    )

    return {
        "video_path": file_path,
        "output_dir": str(out_dir),
        "total_frames": len(extracted_frames),
        "video_duration": duration,
        "video_fps": video_fps,
        "video_resolution": f"{video_info['width']}x{video_info['height']}",
        "sampling_method": sampling_method,
        "sampling_value": sampling_value,
        "frames": extracted_frames,
    }


def extract_single_frame(
    file_path: str,
    timestamp: float,
    output_dir: Optional[str] = None,
) -> dict:
    """
    Extract a single frame at a specific timestamp (in seconds).

    Useful for targeted analysis of a suspicious moment in a video.

    Args:
        file_path:  Path to the video file.
        timestamp:  Time in seconds (e.g. 14.5 for 14.5 seconds in).
        output_dir: Where to save the frame image.

    Returns:
        A dict with frame metadata including the saved file path.
    """
    if timestamp < 0:
        raise MediaError(f"timestamp must be non-negative, got {timestamp}")

    video_info = read_video_info(file_path)
    if timestamp > video_info["duration"]:
        raise MediaError(
            f"timestamp {timestamp}s exceeds video duration "
            f"({video_info['duration']}s)"
        )

    # Set up output
    if output_dir is not None:
        out_dir = Path(output_dir)
    else:
        video_stem = Path(file_path).stem
        out_dir = FRAME_OUTPUT_DIR / video_stem
    out_dir.mkdir(parents=True, exist_ok=True)

    # Open video and seek to the target timestamp
    cap = cv2.VideoCapture(str(file_path))
    if not cap.isOpened():
        raise MediaError(f"Could not open video: {file_path}")

    try:
        # Set the position in milliseconds
        cap.set(cv2.CAP_PROP_POS_MSEC, timestamp * 1000)
        ret, frame = cap.read()

        if not ret or frame is None:
            raise MediaError(
                f"Could not read frame at timestamp {timestamp}s. "
                f"The video may be corrupted at this position."
            )

        h, w = frame.shape[:2]
        frame_number = int(cap.get(cv2.CAP_PROP_POS_FRAMES))

        fname = f"frame_at_{timestamp:.3f}s.jpg"
        fpath = out_dir / fname
        cv2.imwrite(str(fpath), frame)

        return {
            "frame_number": frame_number,
            "timestamp": round(timestamp, 3),
            "timestamp_fmt": _format_duration(timestamp),
            "width": w,
            "height": h,
            "filename": fname,
            "path": str(fpath),
        }
    finally:
        cap.release()


def cleanup_frames(output_dir: str) -> None:
    """
    Delete a previously extracted frames directory.

    Call this after the AI pipeline has consumed the frames to free disk.
    """
    import shutil
    dir_path = Path(output_dir)
    if dir_path.exists() and dir_path.is_dir():
        shutil.rmtree(dir_path)
        logger.info("Cleaned up frames directory: %s", output_dir)


# ---------------------------------------------------------------------------
# Frame extraction helpers
# ---------------------------------------------------------------------------

def _calculate_frame_numbers(
    total_video_frames: int,
    source_fps: float,
    target_fps: float,
) -> list[int]:
    """
    Calculate which frame numbers to extract.

    Uses source-video frame numbers so we can iterate through the video
    once and grab exactly the frames we need.
    """
    if target_fps >= source_fps:
        # Want more frames than the video has -- just take every frame
        return list(range(total_video_frames))

    # Frame interval in source-video frames
    step = source_fps / target_fps

    frame_numbers = []
    pos = 0.0
    while int(pos) < total_video_frames:
        frame_numbers.append(int(pos))
        pos += step

    return frame_numbers


def _evenly_space(total: int, target: int, items: list) -> list:
    """
    Pick 'target' items evenly spaced from a sorted list of 'total' items.
    """
    if target >= total:
        return items
    step = total / target
    return [items[int(i * step)] for i in range(target)]


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
