"""
DeepTrace Model Evaluation & Calibration
==========================================
Evaluates trained model on test set, generates metrics,
and fits Platt scaling for proper score calibration.

Usage:
    python -m training.evaluate --data backend/data/processed/test
    python -m training.evaluate --data backend/data/processed/test --checkpoint model_weights/efficientnet_b2_deeptrace_best.pth
"""

import argparse
import json
import pickle
import sys
from pathlib import Path

import numpy as np
import torch
import torch.nn as nn
from torchvision import transforms, models
from torch.utils.data import DataLoader, Dataset
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from training.config import (
    NUM_CLASSES,
    INPUT_SIZE,
    DEVICE,
    WEIGHTS_DIR,
)
from training.dataset import get_val_transforms, IMAGENET_MEAN, IMAGENET_STD

# Import config values directly
from training import config as cfg


# ── Dataset for evaluation ────────────────────────────────────────────────

class EvalDataset(Dataset):
    """Simple dataset for evaluating on a test directory."""

    def __init__(self, data_dir: Path, transform=None):
        self.transform = transform
        self.samples = []

        for class_name, label in [("real", 0), ("fake", 1)]:
            class_dir = data_dir / class_name
            if not class_dir.exists():
                continue
            for img in sorted(class_dir.glob("*")):
                if img.suffix.lower() in {".jpg", ".jpeg", ".png", ".bmp", ".webp"}:
                    self.samples.append((img, label))

    def __len__(self):
        return len(self.samples)

    def __getitem__(self, idx):
        img_path, label = self.samples[idx]
        try:
            image = Image.open(img_path).convert("RGB")
        except Exception:
            image = Image.new("RGB", (INPUT_SIZE, INPUT_SIZE), (0, 0, 0))

        if self.transform:
            image = self.transform(image)
        return image, label


# ── Platt Scaling ──────────────────────────────────────────────────────────

class PlattScaler:
    """
    Learn a sigmoid calibration: P(fake | score) = sigmoid(a * score + b)
    Transforms raw model outputs to well-calibrated probabilities.
    """

    def __init__(self):
        self.a = 1.0
        self.b = 0.0
        self.fitted = False

    def fit(self, scores: np.ndarray, labels: np.ndarray, lr=0.01, epochs=1000):
        """
        Fit Platt scaling using gradient descent.

        Args:
            scores: Raw fake probabilities from model [0, 1]
            labels: Ground truth labels (0=real, 1=fake)
        """
        # Convert to numpy float
        scores = np.array(scores, dtype=np.float64)
        labels = np.array(labels, dtype=np.float64)

        # Target: use soft labels to avoid overfitting
        n = len(labels)
        targets = np.where(labels == 1, 0.9, 0.1)

        for _ in range(epochs):
            # Forward: sigmoid(a * score + b)
            logits = self.a * scores + self.b
            probs = 1.0 / (1.0 + np.exp(-logits))

            # BCE loss
            eps = 1e-7
            loss = -np.mean(targets * np.log(probs + eps) + (1 - targets) * np.log(1 - probs + eps))

            # Gradients
            grad = probs - targets
            da = np.mean(grad * scores)
            db = np.mean(grad)

            # Update
            self.a -= lr * da
            self.b -= lr * db

        self.fitted = True
        print(f"  Platt scaling fitted: a={self.a:.4f}, b={self.b:.4f}")

    def calibrate(self, scores: np.ndarray) -> np.ndarray:
        """Apply calibration to raw scores."""
        if not self.fitted:
            return scores
        scores = np.array(scores, dtype=np.float64)
        logits = self.a * scores + self.b
        return 1.0 / (1.0 + np.exp(-logits))

    def save(self, path: Path):
        """Save calibration parameters."""
        with open(path, "wb") as f:
            pickle.dump({"a": self.a, "b": self.b}, f)
        print(f"  Calibration saved to {path}")

    @classmethod
    def load(cls, path: Path) -> "PlattScaler":
        """Load calibration parameters."""
        scaler = cls()
        with open(path, "rb") as f:
            data = pickle.load(f)
        scaler.a = data["a"]
        scaler.b = data["b"]
        scaler.fitted = True
        return scaler


# ── Evaluation ─────────────────────────────────────────────────────────────

@torch.no_grad()
def evaluate_model(model, data_loader, device):
    """Run inference on all samples and collect results."""
    model.eval()
    all_probs = []
    all_labels = []

    for images, labels in data_loader:
        images = images.to(device, non_blocking=True)
        outputs = model(images)
        probs = torch.softmax(outputs, dim=1)[:, 1]  # fake probability
        all_probs.extend(probs.cpu().numpy().tolist())
        all_labels.extend(labels.numpy().tolist())

    return np.array(all_probs), np.array(all_labels)


def compute_metrics(probs, labels, thresholds=None):
    """Compute comprehensive classification metrics."""
    if thresholds is None:
        thresholds = [cfg.THRESHOLD_LOW, cfg.THRESHOLD_HIGH]

    threshold_low, threshold_high = thresholds

    # Binary predictions
    preds = np.where(probs >= threshold_high, 1,
                     np.where(probs <= threshold_low, -1, 0))  # -1 = inconclusive

    # Only count definitive predictions for accuracy
    definitive = preds != 0
    if definitive.sum() > 0:
        accuracy = (preds[definitive] == labels[definitive]).mean() * 100
    else:
        accuracy = 0.0

    # All predictions (treat inconclusive as "real" for AUC)
    binary_preds = (probs >= 0.5).astype(int)

    # Confusion matrix components
    tp = ((preds == 1) & (labels == 1)).sum()
    fp = ((preds == 1) & (labels == 0)).sum()
    tn = ((preds == 0) & (labels == 0)).sum() + ((preds == -1) & (labels == 0)).sum()
    fn = ((preds == 0) & (labels == 1)).sum() + ((preds == -1) & (labels == 1)).sum()
    inconclusive = (preds == 0).sum()

    # Precision / Recall / F1
    precision = tp / (tp + fp) if (tp + fp) > 0 else 0.0
    recall = tp / (tp + fn) if (tp + fn) > 0 else 0.0
    f1 = 2 * precision * recall / (precision + recall) if (precision + recall) > 0 else 0.0

    # AUC
    try:
        from sklearn.metrics import roc_auc_score, roc_curve
        auc = roc_auc_score(labels, probs)
        fpr, tpr, _ = roc_curve(labels, probs)
    except ImportError:
        auc = 0.0
        fpr, tpr = np.array([]), np.array([])

    return {
        "accuracy": round(float(accuracy), 2),
        "auc": round(float(auc), 4),
        "precision": round(float(precision), 4),
        "recall": round(float(recall), 4),
        "f1": round(float(f1), 4),
        "true_positives": int(tp),
        "false_positives": int(fp),
        "true_negatives": int(tn),
        "false_negatives": int(fn),
        "inconclusive": int(inconclusive),
        "total": len(labels),
        "fpr": fpr.tolist(),
        "tpr": tpr.tolist(),
    }


def print_metrics(metrics, title="Evaluation Results"):
    """Pretty-print metrics."""
    print(f"\n{'='*50}")
    print(f"  {title}")
    print(f"{'='*50}")
    print(f"  Accuracy:    {metrics['accuracy']:.1f}%")
    print(f"  AUC:         {metrics['auc']:.4f}")
    print(f"  Precision:   {metrics['precision']:.4f}")
    print(f"  Recall:      {metrics['recall']:.4f}")
    print(f"  F1-Score:    {metrics['f1']:.4f}")
    print(f"  {'-'*40}")
    print(f"  TP: {metrics['true_positives']:4d}  |  FP: {metrics['false_positives']:4d}")
    print(f"  FN: {metrics['false_negatives']:4d}  |  TN: {metrics['true_negatives']:4d}")
    print(f"  Inconclusive: {metrics['inconclusive']}")
    print(f"  Total: {metrics['total']}")
    print(f"{'='*50}")


def main():
    parser = argparse.ArgumentParser(description="Evaluate DeepTrace model")
    parser.add_argument("--data", required=True, help="Path to test directory with real/ and fake/")
    parser.add_argument("--checkpoint", default=None, help="Model checkpoint path")
    parser.add_argument("--device", default=None, help="Override device")
    parser.add_argument("--batch-size", type=int, default=32)
    parser.add_argument("--calibrate", action="store_true", default=True,
                        help="Fit Platt scaling calibration")
    parser.add_argument("--no-calibrate", action="store_false", dest="calibrate")
    args = parser.parse_args()

    device = args.device or cfg.DEVICE

    # Load model — auto-detect architecture from checkpoint
    print("\nLoading model...")
    
    ckpt_path = args.checkpoint
    if not ckpt_path:
        # Try ViT first, then EfficientNet
        for name in ["vit_b_16_deeptrace_best.pth", "vit_b_16_deeptrace_final.pth",
                     "efficientnet_b2_deeptrace_best.pth", "efficientnet_b2_deeptrace_final.pth"]:
            candidate = WEIGHTS_DIR / name
            if candidate.exists():
                ckpt_path = str(candidate)
                break
    
    if not ckpt_path or not Path(ckpt_path).exists():
        print(f"  [ERROR] No checkpoint found")
        print(f"    Train the model first: python -m training.train --data <processed_dir>")
        sys.exit(1)
    
    ckpt = torch.load(ckpt_path, map_location=device, weights_only=False)
    state_dict = ckpt.get("model_state_dict", ckpt)
    config = ckpt.get("config", {})
    arch = config.get("architecture", "efficientnet_b2").lower()
    
    print(f"  Checkpoint: {ckpt_path}")
    print(f"  Architecture: {arch}")
    if "config" in ckpt:
        print(f"  Training date: {ckpt['config'].get('training_date', 'N/A')}")
        print(f"  Test accuracy at training: {ckpt['config'].get('test_accuracy', 'N/A')}")
    
    # Build model based on architecture
    if arch.startswith("vit"):
        from services.model import ViTClassifier, create_classifier
        model = create_classifier(arch)
    else:
        model = models.efficientnet_b2(weights=None)
        num_features = model.classifier[1].in_features
        model.classifier = nn.Sequential(
            nn.Dropout(p=0.3, inplace=True),
            nn.Linear(num_features, 256),
            nn.ReLU(inplace=True),
            nn.Dropout(p=0.2),
            nn.Linear(256, NUM_CLASSES),
        )
    
    try:
        model.load_state_dict(state_dict, strict=True)
    except RuntimeError:
        # Try with backbone prefix
        prefixed = {("backbone." + k): v for k, v in state_dict.items()}
        model.load_state_dict(prefixed, strict=True)

    model = model.to(device)

    # Load test data
    test_dir = Path(args.data)
    transform = get_val_transforms()
    dataset = EvalDataset(test_dir, transform=transform)
    loader = DataLoader(dataset, batch_size=args.batch_size, shuffle=False, num_workers=0)

    print(f"\nTest set: {len(dataset)} images")
    class_counts = {}
    for _, label in dataset.samples:
        class_name = "real" if label == 0 else "fake"
        class_counts[class_name] = class_counts.get(class_name, 0) + 1
    print(f"  Real: {class_counts.get('real', 0)}, Fake: {class_counts.get('fake', 0)}")

    # Evaluate without calibration
    print("\nRunning inference...")
    raw_probs, labels = evaluate_model(model, loader, device)

    raw_metrics = compute_metrics(raw_probs, labels)
    print_metrics(raw_metrics, "Raw Model (No Calibration)")

    # Calibrate
    calibrator = PlattScaler()
    if args.calibrate:
        # Split data for calibration fitting
        n = len(labels)
        cal_size = int(n * 0.3)  # Use 30% for calibration fitting
        indices = np.random.RandomState(42).permutation(n)
        cal_idx = indices[:cal_size]

        print("\nFitting Platt scaling calibration...")
        calibrator.fit(raw_probs[cal_idx], labels[cal_idx])

        # Apply calibration to all scores
        calibrated_probs = calibrator.calibrate(raw_probs)
        cal_metrics = compute_metrics(calibrated_probs, labels)
        print_metrics(cal_metrics, "Calibrated Model (Platt Scaling)")

        # Save calibration
        cal_path = WEIGHTS_DIR / "calibrator.pkl"
        calibrator.save(cal_path)

    # Save full evaluation report
    report = {
        "checkpoint": str(ckpt_path),
        "test_dir": str(test_dir),
        "num_samples": len(dataset),
        "class_counts": class_counts,
        "raw_metrics": {k: v for k, v in raw_metrics.items()
                       if k not in ("fpr", "tpr")},
    }

    if args.calibrate:
        report["calibrated_metrics"] = {k: v for k, v in cal_metrics.items()
                                        if k not in ("fpr", "tpr")}
        report["platt_params"] = {"a": calibrator.a, "b": calibrator.b}

    report_path = WEIGHTS_DIR / "evaluation_report.json"
    with open(report_path, "w") as f:
        json.dump(report, f, indent=2)
    print(f"\nFull report saved to {report_path}")


if __name__ == "__main__":
    main()
