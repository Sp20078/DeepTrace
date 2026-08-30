"""
DeepTrace Model Training
========================
Trains EfficientNet-B2 or ViT for binary deepfake detection with:
- Mixed precision (AMP)
- Cosine annealing LR scheduler
- Label smoothing
- Early stopping
- Best checkpoint saving

Usage:
    # Train ViT-B/16 (default)
    python -m training.train --data backend/data/processed

    # Train EfficientNet-B2
    python -m training.train --data backend/data/processed --architecture efficientnet_b2

    # Train with custom settings
    python -m training.train --data backend/data/processed --architecture vit_b_16 --epochs 30 --lr 5e-5
"""

import argparse
import json
import sys
import time
from datetime import datetime
from pathlib import Path

import torch
import torch.nn as nn
import torch.optim as optim
from torch.cuda.amp import GradScaler, autocast
from torchvision import models

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from training.config import (
    ARCHITECTURE,
    ARCH_CONFIGS,
    NUM_CLASSES,
    NUM_EPOCHS,
    LEARNING_RATE,
    WEIGHT_DECAY,
    LABEL_SMOOTHING,
    EARLY_STOP_PATIENCE,
    BATCH_SIZE,
    USE_AMP,
    DEVICE,
    WEIGHTS_DIR,
    CHECKPOINTS_DIR,
    SAVE_BEST_N,
    LOG_EVERY_N_STEPS,
)
from training.dataset import create_dataloaders


# ── Model Definition ──────────────────────────────────────────────────────

def create_model(architecture: str = ARCHITECTURE, num_classes: int = NUM_CLASSES, pretrained: bool = True):
    """
    Create a model for binary classification.

    Args:
        architecture: Model architecture name (efficientnet_b2, vit_b_16, vit_b_32, vit_l_16)
        num_classes: Number of output classes (2 for real/fake)
        pretrained: Whether to use ImageNet pretrained weights

    Returns:
        nn.Module model ready for training
    """
    arch_configs = ARCH_CONFIGS.get(architecture, {})

    if architecture == "efficientnet_b2":
        weights = "IMAGENET1K_V1" if pretrained else None
        model = models.efficientnet_b2(weights=weights)
        num_features = model.classifier[1].in_features
        model.classifier = nn.Sequential(
            nn.Dropout(p=0.3, inplace=True),
            nn.Linear(num_features, 256),
            nn.ReLU(inplace=True),
            nn.Dropout(p=0.2),
            nn.Linear(256, num_classes),
        )

    elif architecture == "vit_b_16":
        weights = "IMAGENET1K_V1" if pretrained else None
        model = models.vit_b_16(weights=weights)
        hidden_dim = model.hidden_dim  # 768
        model.heads = nn.Sequential(
            nn.Dropout(p=0.3),
            nn.Linear(hidden_dim, 256),
            nn.ReLU(inplace=True),
            nn.Dropout(p=0.2),
            nn.Linear(256, num_classes),
        )

    elif architecture == "vit_b_32":
        weights = "IMAGENET1K_V1" if pretrained else None
        model = models.vit_b_32(weights=weights)
        hidden_dim = model.hidden_dim  # 768
        model.heads = nn.Sequential(
            nn.Dropout(p=0.3),
            nn.Linear(hidden_dim, 256),
            nn.ReLU(inplace=True),
            nn.Dropout(p=0.2),
            nn.Linear(256, num_classes),
        )

    elif architecture == "vit_l_16":
        weights = "IMAGENET1K_V1" if pretrained else None
        model = models.vit_l_16(weights=weights)
        hidden_dim = model.hidden_dim  # 1024
        model.heads = nn.Sequential(
            nn.Dropout(p=0.3),
            nn.Linear(hidden_dim, 256),
            nn.ReLU(inplace=True),
            nn.Dropout(p=0.2),
            nn.Linear(256, num_classes),
        )

    else:
        raise ValueError(f"Unknown architecture: {architecture}. "
                         f"Available: {list(ARCH_CONFIGS.keys())}")

    return model


def freeze_early_layers(model, architecture: str = ARCHITECTURE, freeze_until: int = None):
    """
    Freeze early layers for transfer learning.
    For ViT: freezes encoder layers up to freeze_until.
    For EfficientNet: freezes feature blocks up to freeze_until.
    """
    if freeze_until is None:
        freeze_until = ARCH_CONFIGS.get(architecture, {}).get("freeze_until", 6)

    if "vit" in architecture:
        # ViT has encoder.layers — freeze up to layer index
        if hasattr(model, "encoder") and hasattr(model.encoder, "layers"):
            layers = model.encoder.layers
            for i, layer in enumerate(layers):
                if i < freeze_until:
                    for param in layer.parameters():
                        param.requires_grad = False
            # Also freeze conv_proj (patch embedding) always
            for param in model.conv_proj.parameters():
                param.requires_grad = False
        # For torchvision ViT, the structure is different
        # It has encoder.layers, but the attribute name might vary
        # Let's try the direct approach
        total = sum(p.numel() for p in model.parameters())
        trainable = sum(p.numel() for p in model.parameters() if p.requires_grad)
        print(f"  Frozen early ViT layers, training last layers + head")
        print(f"  Trainable params: {trainable:,} / {total:,} ({100 * trainable / total:.1f}%)")

    elif architecture == "efficientnet_b2":
        # Freeze features up to the specified block
        for i, block in enumerate(model.features):
            if i < freeze_until:
                for param in block.parameters():
                    param.requires_grad = False

        trainable = sum(p.numel() for p in model.parameters() if p.requires_grad)
        total = sum(p.numel() for p in model.parameters())
        print(f"  Frozen layers 0-{freeze_until - 1}, training layers {freeze_until}-end")
        print(f"  Trainable params: {trainable:,} / {total:,} ({100 * trainable / total:.1f}%)")
    else:
        print(f"  No layer freezing for architecture: {architecture}")


# ── Training Loop ──────────────────────────────────────────────────────────

class EarlyStopping:
    """Stop training when validation loss stops improving."""

    def __init__(self, patience: int = EARLY_STOP_PATIENCE, min_delta: float = 1e-4):
        self.patience = patience
        self.min_delta = min_delta
        self.counter = 0
        self.best_loss = None
        self.should_stop = False

    def __call__(self, val_loss: float) -> bool:
        if self.best_loss is None:
            self.best_loss = val_loss
            return False

        if val_loss < self.best_loss - self.min_delta:
            self.best_loss = val_loss
            self.counter = 0
            return False
        else:
            self.counter += 1
            if self.counter >= self.patience:
                self.should_stop = True
                return True
            return False


def train_one_epoch(model, loader, criterion, optimizer, scaler, device, epoch):
    """Train for one epoch."""
    model.train()
    running_loss = 0.0
    correct = 0
    total = 0

    for batch_idx, (images, labels) in enumerate(loader):
        images = images.to(device, non_blocking=True)
        labels = labels.to(device, non_blocking=True)

        optimizer.zero_grad(set_to_none=True)

        if scaler is not None:
            with autocast():
                outputs = model(images)
                loss = criterion(outputs, labels)
            scaler.scale(loss).backward()
            scaler.unscale_(optimizer)
            torch.nn.utils.clip_grad_norm_(model.parameters(), max_norm=1.0)
            scaler.step(optimizer)
            scaler.update()
        else:
            outputs = model(images)
            loss = criterion(outputs, labels)
            loss.backward()
            torch.nn.utils.clip_grad_norm_(model.parameters(), max_norm=1.0)
            optimizer.step()

        running_loss += loss.item() * images.size(0)
        _, predicted = outputs.max(1)
        total += labels.size(0)
        correct += predicted.eq(labels).sum().item()

        if (batch_idx + 1) % LOG_EVERY_N_STEPS == 0:
            batch_loss = loss.item()
            batch_acc = 100.0 * predicted.eq(labels).sum().item() / labels.size(0)
            print(f"    Batch {batch_idx + 1}/{len(loader)}: "
                  f"loss={batch_loss:.4f} acc={batch_acc:.1f}%")

    epoch_loss = running_loss / total
    epoch_acc = 100.0 * correct / total
    return epoch_loss, epoch_acc


@torch.no_grad()
def validate(model, loader, criterion, device):
    """Validate and return loss + accuracy + AUC."""
    model.eval()
    running_loss = 0.0
    correct = 0
    total = 0
    all_probs = []
    all_labels = []

    for images, labels in loader:
        images = images.to(device, non_blocking=True)
        labels = labels.to(device, non_blocking=True)

        outputs = model(images)
        loss = criterion(outputs, labels)

        probs = torch.softmax(outputs, dim=1)[:, 1]  # fake probability
        running_loss += loss.item() * images.size(0)
        _, predicted = outputs.max(1)
        total += labels.size(0)
        correct += predicted.eq(labels).sum().item()

        all_probs.extend(probs.cpu().numpy().tolist())
        all_labels.extend(labels.cpu().numpy().tolist())

    epoch_loss = running_loss / total
    epoch_acc = 100.0 * correct / total

    # Compute AUC if sklearn available
    try:
        from sklearn.metrics import roc_auc_score
        auc = roc_auc_score(all_labels, all_probs)
    except ImportError:
        auc = 0.0

    return epoch_loss, epoch_acc, auc


def train(args):
    """Main training function."""
    architecture = args.architecture
    arch_display = architecture.upper().replace("_", "/")
    arch_config = ARCH_CONFIGS.get(architecture, {})

    print(f"\n{'='*60}")
    print("DeepTrace Model Training")
    print(f"{'='*60}")
    print(f"Date: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"Device: {DEVICE}")
    print(f"Architecture: {arch_display}")
    print(f"Epochs: {args.epochs}")
    print(f"Batch size: {args.batch_size}")
    print(f"Learning rate: {args.lr}")
    print(f"AMP: {args.amp}")
    print(f"{'='*60}")

    # Create dataloaders
    train_loader, val_loader, test_loader = create_dataloaders(
        args.data, batch_size=args.batch_size
    )

    # Create model
    print(f"\nCreating {arch_display} model...")
    model = create_model(architecture=architecture, pretrained=True)
    model = model.to(DEVICE)

    # Freeze early layers for faster fine-tuning
    freeze_early_layers(model, architecture=architecture)

    # Loss, optimizer, scheduler

    # Compute class weights from training data to handle imbalance
    train_labels = [label for _, label in train_loader.dataset.samples]
    n_real = sum(1 for l in train_labels if l == 0)
    n_fake = sum(1 for l in train_labels if l == 1)
    total = n_real + n_fake
    # Inverse frequency weighting: minority class gets higher weight
    class_weights = torch.tensor([
        total / (2.0 * n_real),   # weight for real (class 0)
        total / (2.0 * n_fake),   # weight for fake (class 1)
    ], device=DEVICE)
    print(f"\n  Class distribution — real: {n_real}, fake: {n_fake}")
    print(f"  Class weights — real: {class_weights[0]:.3f}, fake: {class_weights[1]:.3f}")

    criterion = nn.CrossEntropyLoss(
        weight=class_weights,
        label_smoothing=args.label_smoothing,
    )

    optimizer = optim.AdamW(
        filter(lambda p: p.requires_grad, model.parameters()),
        lr=args.lr,
        weight_decay=args.weight_decay,
    )

    if args.scheduler == "cosine":
        scheduler = optim.lr_scheduler.CosineAnnealingLR(
            optimizer, T_max=args.epochs - args.warmup_epochs, eta_min=1e-6
        )
    elif args.scheduler == "plateau":
        scheduler = optim.lr_scheduler.ReduceLROnPlateau(
            optimizer, mode="min", factor=0.5, patience=2
        )
    else:
        scheduler = optim.lr_scheduler.StepLR(optimizer, step_size=5, gamma=0.1)

    # AMP scaler
    scaler = GradScaler() if args.amp and DEVICE == "cuda" else None

    # Early stopping
    early_stopping = EarlyStopping(patience=args.patience)

    # Checkpoint tracking
    best_checkpoints = []
    CHECKPOINTS_DIR.mkdir(parents=True, exist_ok=True)

    # Training history
    history = {
        "train_loss": [], "train_acc": [],
        "val_loss": [], "val_acc": [], "val_auc": [],
        "lr": [], "epoch_time": [],
    }

    print(f"\nTraining for {args.epochs} epochs...\n")
    start_time = time.time()

    for epoch in range(args.epochs):
        epoch_start = time.time()
        current_lr = optimizer.param_groups[0]["lr"]

        print(f"Epoch {epoch + 1}/{args.epochs} (lr={current_lr:.2e})")
        print("-" * 40)

        # Train
        train_loss, train_acc = train_one_epoch(
            model, train_loader, criterion, optimizer, scaler, DEVICE, epoch
        )

        # Validate
        val_loss, val_acc, val_auc = validate(model, val_loader, criterion, DEVICE)

        epoch_time = time.time() - epoch_start

        # Log
        history["train_loss"].append(train_loss)
        history["train_acc"].append(train_acc)
        history["val_loss"].append(val_loss)
        history["val_acc"].append(val_acc)
        history["val_auc"].append(val_auc)
        history["lr"].append(current_lr)
        history["epoch_time"].append(epoch_time)

        print(f"  Train: loss={train_loss:.4f} acc={train_acc:.1f}%")
        print(f"  Val:   loss={val_loss:.4f} acc={val_acc:.1f}% AUC={val_auc:.4f}")
        print(f"  Time:  {epoch_time:.1f}s")

        # Save checkpoint
        checkpoint = {
            "epoch": epoch + 1,
            "model_state_dict": model.state_dict(),
            "optimizer_state_dict": optimizer.state_dict(),
            "val_loss": val_loss,
            "val_acc": val_acc,
            "val_auc": val_auc,
            "train_loss": train_loss,
            "train_acc": train_acc,
            "config": {
                "architecture": architecture,
                "model": architecture,
                "num_classes": NUM_CLASSES,
                "input_size": 224,
            },
        }

        ckpt_path = CHECKPOINTS_DIR / f"{architecture}_epoch_{epoch + 1:03d}.pth"
        torch.save(checkpoint, ckpt_path)

        # Track best checkpoints
        best_checkpoints.append((val_auc, ckpt_path))
        best_checkpoints.sort(reverse=True)
        if len(best_checkpoints) > SAVE_BEST_N:
            worst = best_checkpoints.pop()
            if worst[1].exists():
                worst[1].unlink()

        # Save best model
        if val_auc == max(c[0] for c in best_checkpoints):
            best_path = WEIGHTS_DIR / f"{architecture}_deeptrace_best.pth"
            torch.save(checkpoint, best_path)
            print(f"  ★ New best model saved (AUC={val_auc:.4f})")

        # Scheduler step
        if args.scheduler == "plateau":
            scheduler.step(val_loss)
        elif epoch >= args.warmup_epochs:
            scheduler.step()

        # Early stopping
        if early_stopping(val_loss):
            print(f"\n⚠ Early stopping at epoch {epoch + 1}")
            break

        print()

    total_time = time.time() - start_time
    print(f"\n{'='*60}")
    print(f"Training complete in {total_time / 60:.1f} minutes")
    print(f"Best checkpoints: {[f'AUC={c[0]:.4f}' for c in best_checkpoints]}")

    # Evaluate on test set
    print(f"\n{'='*60}")
    print("Final Test Set Evaluation")
    print(f"{'='*60}")

    # Load best model
    best_model_path = WEIGHTS_DIR / f"{architecture}_deeptrace_best.pth"
    if best_model_path.exists():
        ckpt = torch.load(best_model_path, map_location=DEVICE, weights_only=False)
        model.load_state_dict(ckpt["model_state_dict"])
        print(f"Loaded best model from epoch {ckpt['epoch']}")

    test_loss, test_acc, test_auc = validate(model, test_loader, criterion, DEVICE)
    print(f"  Test Loss:     {test_loss:.4f}")
    print(f"  Test Accuracy: {test_acc:.1f}%")
    print(f"  Test AUC:      {test_auc:.4f}")

    # Save history
    history_path = WEIGHTS_DIR / f"{architecture}_training_history.json"
    with open(history_path, "w") as f:
        json.dump(history, f, indent=2)
    print(f"\nTraining history saved to {history_path}")

    # Save final model (non-checkpoint, inference-only)
    final_path = WEIGHTS_DIR / f"{architecture}_deeptrace_final.pth"
    torch.save({
        "model_state_dict": model.state_dict(),
        "config": {
            "architecture": architecture,
            "model": architecture,
            "num_classes": NUM_CLASSES,
            "input_size": 224,
            "training_date": datetime.now().isoformat(),
            "test_accuracy": test_acc,
            "test_auc": test_auc,
            "trained_on": "custom_dataset",
        },
    }, final_path)
    print(f"Final model saved to {final_path}")

    print(f"\n{'='*60}")
    print("Next step: python -m training.evaluate --data <test_dir>")
    print(f"{'='*60}")


def main():
    parser = argparse.ArgumentParser(description="Train DeepTrace deepfake detection model")
    parser.add_argument("--data", required=True, help="Path to processed data directory")
    parser.add_argument("--architecture", default=ARCHITECTURE,
                        choices=list(ARCH_CONFIGS.keys()),
                        help=f"Model architecture (default: {ARCHITECTURE})")
    parser.add_argument("--epochs", type=int, default=NUM_EPOCHS)
    parser.add_argument("--batch-size", type=int, default=None,
                        help="Batch size (default: architecture-specific)")
    parser.add_argument("--lr", type=float, default=None,
                        help="Learning rate (default: architecture-specific)")
    parser.add_argument("--weight-decay", type=float, default=WEIGHT_DECAY)
    parser.add_argument("--label-smoothing", type=float, default=LABEL_SMOOTHING)
    parser.add_argument("--patience", type=int, default=EARLY_STOP_PATIENCE)
    parser.add_argument("--scheduler", default="cosine", choices=["cosine", "plateau", "step"])
    parser.add_argument("--warmup-epochs", type=int, default=2)
    parser.add_argument("--amp", action="store_true", default=USE_AMP)
    parser.add_argument("--no-amp", action="store_false", dest="amp")
    parser.add_argument("--device", default=None, help="Override device (cuda/cpu)")
    args = parser.parse_args()

    # Apply architecture-specific defaults for batch size and lr
    arch_config = ARCH_CONFIGS.get(args.architecture, {})
    if args.batch_size is None:
        args.batch_size = arch_config.get("batch_size", BATCH_SIZE)
    if args.lr is None:
        args.lr = arch_config.get("lr", LEARNING_RATE)

    if args.device:
        import training.config as cfg
        cfg.DEVICE = args.device

    train(args)


if __name__ == "__main__":
    main()
