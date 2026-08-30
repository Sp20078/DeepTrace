"""
DeepTrace Video Data Preprocessing for Celeb-DF Dataset
========================================================
Extracts frames from videos, detects faces, crops them to 224x224,
and organizes into train/val/test splits.

Dataset structure expected:
    archive/
    |-- Celeb-real/       -> real celebrity videos (label: real)
    |-- Celeb-synthesis/  -> deepfake videos (label: fake)
    |-- YouTube-real/     -> real YouTube videos (label: real)

Usage:
    python -m training.video_preprocess \\
        --input "C:/Users/Aditya Pandey/Downloads/archive" \\
        --output backend/data/processed

    # Or with custom settings:
    python -m training.video_preprocess \\
        --input "C:/Users/Aditya Pandey/Downloads/archive" \\
        --output backend/data/processed \\
        --frames-per-video 12 \\
        --max-videos 300 \\
        --seed 42
"""

import argparse
import random
import shutil
import sys
from pathlib import Path
import os

import cv2
import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))


# ── Configuration ──────────────────────────────────────────────────────────

INPUT_SIZE = 224
FACE_PADDING = 0.20
MIN_FACE_SIZE = 50
MIN_IMAGE_SIZE = 64
RANDOM_SEED = 42

TRAIN_RATIO = 0.80
VAL_RATIO = 0.10
TEST_RATIO = 0.10


# ── Face Detection ─────────────────────────────────────────────────────────

def get_face_detector():
    """Initialize Haar cascade face detector (works without facenet-pytorch)."""
    cascade_path = str(
        Path(cv2.data.haarcascades) / "haarcascade_frontalface_default.xml"
    )
    cascade = cv2.CascadeClassifier(cascade_path)
    if cascade.empty():
        raise RuntimeError(f"Failed to load cascade from {cascade_path}")
    return cascade


def detect_faces(frame_bgr: np.ndarray, detector, padding: float = FACE_PADDING):
    """
    Detect faces in a BGR frame using Haar cascades.

    Returns list of (x, y, w, h) bounding boxes (padded).
    """
    gray = cv2.cvtColor(frame_bgr, cv2.COLOR_BGR2GRAY)
    # Enhance contrast for better detection
    gray = cv2.equalizeHist(gray)

    faces_rects = detector.detectMultiScale(
        gray,
        scaleFactor=1.05,
        minNeighbors=4,
        minSize=(MIN_FACE_SIZE, MIN_FACE_SIZE),
        flags=cv2.CASCADE_SCALE_IMAGE,
    )

    if len(faces_rects) == 0:
        # Try with more relaxed parameters
        faces_rects = detector.detectMultiScale(
            gray,
            scaleFactor=1.1,
            minNeighbors=3,
            minSize=(30, 30),
            flags=cv2.CASCADE_SCALE_IMAGE,
        )

    ih, iw = frame_bgr.shape[:2]
    faces = []

    for (x, y, w, h) in faces_rects:
        if w < MIN_FACE_SIZE or h < MIN_FACE_SIZE:
            continue

        # Apply padding
        pad_w = int(w * padding)
        pad_h = int(h * padding)
        x1 = max(0, x - pad_w)
        y1 = max(0, y - pad_h)
        x2 = min(iw, x + w + pad_w)
        y2 = min(ih, y + h + pad_h)

        # Ensure minimum size
        if (x2 - x1) < MIN_IMAGE_SIZE or (y2 - y1) < MIN_IMAGE_SIZE:
            continue

        faces.append((x1, y1, x2 - x1, y2 - y1))

    # Sort by area (largest first)
    faces.sort(key=lambda b: b[2] * b[3], reverse=True)
    return faces


def crop_and_resize(frame_bgr: np.ndarray, bbox: tuple, size: int = INPUT_SIZE):
    """Crop face region and resize to target size."""
    x, y, w, h = bbox
    crop = frame_bgr[y : y + h, x : x + w]
    if crop.size == 0:
        return None
    resized = cv2.resize(crop, (size, size), interpolation=cv2.INTER_LANCZOS4)
    return resized


# ── Video Processing ───────────────────────────────────────────────────────


def extract_frames_from_video(
    video_path: str,
    num_frames: int = 10,
    min_interval: int = 5,
):
    """
    Extract evenly-spaced frames from a video.

    Returns list of (frame_bgr, frame_number, timestamp).
    """
    cap = cv2.VideoCapture(video_path)
    if not cap.isOpened():
        return []

    fps = cap.get(cv2.CAP_PROP_FPS)
    total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))

    if total_frames <= 0 or fps <= 0:
        cap.release()
        return []

    # Skip first and last 10% of frames to avoid intro/outro
    start_frame = int(total_frames * 0.1)
    end_frame = int(total_frames * 0.9)
    if end_frame <= start_frame:
        start_frame = 0
        end_frame = total_frames - 1

    # Sample evenly spaced frames
    sample_count = min(num_frames, end_frame - start_frame)
    if sample_count <= 0:
        cap.release()
        return []

    indices = np.linspace(start_frame, end_frame, sample_count, dtype=int)
    frames = []

    for idx in indices:
        cap.set(cv2.CAP_PROP_POS_FRAMES, int(idx))
        ret, frame = cap.read()
        if ret and frame is not None:
            timestamp = idx / fps
            frames.append((frame, int(idx), round(timestamp, 3)))

    cap.release()
    return frames


def process_video(
    video_path: str,
    detector,
    output_dir: Path,
    prefix: str,
    num_frames: int = 10,
    max_faces_per_frame: int = 1,
):
    """
    Process a single video: extract frames, detect faces, save crops.

    Returns number of face crops saved.
    """
    frames = extract_frames_from_video(video_path, num_frames=num_frames)
    saved = 0

    for frame_idx, (frame_bgr, frame_number, timestamp) in enumerate(frames):
        faces = detect_faces(frame_bgr, detector)

        for face_idx, bbox in enumerate(faces[:max_faces_per_frame]):
            crop = crop_and_resize(frame_bgr, bbox)
            if crop is None:
                continue

            out_name = f"{prefix}_f{frame_number:06d}_face{face_idx:02d}.png"
            out_path = output_dir / out_name

            # Check minimum size
            if crop.shape[0] < MIN_IMAGE_SIZE or crop.shape[1] < MIN_IMAGE_SIZE:
                continue

            cv2.imwrite(str(out_path), crop, [cv2.IMWRITE_PNG_COMPRESSION, 3])
            saved += 1

    return saved


# ── Dataset Processing ─────────────────────────────────────────────────────


def process_celebdf_dataset(
    input_dir: Path,
    output_dir: Path,
    detector,
    frames_per_video: int = 10,
    max_videos: int | None = None,
    seed: int = RANDOM_SEED,
):
    """
    Process the full Celeb-DF dataset.

    1. Scan real/fake video directories
    2. Extract frames and detect faces
    3. Save face crops to raw/real/ and raw/fake/
    """
    random.seed(seed)
    np.random.seed(seed)

    # Map directory names to labels
    dir_map = {
        "Celeb-real": "real",
        "Celeb-synthesis": "fake",
        "YouTube-real": "real",
    }

    raw_dir = output_dir / "raw"
    raw_real = raw_dir / "real"
    raw_fake = raw_dir / "fake"
    raw_real.mkdir(parents=True, exist_ok=True)
    raw_fake.mkdir(parents=True, exist_ok=True)

    stats = {"real": {"videos": 0, "faces": 0}, "fake": {"videos": 0, "faces": 0}}

    for dir_name, label in dir_map.items():
        src_dir = input_dir / dir_name
        if not src_dir.exists():
            print(f"  [!] Directory not found: {src_dir}")
            continue

        # Find all video files
        video_extensions = {".mp4", ".avi", ".mov", ".mkv", ".webm"}
        videos = [
            f
            for f in src_dir.iterdir()
            if f.suffix.lower() in video_extensions
        ]
        videos.sort()

        # Apply max_videos limit per class
        if max_videos and len(videos) > max_videos:
            videos = random.sample(videos, max_videos)

        print(f"\n  Processing {dir_name} ({label}): {len(videos)} videos...")
        out_dir = raw_real if label == "real" else raw_fake

        for v_idx, video_path in enumerate(videos):
            prefix = f"{label}_{v_idx:04d}"
            saved = process_video(
                str(video_path),
                detector,
                out_dir,
                prefix=prefix,
                num_frames=frames_per_video,
                max_faces_per_frame=1,
            )

            stats[label]["videos"] += 1
            stats[label]["faces"] += saved

            if (v_idx + 1) % 25 == 0:
                print(
                    f"    {v_idx + 1}/{len(videos)} videos processed "
                    f"({stats[label]['faces']} faces extracted)"
                )

        print(
            f"  [OK] {dir_name}: {stats[label]['videos']} videos, "
            f"{stats[label]['faces']} faces"
        )

    return stats, raw_dir


# ── Balanced Split ─────────────────────────────────────────────────────────


def split_data(
    raw_dir: Path,
    output_dir: Path,
    seed: int = RANDOM_SEED,
):
    """Split raw face crops into balanced train/val/test."""
    random.seed(seed)

    # Load both classes
    class_images = {}
    for class_name in ["real", "fake"]:
        class_dir = raw_dir / class_name
        if not class_dir.exists():
            continue
        images = list(class_dir.glob("*.png"))
        random.shuffle(images)
        class_images[class_name] = images

    if len(class_images) < 2:
        print("  [!] Need both real/ and fake/ directories")
        return

    real_imgs = class_images.get("real", [])
    fake_imgs = class_images.get("fake", [])
    n_real = len(real_imgs)
    n_fake = len(fake_imgs)

    print(f"\n  Raw counts — real: {n_real}, fake: {n_fake}")

    # Balance: use minority class size
    min_class = min(n_real, n_fake)
    n_train = int(min_class * TRAIN_RATIO)
    n_val = int(min_class * VAL_RATIO)
    n_test = min_class - n_train - n_val

    # Slice each class
    splits_real = {
        "train": real_imgs[:n_train],
        "val": real_imgs[n_train : n_train + n_val],
        "test": real_imgs[n_train + n_val : n_train + n_val + n_test],
    }
    splits_fake = {
        "train": fake_imgs[:n_train],
        "val": fake_imgs[n_train : n_train + n_val],
        "test": fake_imgs[n_train + n_val : n_train + n_val + n_test],
    }

    for split_name in ["train", "val", "test"]:
        for class_name, split_imgs in [
            ("real", splits_real[split_name]),
            ("fake", splits_fake[split_name]),
        ]:
            split_dir = output_dir / split_name / class_name
            split_dir.mkdir(parents=True, exist_ok=True)
            for img_path in split_imgs:
                shutil.copy2(img_path, split_dir / img_path.name)

    majority = "real" if n_real > n_fake else "fake"
    print(f"  Balanced split — train: {n_train} real + {n_train} fake")
    print(f"                   val:   {n_val} real + {n_val} fake")
    print(f"                   test:  {n_test} real + {n_test} fake")
    print(
        f"  Total per class: {min_class} "
        f"(majority {majority} had {max(n_real, n_fake)} — "
        f"{max(n_real, n_fake) - min_class} unused)"
    )


# ── Main ───────────────────────────────────────────────────────────────────


def main():
    parser = argparse.ArgumentParser(
        description="Preprocess Celeb-DF video dataset for DeepTrace training"
    )
    parser.add_argument(
        "--input",
        required=True,
        help="Path to archive/ directory containing Celeb-real, Celeb-synthesis, YouTube-real",
    )
    parser.add_argument(
        "--output",
        default=None,
        help="Output directory for processed data (default: input/processed)",
    )
    parser.add_argument(
        "--frames-per-video",
        type=int,
        default=10,
        help="Number of frames to extract per video (default: 10)",
    )
    parser.add_argument(
        "--max-videos",
        type=int,
        default=None,
        help="Max videos to process per class (default: all)",
    )
    parser.add_argument(
        "--seed", type=int, default=RANDOM_SEED, help="Random seed"
    )
    args = parser.parse_args()

    input_dir = Path(args.input)
    output_dir = Path(args.output) if args.output else input_dir / "processed"

    if not input_dir.exists():
        print(f"[ERROR] Input directory not found: {input_dir}")
        sys.exit(1)

    print(f"\n{'=' * 60}")
    print("DeepTrace Video Data Preprocessing (Celeb-DF)")
    print(f"{'=' * 60}")
    print(f"  Input:  {input_dir}")
    print(f"  Output: {output_dir}")
    print(f"  Frames per video: {args.frames_per_video}")
    print(f"  Max videos per class: {args.max_videos or 'all'}")
    print(f"{'=' * 60}")

    # Initialize face detector
    print("\nInitializing face detector...")
    detector = get_face_detector()
    print("[OK] Haar cascade face detector ready")

    # Step 1: Process videos → extract faces
    print("\nStep 1: Extracting faces from videos...")
    stats, raw_dir = process_celebdf_dataset(
        input_dir=input_dir,
        output_dir=output_dir,
        detector=detector,
        frames_per_video=args.frames_per_video,
        max_videos=args.max_videos,
        seed=args.seed,
    )

    total_faces = sum(s["faces"] for s in stats.values())
    print(f"\n[OK] Total face crops extracted: {total_faces}")
    print(f"  Real: {stats['real']['faces']} from {stats['real']['videos']} videos")
    print(f"  Fake: {stats['fake']['faces']} from {stats['fake']['videos']} videos")

    if total_faces == 0:
        print("\n[ERROR] No faces found. Check input directory and video files.")
        sys.exit(1)

    # Step 2: Split into train/val/test
    print("\nStep 2: Splitting into train/val/test...")
    split_data(raw_dir, output_dir, seed=args.seed)

    # Step 3: Clean up raw directory
    shutil.rmtree(raw_dir, ignore_errors=True)

    # Summary
    print(f"\n{'=' * 60}")
    print("Preprocessing complete!")
    print(f"{'=' * 60}")
    for split in ["train", "val", "test"]:
        split_dir = output_dir / split
        r = (
            len(list((split_dir / "real").glob("*.png")))
            if (split_dir / "real").exists()
            else 0
        )
        f = (
            len(list((split_dir / "fake").glob("*.png")))
            if (split_dir / "fake").exists()
            else 0
        )
        print(f"  {split:5s}: {r + f:5d} images (real: {r}, fake: {f})")

    total = sum(
        len(list((output_dir / s / c).glob("*.png")))
        for s in ["train", "val", "test"]
        for c in ["real", "fake"]
        if (output_dir / s / c).exists()
    )
    print(f"  Total: {total:5d} images")
    print(f"\n  Next step: python -m training.train --data {output_dir}")


if __name__ == "__main__":
    main()
