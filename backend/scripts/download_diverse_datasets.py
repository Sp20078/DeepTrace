"""
Download diverse deepfake datasets from Hugging Face.
Multiple generation methods = better generalization.
"""

import os
import sys
import shutil
from pathlib import Path

# Add parent to path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

def download_with_hub(dataset_id, repo_type="dataset"):
    """Download dataset using huggingface_hub."""
    try:
        from huggingface_hub import snapshot_download
        print(f"  Downloading {dataset_id}...")
        path = snapshot_download(
            repo_id=dataset_id,
            repo_type=repo_type,
            local_dir=f"/tmp/hf_datasets/{dataset_id.replace('/', '_')}",
        )
        print(f"  ✓ Downloaded to {path}")
        return Path(path)
    except Exception as e:
        print(f"  ✗ Failed: {e}")
        return None

def organize_dataset(path, real_dir, fake_dir, real_subdir="real", fake_subdir="fake"):
    """Copy images from downloaded dataset to data dirs."""
    if not path or not path.exists():
        return 0, 0
    
    real_count = 0
    fake_count = 0
    extensions = {".jpg", ".jpeg", ".png", ".bmp", ".webp"}
    
    # Try common directory structures
    for candidate_real in [real_subdir, "0", "authentic", "genuine"]:
        real_path = path / candidate_real
        if real_path.exists() and real_path.is_dir():
            for img in real_path.rglob("*"):
                if img.suffix.lower() in extensions:
                    shutil.copy2(img, real_dir / f"hf_{real_count:06d}{img.suffix.lower()}")
                    real_count += 1
            break
    
    for candidate_fake in [fake_subdir, "1", "fake", "synthetic", "deepfake"]:
        fake_path = path / candidate_fake
        if fake_path.exists() and fake_path.is_dir():
            for img in fake_path.rglob("*"):
                if img.suffix.lower() in extensions:
                    shutil.copy2(img, fake_dir / f"hf_{fake_count:06d}{img.suffix.lower()}")
                    fake_count += 1
            break
    
    return real_count, fake_count

def main():
    base_dir = Path(__file__).resolve().parent.parent
    data_dir = base_dir / "data"
    real_dir = data_dir / "real"
    fake_dir = data_dir / "fake"
    
    real_dir.mkdir(parents=True, exist_ok=True)
    fake_dir.mkdir(parents=True, exist_ok=True)
    
    print("=" * 60)
    print("Downloading Diverse Deepfake Datasets")
    print("=" * 60)
    
    # Count existing images
    existing_real = len(list(real_dir.glob("*")))
    existing_fake = len(list(fake_dir.glob("*")))
    print(f"\nExisting: {existing_real} real, {existing_fake} fake")
    
    # Datasets to download
    datasets = [
        # Diverse deepfake techniques
        ("OpenRL-Lab/DeepFakeFace", "real", "fake"),
        # 60K diverse deepfakes
        ("prithivMLmods/Deepfake-vs-Real-60K", "real", "fake"),
        # DF40 - 40 different techniques
        ("pujanpaudel/deepfake_face_classification", "real", "fake"),
    ]
    
    total_real = 0
    total_fake = 0
    
    for dataset_id, real_sub, fake_sub in datasets:
        print(f"\n{'─' * 40}")
        print(f"Dataset: {dataset_id}")
        path = download_with_hub(dataset_id)
        if path:
            r, f = organize_dataset(path, real_dir, fake_dir, real_sub, fake_sub)
            total_real += r
            total_fake += f
            print(f"  → Added {r} real, {f} fake")
    
    # Final counts
    final_real = len(list(real_dir.glob("*")))
    final_fake = len(list(fake_dir.glob("*")))
    
    print(f"\n{'=' * 60}")
    print(f"Download Complete!")
    print(f"{'=' * 60}")
    print(f"Total real: {final_real} (+{total_real} new)")
    print(f"Total fake: {final_fake} (+{total_fake} new)")
    print(f"\nNext: python -m training.preprocess --input data --output data/processed")

if __name__ == "__main__":
    main()
