"""
DeepTrace Data Preprocessing Pipeline
=======================================
Detects faces using MTCNN, crops them, resizes to 224×224,
and splits into train/val/test sets.

Usage:
    python -m training.preprocess --input backend/data --output backend/data/processed

Or from the backend/ directory:
    python -m training.preprocess --input data --output data/processed
"""

import argparse
import random
import shutil
import sys
from pathlib import Path

import cv2
import numpy as np

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from training.config import (
    INPUT_SIZE,
    FACE_PADDING,
    TRAIN_RATIO,
    VAL_RATIO,
    TEST_RATIO,
    RANDOM_SEED,
    MIN_IMAGE_SIZE,
)


def detect_faces_mtcnn(image: np.ndarray, detector):
    """
    Detect faces using MTCNN.

    Args:
        image: BGR numpy array
        detector: MTCNN detector instance

    Returns:
        List of (x, y, w, h) bounding boxes
    """
    from PIL import Image

    # MTCNN expects RGB PIL Image
    rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
    pil_img = Image.fromarray(rgb)

    boxes, probs = detector.detect(pil_img)

    faces = []
    if boxes is not None:
        for box, prob in zip(boxes, probs):
            if prob < 0.9:  # Confidence threshold
                continue
            x1, y1, x2, y2 = box.astype(int)
            w, h = x2 - x1, y2 - y1

            # Skip tiny faces
            if w < MIN_IMAGE_SIZE or h < MIN_IMAGE_SIZE:
                continue

            # Apply padding
            pad_w = int(w * FACE_PADDING)
            pad_h = int(h * FACE_PADDING)

            ih, iw = image.shape[:2]
            x1 = max(0, x1 - pad_w)
            y1 = max(0, y1 - pad_h)
            x2 = min(iw, x2 + pad_w)
            y2 = min(ih, y2 + pad_h)

            faces.append((x1, y1, x2 - x1, y2 - y1))

    return faces


def detect_faces_haar(image: np.ndarray, cascade):
    """Fallback face detection using Haar cascades."""
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    faces_rects = cascade.detectMultiScale(
        gray, scaleFactor=1.1, minNeighbors=5, minSize=(30, 30)
    )

    faces = []
    for (x, y, w, h) in faces_rects:
        pad_w = int(w * FACE_PADDING)
        pad_h = int(h * FACE_PADDING)
        ih, iw = image.shape[:2]
        x1 = max(0, x - pad_w)
        y1 = max(0, y - pad_h)
        x2 = min(iw, x + w + pad_w)
        y2 = min(ih, y + h + pad_h)
        faces.append((x1, y1, x2 - x1, y2 - y1))

    return faces


def crop_and_resize(image: np.ndarray, bbox: tuple, size: int = INPUT_SIZE) -> np.ndarray:
    """Crop face region and resize to target size."""
    x, y, w, h = bbox
    crop = image[y:y + h, x:x + w]
    resized = cv2.resize(crop, (size, size), interpolation=cv2.INTER_LANCZOS4)
    return resized


def get_face_detector(detector_type: str = "mtcnn"):
    """Initialize face detector."""
    if detector_type == "mtcnn":
        try:
            from facenet_pytorch import MTCNN
            detector = MTCNN(
                keep_all=True,
                device="cpu",  # Preprocessing on CPU is fine
                min_face_size=30,
                thresholds=[0.9, 0.9, 0.9],
                post_process=True,
            )
            print("[OK] MTCNN face detector initialized")
            return detector, "mtcnn"
        except ImportError:
            print("[WARN] MTCNN not available. Install facenet-pytorch:")
            print("  pip install facenet-pytorch")
            print("  Falling back to Haar cascades...")

    # Fallback to Haar
    cascade = cv2.CascadeClassifier(
        str(Path(cv2.data.haarcascades) / "haarcascade_frontalface_default.xml")
    )
    print("[OK] Haar cascade face detector initialized (fallback)")
    return cascade, "haar"


def process_directory(
    input_dir: Path,
    output_dir: Path,
    detector_type: str = "mtcnn",
    max_faces_per_image: int = 1,
):
    """
    Process all images in input_dir, detect faces, save crops to output_dir.

    Returns:
        dict with processing stats
    """
    detector, det_type = get_face_detector(detector_type)

    real_dir = input_dir / "real"
    fake_dir = input_dir / "fake"

    output_real = output_dir / "raw" / "real"
    output_fake = output_dir / "raw" / "fake"
    output_real.mkdir(parents=True, exist_ok=True)
    output_fake.mkdir(parents=True, exist_ok=True)

    stats = {"real": {"processed": 0, "skipped": 0, "faces": 0},
             "fake": {"processed": 0, "skipped": 0, "faces": 0}}

    for class_name, out_dir in [("real", output_real), ("fake", output_fake)]:
        src_dir = real_dir if class_name == "real" else fake_dir
        if not src_dir.exists():
            print(f"[!] Directory not found: {src_dir}")
            continue

        extensions = {".jpg", ".jpeg", ".png", ".bmp", ".webp", ".tiff"}
        images = [f for f in src_dir.iterdir() if f.suffix.lower() in extensions]
        print(f"\nProcessing {class_name}: {len(images)} images...")

        for i, img_path in enumerate(images):
            try:
                image = cv2.imread(str(img_path))
                if image is None:
                    stats[class_name]["skipped"] += 1
                    continue

                h, w = image.shape[:2]
                if h < MIN_IMAGE_SIZE or w < MIN_IMAGE_SIZE:
                    stats[class_name]["skipped"] += 1
                    continue

                # Detect faces
                if det_type == "mtcnn":
                    faces = detect_faces_mtcnn(image, detector)
                else:
                    faces = detect_faces_haar(image, detector)

                if not faces:
                    stats[class_name]["skipped"] += 1
                    continue

                # Use the largest face
                faces.sort(key=lambda b: b[2] * b[3], reverse=True)

                for face_idx, bbox in enumerate(faces[:max_faces_per_image]):
                    crop = crop_and_resize(image, bbox)
                    out_name = f"{img_path.stem}_face{face_idx:02d}.png"
                    cv2.imwrite(str(out_dir / out_name), crop)
                    stats[class_name]["faces"] += 1

                stats[class_name]["processed"] += 1

                if (i + 1) % 100 == 0:
                    print(f"  {i + 1}/{len(images)} processed...")

            except Exception as e:
                stats[class_name]["skipped"] += 1
                continue

        print(f"  [OK] {class_name}: {stats[class_name]['processed']} processed, "
              f"{stats[class_name]['faces']} faces extracted, "
              f"{stats[class_name]['skipped']} skipped")

    return stats


def split_data(raw_dir: Path, output_dir: Path, seed: int = RANDOM_SEED):
    """Split raw face crops into train/val/test with BALANCED classes.

    Undersamples the majority class in each split so real and fake counts
    are equal.  The unused majority-class images are discarded.
    """
    random.seed(seed)

    # ── Load both classes ──────────────────────────────────────────────────
    class_images: dict[str, list[Path]] = {}
    for class_name in ["real", "fake"]:
        class_dir = raw_dir / class_name
        if not class_dir.exists():
            continue
        images = list(class_dir.glob("*.png"))
        random.shuffle(images)
        class_images[class_name] = images

    if len(class_images) < 2:
        print("  [!] Need both real/ and fake/ directories to create balanced splits")
        return

    real_imgs = class_images.get("real", [])
    fake_imgs = class_images.get("fake", [])
    n_real = len(real_imgs)
    n_fake = len(fake_imgs)

    print(f"  Raw counts — real: {n_real}, fake: {n_fake}")

    # ── Determine balanced split sizes ─────────────────────────────────────
    # Cap the majority class to the minority class size per split
    min_class = min(n_real, n_fake)
    n_train = int(min_class * TRAIN_RATIO)
    n_val = int(min_class * VAL_RATIO)
    n_test = min_class - n_train - n_val

    # Slice each class independently (already shuffled)
    splits_real = {
        "train": real_imgs[:n_train],
        "val": real_imgs[n_train:n_train + n_val],
        "test": real_imgs[n_train + n_val:n_train + n_val + n_test],
    }
    splits_fake = {
        "train": fake_imgs[:n_train],
        "val": fake_imgs[n_train:n_train + n_val],
        "test": fake_imgs[n_train + n_val:n_train + n_val + n_test],
    }

    for split_name in ["train", "val", "test"]:
        for class_name, split_imgs in [("real", splits_real[split_name]),
                                        ("fake", splits_fake[split_name])]:
            split_dir = output_dir / split_name / class_name
            split_dir.mkdir(parents=True, exist_ok=True)
            for img_path in split_imgs:
                shutil.copy2(img_path, split_dir / img_path.name)

    print(f"  Balanced split — train: {n_train} real + {n_train} fake")
    print(f"                 val:   {n_val} real + {n_val} fake")
    print(f"                 test:  {n_test} real + {n_test} fake")
    print(f"  Total per class: {min_class} (majority class {"real" if n_real > n_fake else "fake"} "
          f"had {max(n_real, n_fake)} — {max(n_real, n_fake) - min_class} unused)")


def main():
    parser = argparse.ArgumentParser(description="Preprocess data for DeepTrace training")
    parser.add_argument("--input", required=True, help="Input directory with real/ and fake/ subdirs")
    parser.add_argument("--output", default=None, help="Output directory (default: input/processed)")
    parser.add_argument("--detector", default="mtcnn", choices=["mtcnn", "haar"],
                        help="Face detector to use")
    parser.add_argument("--max-faces", type=int, default=1,
                        help="Max faces to extract per image")
    parser.add_argument("--seed", type=int, default=RANDOM_SEED, help="Random seed")
    args = parser.parse_args()

    input_dir = Path(args.input)
    output_dir = Path(args.output) if args.output else input_dir / "processed"

    if not input_dir.exists():
        print(f"[ERROR] Input directory not found: {input_dir}")
        sys.exit(1)

    print(f"\n{'='*50}")
    print("DeepTrace Data Preprocessing")
    print(f"{'='*50}")
    print(f"Input:  {input_dir}")
    print(f"Output: {output_dir}")
    print(f"Detector: {args.detector}")
    print(f"{'='*50}")

    # Step 1: Detect faces and crop
    raw_dir = output_dir / "raw"
    stats = process_directory(
        input_dir=input_dir,
        output_dir=output_dir,
        detector_type=args.detector,
        max_faces_per_image=args.max_faces,
    )

    total = sum(s["faces"] for s in stats.values())
    print(f"\n[OK] Total faces extracted: {total}")

    if total == 0:
        print("\n[ERROR] No faces found in any images. Check your input directory.")
        sys.exit(1)

    # Step 2: Split into train/val/test
    print(f"\nSplitting into train/val/test...")
    split_data(raw_dir, output_dir, seed=args.seed)

    # Step 3: Clean up raw directory
    shutil.rmtree(raw_dir, ignore_errors=True)

    # Summary
    print(f"\n{'='*50}")
    print("Preprocessing complete!")
    print(f"{'='*50}")
    for split in ["train", "val", "test"]:
        split_dir = output_dir / split
        r = len(list((split_dir / "real").glob("*.png"))) if (split_dir / "real").exists() else 0
        f = len(list((split_dir / "fake").glob("*.png"))) if (split_dir / "fake").exists() else 0
        print(f"  {split:5s}: {r + f:5d} images (real: {r}, fake: {f})")
    print(f"\nNext step: python -m training.train --data {output_dir}")


if __name__ == "__main__":
    main()
