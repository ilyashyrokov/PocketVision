# Testing Pocket Vision

The shared `PocketVision` Xcode scheme runs both the unit and UI test targets on an iOS Simulator.

## Automated coverage

- Recognition status boundaries at 0.35 and 0.70.
- Local image/result persistence, reload, and deletion.
- Pocket Vision model state: save-once behavior, feedback deduplication, deletion, and reset.
- Real Core ML inference using a generated 224 × 224 image; checks the three returned labels, score bounds, and descending order.
- UI navigation across Camera, Collection, and Model tabs, including the displayed validation result.
- Opening and dismissing the system camera picker in Simulator.

Latest run: **7 passed, 0 failed** on iPhone 17 Simulator, iOS 26.2. Xcode line coverage for the app target was **56.95%**. `AppModel.swift` was 74.21% covered, `RootView.swift` 53.69%, and `CameraPicker.swift` 78.57%. The camera UI test checks that the system camera opens and closes. It does not capture an image. The Photos Picker UI is not exercised end to end; the classifier itself is tested directly with a generated image, and the exact bundled model was separately evaluated on 3,925 Imagenette validation images.

## Run

```sh
xcodebuild test \
  -project PocketVision.xcodeproj \
  -scheme PocketVision \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' \
  -derivedDataPath /tmp/PocketVisionDerived \
  -enableCodeCoverage YES \
  CODE_SIGNING_ALLOWED=YES \
  CODE_SIGNING_IDENTITY=-
```
