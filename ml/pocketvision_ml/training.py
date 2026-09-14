"""Reusable training helpers for the MobileNetV3 fine-tuning CLI."""

import random

import torch


def split_by_class(samples, seed):
    """Create a deterministic, class-stratified split from ImageFolder samples."""
    rng = random.Random(seed)
    buckets = {}
    for index, (_, target) in enumerate(samples):
        buckets.setdefault(target, []).append(index)
    train_indices, validation_indices = [], []
    for indices in buckets.values():
        rng.shuffle(indices)
        validation_count = max(1, round(len(indices) * 0.1))
        validation_indices.extend(indices[:validation_count])
        train_indices.extend(indices[validation_count:])
    rng.shuffle(train_indices)
    rng.shuffle(validation_indices)
    return train_indices, validation_indices


def set_frozen_feature_blocks_eval(model):
    """Keep frozen feature blocks in inference mode during fine-tuning."""
    for block in model.features:
        if not any(parameter.requires_grad for parameter in block.parameters()):
            block.eval()


def run_epoch(model, loader, criterion, device, optimizer=None):
    """Run one train or evaluation epoch and return aggregate metrics."""
    training = optimizer is not None
    model.train(training)
    if training:
        set_frozen_feature_blocks_eval(model)
    loss_total = top1_total = top3_total = count = 0
    for images, labels in loader:
        images, labels = images.to(device), labels.to(device)
        if training:
            optimizer.zero_grad(set_to_none=True)
        with torch.set_grad_enabled(training):
            logits = model(images)
            loss = criterion(logits, labels)
            if training:
                loss.backward()
                optimizer.step()
        batch_size = labels.size(0)
        count += batch_size
        loss_total += loss.item() * batch_size
        top1_total += (logits.argmax(1) == labels).sum().item()
        top3_total += (logits.topk(3, dim=1).indices == labels[:, None]).any(1).sum().item()
    if count == 0:
        raise ValueError("Cannot compute metrics for an empty data loader")
    return {"loss": loss_total / count, "top1": top1_total / count, "top3": top3_total / count, "images": count}
