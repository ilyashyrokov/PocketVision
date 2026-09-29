# Pocket Vision image classifier model card

## Bundled model

- **Architecture:** TorchVision MobileNetV3-Small.
- **Weights:** `MobileNet_V3_Small_Weights.IMAGENET1K_V1` pretrained on ImageNet-1K.
- **Task:** single-label classification over 1,000 ImageNet-1K categories.
- **Examples:** laptop, perfume, keyboard, phone, animals, vehicles, food, and places.
- **Input:** 224 × 224 RGB, center-cropped by Vision; ImageNet mean/std normalization is embedded in the model.
- **On-device format:** Core ML FP16, bundled at `PocketVision/Models/PocketVisionClassifier.mlpackage`.
- **Inference:** on device; no image upload or network service.

## Published evaluation

TorchVision reports these ImageNet-1K validation metrics for the selected pretrained weights:

| Metric | Result |
| --- | ---: |
| Top-1 accuracy | 67.668% |
| Top-5 accuracy | 87.402% |

These published benchmark figures describe the pretrained weights on ImageNet-1K. They are not measurements on Pocket Vision user photos. The repository's 96.9% Top-1 Imagenette result belongs to a separate 10-class fine-tuning experiment and is retained in `ml/results/pocketvision-imagenette-validation.json`.

## Limits and use

- The app displays one best label; it is not an object detector and does not identify multiple objects in a scene.
- The model only knows its 1,000 ImageNet-1K labels. It can still return a nearest label for objects outside those categories.
- Below a 50% top score, the app presents the model's top labels as unconfirmed suggestions instead of a recognized result. This is a conservative UI heuristic, not a calibrated open-set detector.
- The app displays a softmax score, not a calibrated probability of correctness.
- Results vary with cropping, lighting, image quality, and how closely an object matches the training categories.
- This is a portfolio project and should not be used for safety-critical decisions.

## Reproduction

See `README.md` for Core ML export and evaluation commands. TorchVision's pretrained weights are obtained through the pinned TorchVision package. The separate Imagenette dataset is not included.

## Sources and notices

- [TorchVision MobileNetV3-Small weights and model documentation](https://docs.pytorch.org/vision/main/models/generated/torchvision.models.mobilenet_v3_small.html)
- [TorchVision license](https://github.com/pytorch/vision/blob/main/LICENSE)
- [Imagenette dataset](https://github.com/fastai/imagenette)
