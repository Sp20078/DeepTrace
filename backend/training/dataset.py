"""
PyTorch Dataset for DeepTrace deepfake detection.
===================================================
Handles loading preprocessed face crops from disk,
applying training/validation transforms, and providing
them to the DataLoader.
"""

import random
from pathlib import Path

import torch
from torch.utils.data import Dataset, DataLoader, WeightedRandomSampler
from torchvision import transforms
from PIL import Image

from training.config import (
    INPUT_SIZE,
    BATCH_SIZE,
    NUM_WORKERS,
    RANDOM_SEED,
    RANDOM_HORIZONTAL_FLIP,
    COLOR_JITTER_BRIGHTNESS,
    COLOR_JITTER_CONTRAST,
    COLOR_JITTER_SATURATION,
    COLOR_JITTER_HUE,
    RANDOM_ERASING_PROB,
)

# ── ImageNet normalization (required for pretrained models) ────────────────
IMAGENET_MEAN = [0.485, 0.456, 0.406]
IMAGENET_STD = [0.229, 0.224, 0.225]


def get_train_transforms():
    """Augmentation pipeline for training."""
    return transforms.Compose([
        transforms.Resize((INPUT_SIZE, INPUT_SIZE)),
        transforms.RandomHorizontalFlip(p=RANDOM_HORIZONTAL_FLIP),
        transforms.ColorJitter(
            brightness=COLOR_JITTER_BRIGHTNESS,
            contrast=COLOR_JITTER_CONTRAST,
            saturation=COLOR_JITTER_SATURATION,
            hue=COLOR_JITTER_HUE,
        ),
        transforms.ToTensor(),
        transforms.Normalize(mean=IMAGENET_MEAN, std=IMAGENET_STD),
        transforms.RandomErasing(p=RANDOM_ERASING_PROB, scale=(0.02, 0.15)),
    ])


def get_val_transforms():
    """No augmentation for validation/testing."""
    return transforms.Compose([
        transforms.Resize((INPUT_SIZE, INPUT_SIZE)),
        transforms.ToTensor(),
        transforms.Normalize(mean=IMAGENET_MEAN, std=IMAGENET_STD),
    ])


class DeepfakeDataset(Dataset):
    """
    Dataset that loads face crops from a processed directory.

    Expected structure:
        processed_dir/
        ├── train/
        │   ├── real/
        │   │   ├── img001.png
        │   │   └── ...
        │   └── fake/
        │       ├── img001.png
        │       └── ...
        ├── val/
        │   ├── real/
        │   └── fake/
        └── test/
            ├── real/
            └── fake/
    """

    CLASS_MAP = {"real": 0, "fake": 1}

    def __init__(self, split_dir: str | Path, transform=None):
        """
        Args:
            split_dir: Path to split directory (e.g. data/processed/train/)
            transform: torchvision transform pipeline
        """
        self.split_dir = Path(split_dir)
        self.transform = transform
        self.samples: list[tuple[Path, int]] = []

        for class_name, label in self.CLASS_MAP.items():
            class_dir = self.split_dir / class_name
            if not class_dir.exists():
                continue
            for img_path in sorted(class_dir.glob("*")):
                if img_path.suffix.lower() in {".jpg", ".jpeg", ".png", ".bmp", ".webp"}:
                    self.samples.append((img_path, label))

        if not self.samples:
            raise FileNotFoundError(
                f"No images found in {split_dir}. "
                f"Expected structure: {split_dir}/{{real,fake}}/*.png"
            )

    def __len__(self):
        return len(self.samples)

    def __getitem__(self, idx):
        img_path, label = self.samples[idx]

        try:
            image = Image.open(img_path).convert("RGB")
        except Exception as e:
            # If image is corrupt, return a black image (keeps training going)
            image = Image.new("RGB", (INPUT_SIZE, INPUT_SIZE), (0, 0, 0))

        if self.transform:
            image = self.transform(image)

        return image, label

    def get_class_counts(self) -> dict[str, int]:
        """Return count of samples per class."""
        counts = {"real": 0, "fake": 0}
        for _, label in self.samples:
            class_name = "real" if label == 0 else "fake"
            counts[class_name] += 1
        return counts

    def get_weights(self) -> torch.Tensor:
        """Return sample weights for balanced sampling (handles class imbalance)."""
        counts = self.get_class_counts()
        total = sum(counts.values())
        weights = []
        for _, label in self.samples:
            class_name = "real" if label == 0 else "fake"
            w = total / (2 * counts[class_name])
            weights.append(w)
        return torch.DoubleTensor(weights)


def create_dataloaders(processed_dir: str | Path, batch_size: int = BATCH_SIZE):
    """
    Create train, val, and test DataLoaders.

    Uses WeightedRandomSampler for training to handle class imbalance.
    """
    processed_dir = Path(processed_dir)

    train_ds = DeepfakeDataset(processed_dir / "train", transform=get_train_transforms())
    val_ds = DeepfakeDataset(processed_dir / "val", transform=get_val_transforms())
    test_ds = DeepfakeDataset(processed_dir / "test", transform=get_val_transforms())

    # Balanced sampler for training
    train_weights = train_ds.get_weights()
    sampler = WeightedRandomSampler(
        train_weights, num_samples=len(train_weights), replacement=True
    )

    train_loader = DataLoader(
        train_ds,
        batch_size=batch_size,
        sampler=sampler,
        num_workers=NUM_WORKERS,
        pin_memory=True,
        drop_last=True,
    )

    val_loader = DataLoader(
        val_ds,
        batch_size=batch_size,
        shuffle=False,
        num_workers=NUM_WORKERS,
        pin_memory=True,
    )

    test_loader = DataLoader(
        test_ds,
        batch_size=batch_size,
        shuffle=False,
        num_workers=NUM_WORKERS,
        pin_memory=True,
    )

    # Print dataset stats
    train_counts = train_ds.get_class_counts()
    val_counts = val_ds.get_class_counts()
    test_counts = test_ds.get_class_counts()

    print(f"\n{'='*50}")
    print(f"Dataset loaded from {processed_dir}")
    print(f"{'='*50}")
    print(f"  Train: {len(train_ds):,} images (real: {train_counts['real']:,}, fake: {train_counts['fake']:,})")
    print(f"  Val:   {len(val_ds):,} images (real: {val_counts['real']:,}, fake: {val_counts['fake']:,})")
    print(f"  Test:  {len(test_ds):,} images (real: {test_counts['real']:,}, fake: {test_counts['fake']:,})")
    print(f"  Total: {len(train_ds) + len(val_ds) + len(test_ds):,} images")
    print(f"{'='*50}\n")

    return train_loader, val_loader, test_loader
