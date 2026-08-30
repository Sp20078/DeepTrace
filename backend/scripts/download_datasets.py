"""
DeepTrace — Bulk Dataset Downloader
====================================
Downloads high-quality real/fake face datasets from Hugging Face.
No API keys required.

Usage:
    cd backend
    .venv/bin/python scripts/download_datasets.py
"""

import shutil
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from huggingface_hub import snapshot_download

BASE_DIR = Path(__file__).resolve().parent.parent
DATA_DIR = BASE_DIR / "data"
REAL_DIR = DATA_DIR / "real"
FAKE_DIR = DATA_DIR / "fake"
TEMP_DIR = DATA_DIR / "_downloads"
IMG_EXT = {".jpg", ".jpeg", ".png", ".bmp", ".webp"}


def ensure_dirs():
    for d in [REAL_DIR, FAKE_DIR, TEMP_DIR]:
        d.mkdir(parents=True, exist_ok=True)


def count_images(directory):
    return sum(1 for f in directory.rglob("*") if f.suffix.lower() in IMG_EXT)


def download_hf(repo_id, temp_name):
    dest = TEMP_DIR / temp_name
    if dest.exists():
        existing = sum(1 for f in dest.rglob("*") if f.suffix.lower() in IMG_EXT)
        if existing > 0:
            print(f"  Already downloaded: {temp_name} ({existing} images)")
            return dest
    print(f"  Downloading {repo_id}...")
    try:
        path = snapshot_download(repo_id=repo_id, repo_type="dataset", local_dir=str(dest), max_workers=4)
        print(f"  Downloaded to {path}")
        return Path(path)
    except Exception as e:
        print(f"  Failed: {e}")
        return None


def copy_images(src_dir, dest_dir):
    images = [f for f in src_dir.rglob("*") if f.suffix.lower() in IMG_EXT]
    copied = 0
    for img in images:
        dest_name = f"{src_dir.name}_{img.stem}_{copied:05d}{img.suffix}"
        shutil.copy2(img, dest_dir / dest_name)
        copied += 1
    return copied


def find_subdirs(path, names):
    """Find directories matching any of the given names."""
    results = {}
    for p in path.rglob("*"):
        if p.is_dir() and p.name.lower() in names:
            results[p.name.lower()] = p
    return results


def dataset_60k():
    """prithivMLmods/Deepfake-vs-Real-60K"""
    print("\n[1/4] Deepfake-vs-Real-60K (30K real + 30K fake)")
    path = download_hf("prithivMLmods/Deepfake-vs-Real-60K", "deepfake_60k")
    if not path:
        return 0
    dirs = find_subdirs(path, ["real", "fake"])
    n_real = copy_images(dirs["real"], REAL_DIR) if "real" in dirs else 0
    n_fake = copy_images(dirs["fake"], FAKE_DIR) if "fake" in dirs else 0
    print(f"  -> {n_real} real, {n_fake} fake")
    return n_real + n_fake


def dataset_openrl():
    """OpenRL/DeepFakeFace"""
    print("\n[2/4] DeepFakeFace (OpenRL)")
    path = download_hf("OpenRL/DeepFakeFace", "openrl_deepfake")
    if not path:
        return 0
    total = 0
    dirs = find_subdirs(path, ["real", "original", "fake", "deepfake", "generated"])
    for name in ["real", "original"]:
        if name in dirs:
            n = copy_images(dirs[name], REAL_DIR)
            total += n
            print(f"  -> {name}: {n} images")
    for name in ["fake", "deepfake", "generated"]:
        if name in dirs:
            n = copy_images(dirs[name], FAKE_DIR)
            total += n
            print(f"  -> {name}: {n} images")
    if total == 0:
        all_imgs = list(path.rglob("*.png")) + list(path.rglob("*.jpg"))
        if all_imgs:
            n = copy_images(path, FAKE_DIR)
            total = n
            print(f"  -> All {n} images as fake (GAN-generated)")
    return total


def dataset_detection_140k():
    """yashduhan/DeepFakeDetection"""
    print("\n[3/4] DeepFakeDetection (140K)")
    path = download_hf("yashduhan/DeepFakeDetection", "deepfake_detection_140k")
    if not path:
        return 0
    total = 0
    dirs = find_subdirs(path, ["real", "fake"])
    for name in ["real"]:
        if name in dirs:
            n = copy_images(dirs[name], REAL_DIR)
            total += n
            print(f"  -> {name}: {n} images")
    for name in ["fake"]:
        if name in dirs:
            n = copy_images(dirs[name], FAKE_DIR)
            total += n
            print(f"  -> {name}: {n} images")
    return total


def dataset_real_fake():
    """manjilkarki/deepfake-and-real-images"""
    print("\n[4/4] Deepfake and Real Images")
    path = download_hf("manjilkarki/deepfake-and-real-images", "deepfake_real_images")
    if not path:
        return 0
    total = 0
    dirs = find_subdirs(path, ["real", "fake"])
    for name in ["real"]:
        if name in dirs:
            n = copy_images(dirs[name], REAL_DIR)
            total += n
            print(f"  -> {name}: {n} images")
    for name in ["fake"]:
        if name in dirs:
            n = copy_images(dirs[name], FAKE_DIR)
            total += n
            print(f"  -> {name}: {n} images")
    return total


def main():
    print("=" * 60)
    print("DeepTrace — Bulk Dataset Downloader")
    print("=" * 60)
    ensure_dirs()

    existing = count_images(REAL_DIR) + count_images(FAKE_DIR)
    print(f"Existing: {count_images(REAL_DIR)} real + {count_images(FAKE_DIR)} fake = {existing}")

    total_added = 0
    for fn in [dataset_60k, dataset_openrl, dataset_detection_140k, dataset_real_fake]:
        total_added += fn()

    final_real = count_images(REAL_DIR)
    final_fake = count_images(FAKE_DIR)

    print("\n" + "=" * 60)
    print(f"SUMMARY: {total_added} new images added")
    print(f"  Real: {final_real}")
    print(f"  Fake: {final_fake}")
    print(f"  Total: {final_real + final_fake}")
    print("=" * 60)

    if TEMP_DIR.exists():
        size_mb = sum(f.stat().st_size for f in TEMP_DIR.rglob("*") if f.is_file()) / 1e6
        print(f"\nCleaning {size_mb:.0f} MB of downloads...")
        shutil.rmtree(TEMP_DIR, ignore_errors=True)
        print("Done!")

    print("\nNext steps:")
    print("  .venv/bin/python -m training.preprocess --input data --output data/processed")
    print("  .venv/bin/python -m training.train --data data/processed")
    print("  .venv/bin/python -m training.evaluate --data data/processed/test")


if __name__ == "__main__":
    main()
