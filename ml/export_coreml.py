#!/usr/bin/env python3
"""Export the fine-tuned MobileNetV3 checkpoint as an image-input Core ML classifier."""

import argparse
import json
from pathlib import Path

import coremltools as ct
import torch
from torch import nn
from torchvision.models import MobileNet_V3_Small_Weights, mobilenet_v3_small

from pocketvision_ml.labels import RUSSIAN_LABELS
from pocketvision_ml.preprocessing import MEAN, STD


class ImageNetNormalizedModel(nn.Module):
    def __init__(self, model):
        super().__init__()
        self.model = model
        self.register_buffer("mean", torch.tensor(MEAN).view(1, 3, 1, 1))
        self.register_buffer("std", torch.tensor(STD).view(1, 3, 1, 1))

    def forward(self, image):
        logits = self.model((image - self.mean) / self.std)
        return torch.softmax(logits, dim=1)


def parse_args():
    parser = argparse.ArgumentParser()
    source = parser.add_mutually_exclusive_group(required=True)
    source.add_argument("--checkpoint", type=Path, help="Pocket Vision fine-tuning checkpoint")
    source.add_argument("--imagenet-pretrained", action="store_true", help="Export the full 1,000-class TorchVision ImageNet model")
    parser.add_argument("--labels", type=Path, default=Path("ml/imagenet_class_index.json"))
    parser.add_argument("--class-labels-output", type=Path, default=Path("ml/models/imagenet1k_class_labels.json"))
    parser.add_argument("--output", type=Path, required=True)
    return parser.parse_args()


def main():
    args = parse_args()
    if args.imagenet_pretrained:
        weights = MobileNet_V3_Small_Weights.IMAGENET1K_V1
        model = mobilenet_v3_small(weights=weights)
        label_index = json.loads(args.labels.read_text())
        categories = weights.meta["categories"]
        if len(categories) != 1000 or len(label_index) != 1000:
            raise RuntimeError("ImageNet export requires exactly 1,000 category labels")
        classes = []
        for index, english in enumerate(categories):
            synset, _ = label_index[str(index)]
            classes.append({
                "synset": synset,
                "english": english,
                "russian": RUSSIAN_LABELS.get(english, english.title()),
            })
    else:
        checkpoint = torch.load(args.checkpoint, map_location="cpu", weights_only=False)
        model = mobilenet_v3_small(weights=None)
        model.classifier[3] = nn.Linear(model.classifier[3].in_features, len(checkpoint["classes"]))
        model.load_state_dict(checkpoint["state_dict"])
        classes = checkpoint["classes"]

    wrapped = ImageNetNormalizedModel(model).eval()
    sample = torch.zeros((1, 3, 224, 224), dtype=torch.float32)
    traced = torch.jit.trace(wrapped, sample, strict=True)
    labels = [entry["english"] for entry in classes]

    converted = ct.convert(
        traced,
        inputs=[ct.ImageType(
            name="image",
            shape=(1, 3, 224, 224),
            scale=1.0 / 255.0,
            bias=[0.0, 0.0, 0.0],
            color_layout=ct.colorlayout.RGB,
            channel_first=True,
        )],
        classifier_config=ct.ClassifierConfig(class_labels=labels),
        convert_to="mlprogram",
        minimum_deployment_target=ct.target.iOS17,
        compute_precision=ct.precision.FLOAT16,
    )
    converted.author = "TorchVision MobileNetV3-Small ImageNet-1K weights, exported by Pocket Vision"
    converted.short_description = "On-device image classifier for 1,000 ImageNet-1K categories."
    converted.version = "2.0.0" if args.imagenet_pretrained else "1.0.0"
    converted.license = "TorchVision BSD-3-Clause; see THIRD_PARTY_LICENSES.md."
    converted.user_defined_metadata["com.pocketvision.training"] = (
        "TorchVision MobileNet_V3_Small_Weights.IMAGENET1K_V1"
        if args.imagenet_pretrained else "Pocket Vision fine-tuning checkpoint"
    )
    converted.user_defined_metadata["com.pocketvision.classes"] = json.dumps(labels)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    converted.save(str(args.output))
    args.class_labels_output.parent.mkdir(parents=True, exist_ok=True)
    args.class_labels_output.write_text(json.dumps(classes, ensure_ascii=False, indent=2) + "\n")
    print(f"Saved {args.output} ({len(labels)} classes)")
    print(f"Saved class labels to {args.class_labels_output}")


if __name__ == "__main__":
    main()
