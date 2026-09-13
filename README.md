# Pocket Vision

A native SwiftUI portfolio app for private, on-device image classification. The app bundles a project-fine-tuned Core ML model and presents its supported categories and measured validation results transparently.

## Run

Open `PocketVision.xcodeproj` in Xcode and run the `PocketVision` scheme on iOS 17 or later. Camera capture requires a physical iPhone; Photos Picker works in Simulator.

## Source layout

- `PocketVision/Application` contains app state and orchestration.
- `PocketVision/Domain` contains recognition and history data types.
- `PocketVision/Recognition` runs on-device Core ML inference; `PocketVision/Persistence` stores saved records locally.
- `PocketVision/Features` contains the Recognition, Collection, and Model Info screens; `PocketVision/Shared` contains reusable UI elements.
- `ml/train.py`, `ml/export_coreml.py`, and `ml/evaluate_coreml.py` are the ML command-line entry points. Shared labels, normalization, and training helpers live in `ml/pocketvision_ml`.

## App features

- Take a photo or choose one with the system Photos Picker.
- Run the bundled classifier locally through Vision and Core ML.
- Show the three strongest labels and model scores.
- Save a photo and result to the local collection only after an explicit tap.
- Delete saved records or clear the collection.
- Store optional prediction feedback locally.
- Read model details, supported categories, and published benchmark metrics in the Model tab.

## Model and scope

The app bundles TorchVision MobileNetV3-Small pretrained on ImageNet-1K and exported to Core ML FP16. It can choose among **1,000 ImageNet categories**, including laptops and perfume. Images are center-cropped to 224 × 224 by Vision; ImageNet normalization is part of the exported model.

This is a single-label classifier, not an object detector or an unlimited general recognizer. An image outside its 1,000 supported categories can still receive the nearest label, so the home screen warns users about that limit. The app runs inference locally, and user images stay on device.

See [ModelCard.md](ModelCard.md) for training details, evaluation scope, limitations, and sources.

## Held-out evaluation

The bundled ImageNet-1K weights have the following published TorchVision validation metrics:

| Metric | Result |
| --- | ---: |
| Top-1 accuracy | 67.7% |
| Top-5 accuracy | 87.4% |

These are ImageNet-1K benchmark results for the original TorchVision weights, not an evaluation on user photos. The repository also retains a separate 10-class Imagenette fine-tuning experiment; its results are in [`ml/results/pocketvision-imagenette-validation.json`](ml/results/pocketvision-imagenette-validation.json) and do not describe the bundled model. Softmax scores shown in the app are not calibrated probabilities of correctness.

## Reproduce training and evaluation

Requires macOS or Linux, Python 3.10+, and the pinned dependencies in `requirements-ml.txt`. The pretrained TorchVision weights are cached or downloaded by TorchVision. Imagenette is only needed to reproduce the separate 10-class fine-tuning experiment; its images are not redistributed here.

```sh
curl -L https://s3.amazonaws.com/fast-ai-imageclas/imagenette2-160.tgz -o /tmp/imagenette2-160.tgz
mkdir -p /tmp/imagenette2-160
tar -xzf /tmp/imagenette2-160.tgz -C /tmp/imagenette2-160 --strip-components=1
python -m venv .venv
. .venv/bin/activate
python -m pip install -r requirements-ml.txt
python ml/export_coreml.py --imagenet-pretrained --labels ml/imagenet_class_index.json --class-labels-output PocketVision/Resources/ImageNetClassLabels.json --output PocketVision/Models/PocketVisionClassifier.mlpackage
python ml/evaluate_coreml.py --model PocketVision/Models/PocketVisionClassifier.mlpackage --labels PocketVision/Resources/ImageNetClassLabels.json --dataset-root /tmp/imagenette2-160 --output ml/results/pocketvision-imagenet1k-imagenette-subset.json
```

To reproduce the separate Imagenette experiment, run `ml/train.py` and export its checkpoint without replacing the bundled 1,000-class model.

Imagenette derives from ImageNet; applicable dataset terms remain in effect. TorchVision's BSD 3-Clause license and model source are linked in the model card.

## Tests

The `PocketVision` scheme includes XCTest unit tests and UI tests for the model, local persistence, recognition state, tab navigation, and camera picker. See [TESTING.md](TESTING.md) for the latest iPhone Simulator run and coverage report.

## Privacy

Classification runs on device. Photos are stored in Application Support only after the user chooses **Save to collection**. Optional feedback is also stored locally and is never uploaded.
