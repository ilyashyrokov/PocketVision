#!/usr/bin/env python3
"""Evaluate the exported Core ML package on Imagenette's held-out validation split."""

import argparse
import hashlib
import json
from pathlib import Path

import coremltools as ct
from PIL import Image
from torchvision import datasets, transforms


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--model", type=Path, required=True)
    parser.add_argument("--labels", type=Path, required=True)
    parser.add_argument("--dataset-root", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    return parser.parse_args()


def model_sha256(path):
    digest = hashlib.sha256()
    for item in sorted(path.rglob("*")):
        if item.is_file():
            digest.update(item.relative_to(path).as_posix().encode())
            with item.open("rb") as source:
                for chunk in iter(lambda: source.read(1024 * 1024), b""):
                    digest.update(chunk)
    return digest.hexdigest()


def main():
    args = parse_args()
    label_entries = json.loads(args.labels.read_text())
    english_by_synset = {entry["synset"]: entry["english"] for entry in label_entries}
    labels = [entry["english"] for entry in label_entries]
    dataset = datasets.ImageFolder(args.dataset_root / "val")
    model = ct.models.MLModel(str(args.model), compute_units=ct.ComputeUnit.ALL)
    prepare = transforms.Compose([transforms.Resize(224), transforms.CenterCrop(224)])
    per_class = []
    evaluation_labels = [english_by_synset[synset] for synset in dataset.classes if synset in english_by_synset]
    if len(evaluation_labels) != len(dataset.classes):
        missing = sorted(set(dataset.classes) - set(english_by_synset))
        raise RuntimeError(f"Missing class mappings for validation labels: {missing}")
    confusion = [[0 for _ in range(len(evaluation_labels) + 1)] for _ in evaluation_labels]
    class_to_position = {label: index for index, label in enumerate(evaluation_labels)}
    total_top1 = 0
    total_top3 = 0
    total = 0

    for synset in dataset.classes:
        expected = english_by_synset[synset]
        position = class_to_position[expected]
        paths = sorted((args.dataset_root / "val" / synset).glob("*"))
        count = 0
        top1_count = 0
        top3_count = 0
        for path in paths:
            if path.suffix.lower() not in {".jpg", ".jpeg", ".png"}:
                continue
            with Image.open(path) as image:
                rgb = image.convert("RGB")
                crop = prepare(rgb)
            result = model.predict({"image": crop})
            probability_key = next((key for key in result if key in {"classLabel_probs", "classProbability"}), None)
            if probability_key is None:
                raise RuntimeError(f"No class probability output in Core ML result keys: {list(result)}")
            probabilities = result[probability_key]
            ordered = sorted(probabilities.items(), key=lambda item: item[1], reverse=True)
            predicted = ordered[0][0]
            top_labels = [label for label, _ in ordered[:3]]

            count += 1
            total += 1
            correct = predicted == expected
            top1_count += int(correct)
            top3_count += int(expected in top_labels)
            total_top1 += int(correct)
            total_top3 += int(expected in top_labels)
            confusion[position][class_to_position.get(predicted, len(labels))] += 1

        per_class.append({
            "label": expected,
            "count": count,
            "top1Accuracy": top1_count / count if count else 0,
            "top3Accuracy": top3_count / count if count else 0,
        })
        print(f"{expected}: {top1_count}/{count} top-1, {top3_count}/{count} top-3", flush=True)

    report = {
        "model": args.model.name,
        "modelSHA256": model_sha256(args.model),
        "dataset": "Imagenette 2-160 validation",
        "images": total,
        "top1Accuracy": total_top1 / total,
        "top3Accuracy": total_top3 / total,
        "classes": per_class,
        "confusionLabels": evaluation_labels + ["other"],
        "confusionMatrix": confusion,
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n")
    print(f"Top-1: {report['top1Accuracy']:.1%}; top-3: {report['top3Accuracy']:.1%}; {total} images")
    print(f"Saved {args.output}")


if __name__ == "__main__":
    main()
