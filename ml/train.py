#!/usr/bin/env python3
"""Fine-tune MobileNetV3-Small on Imagenette with an internal train-only split."""

import argparse
import json
import random
from pathlib import Path

import torch
from torch import nn
from torch.utils.data import DataLoader, Subset
from torchvision import datasets, transforms
from torchvision.models import MobileNet_V3_Small_Weights, mobilenet_v3_small

from pocketvision_ml.labels import RUSSIAN_LABELS
from pocketvision_ml.preprocessing import MEAN, STD
from pocketvision_ml.training import run_epoch, split_by_class


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--dataset-root", type=Path, required=True)
    parser.add_argument("--labels", type=Path, required=True, help="ImageNet synset index JSON")
    parser.add_argument("--output-dir", type=Path, default=Path("ml/models"))
    parser.add_argument("--head-epochs", type=int, default=2)
    parser.add_argument("--finetune-epochs", type=int, default=2)
    parser.add_argument("--batch-size", type=int, default=32)
    parser.add_argument("--seed", type=int, default=42)
    parser.add_argument("--workers", type=int, default=0)
    return parser.parse_args()


def main():
    args = parse_args()
    random.seed(args.seed)
    torch.manual_seed(args.seed)
    torch.set_num_threads(max(1, min(6, torch.get_num_threads())))
    device = torch.device("mps" if torch.backends.mps.is_available() else "cpu")
    if torch.backends.mps.is_available():
        torch.mps.manual_seed(args.seed)

    train_dir = args.dataset_root / "train"
    imagenet_labels = json.loads(args.labels.read_text())
    label_by_synset = {value[0]: value[1].replace("_", " ") for value in imagenet_labels.values()}

    train_transform = transforms.Compose([
        transforms.RandomResizedCrop(224, scale=(0.72, 1.0)),
        transforms.RandomHorizontalFlip(),
        transforms.ColorJitter(brightness=0.08, contrast=0.08, saturation=0.08),
        transforms.ToTensor(),
        transforms.Normalize(MEAN, STD),
    ])
    evaluation_transform = transforms.Compose([
        transforms.Resize(224),
        transforms.CenterCrop(224),
        transforms.ToTensor(),
        transforms.Normalize(MEAN, STD),
    ])
    training_data = datasets.ImageFolder(train_dir, transform=train_transform)
    validation_data = datasets.ImageFolder(train_dir, transform=evaluation_transform)
    if training_data.class_to_idx != validation_data.class_to_idx:
        raise RuntimeError("Training and validation labels differ")
    train_indices, internal_validation_indices = split_by_class(training_data.samples, args.seed)
    generator = torch.Generator().manual_seed(args.seed)
    train_loader = DataLoader(
        Subset(training_data, train_indices), batch_size=args.batch_size, shuffle=True,
        num_workers=args.workers, generator=generator,
    )
    internal_validation_loader = DataLoader(
        Subset(validation_data, internal_validation_indices), batch_size=args.batch_size,
        shuffle=False, num_workers=args.workers,
    )

    weights = MobileNet_V3_Small_Weights.IMAGENET1K_V1
    model = mobilenet_v3_small(weights=weights)
    class_count = len(training_data.classes)
    model.classifier[3] = nn.Linear(model.classifier[3].in_features, class_count)
    for parameter in model.features.parameters():
        parameter.requires_grad = False
    model.to(device)
    criterion = nn.CrossEntropyLoss(label_smoothing=0.05)
    history = []
    best_top1 = -1.0
    best_state = None
    epoch_number = 0

    phases = [
        ("classifier", args.head_epochs, [{"params": model.classifier.parameters(), "lr": 2e-3}]),
        ("last_blocks", args.finetune_epochs, [
            {"params": [p for block in model.features[-4:] for p in block.parameters()], "lr": 1e-4},
            {"params": model.classifier.parameters(), "lr": 5e-4},
        ]),
    ]
    for phase, epochs, parameter_groups in phases:
        if phase == "last_blocks":
            for block in model.features[-4:]:
                for parameter in block.parameters():
                    parameter.requires_grad = True
        optimizer = torch.optim.AdamW(parameter_groups, weight_decay=1e-4)
        for _ in range(epochs):
            epoch_number += 1
            train_metrics = run_epoch(model, train_loader, criterion, device, optimizer)
            validation_metrics = run_epoch(model, internal_validation_loader, criterion, device)
            row = {
                "epoch": epoch_number,
                "phase": phase,
                "train": train_metrics,
                "internal_validation": validation_metrics,
            }
            history.append(row)
            print(
                f"epoch {epoch_number}/{args.head_epochs + args.finetune_epochs} "
                f"{phase}: train top-1 {train_metrics['top1']:.3f}; "
                f"internal validation top-1 {validation_metrics['top1']:.3f}",
                flush=True,
            )
            if validation_metrics["top1"] > best_top1:
                best_top1 = validation_metrics["top1"]
                best_state = {key: value.detach().cpu().clone() for key, value in model.state_dict().items()}

    if best_state is None:
        raise RuntimeError("Training did not produce a model checkpoint")
    model.load_state_dict(best_state)
    classes = []
    for synset in training_data.classes:
        english = label_by_synset.get(synset, synset)
        classes.append({
            "synset": synset,
            "english": english,
            "russian": RUSSIAN_LABELS.get(english, english.title()),
        })
    args.output_dir.mkdir(parents=True, exist_ok=True)
    checkpoint = {
        "state_dict": model.state_dict(),
        "classes": classes,
        "architecture": "torchvision.mobilenet_v3_small",
        "pretrained_weights": "MobileNet_V3_Small_Weights.IMAGENET1K_V1",
        "seed": args.seed,
        "best_internal_validation_top1": best_top1,
        "normalization": {"mean": MEAN, "std": STD},
    }
    torch.save(checkpoint, args.output_dir / "pocketvision_mobilenet_v3_small.pth")
    (args.output_dir / "class_labels.json").write_text(json.dumps(classes, ensure_ascii=False, indent=2) + "\n")
    history_document = {
        "dataset": "Imagenette 2-160 training split",
        "seed": args.seed,
        "device": str(device),
        "train_images": len(train_indices),
        "internal_validation_images": len(internal_validation_indices),
        "class_names": [item["english"] for item in classes],
        "best_internal_validation_top1": best_top1,
        "epochs": history,
    }
    history_path = args.output_dir.parent / "results" / "training-history.json"
    history_path.parent.mkdir(parents=True, exist_ok=True)
    history_path.write_text(json.dumps(history_document, ensure_ascii=False, indent=2) + "\n")
    print(f"Saved fine-tuned checkpoint to {args.output_dir / 'pocketvision_mobilenet_v3_small.pth'}")
    print(f"Best internal validation top-1: {best_top1:.3%}")


if __name__ == "__main__":
    main()
