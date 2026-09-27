import CoreGraphics
import XCTest
import UIKit
@testable import PocketVision

final class PocketVisionTests: XCTestCase {
    func testRecognitionStatusThresholds() {
        XCTAssertEqual(RecognitionStatus(score: 0.70), .likely)
        XCTAssertEqual(RecognitionStatus(score: 0.50), .possible)
        XCTAssertEqual(RecognitionStatus(score: 0.699), .possible)
        XCTAssertEqual(RecognitionStatus(score: 0.499), .unsure)
        XCTAssertEqual(RecognitionStatus(score: 0.349), .unsure)
    }

    @MainActor
    func testRecognitionStorePersistsAndDeletesRecordAndImage() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = RecognitionStore(rootURL: root)
        let image = makeImage()
        let predictions = [Prediction(label: "Мяч для гольфа", score: 0.92)]

        let saved = try store.save(image: image, predictions: predictions)
        XCTAssertEqual(try store.load(), [saved])
        XCTAssertNotNil(store.image(for: saved))
        XCTAssertEqual(saved.predictions, predictions)

        try store.delete(saved)
        XCTAssertTrue(try store.load().isEmpty)
        XCTAssertNil(store.image(for: saved))
    }

    @MainActor
    func testBundledCoreMLClassifierReturnsThreePredictions() async throws {
        let predictions = try await ImageClassifier().classify(makeImage())
        XCTAssertEqual(predictions.count, 3)
        XCTAssertTrue(predictions.allSatisfy { !$0.label.isEmpty && (0...1).contains($0.score) })
        XCTAssertEqual(predictions, predictions.sorted { $0.score > $1.score })
    }

    func testBundledLabelsIncludeLaptopAndPerfumeInRussian() throws {
        struct ClassLabel: Decodable {
            let english: String
            let russian: String
        }

        let bundle = Bundle(for: PocketVisionModel.self)
        let url = try XCTUnwrap(bundle.url(forResource: "ImageNetClassLabels", withExtension: "json"))
        let labels = try JSONDecoder().decode([ClassLabel].self, from: Data(contentsOf: url))
        let labelsByEnglish = Dictionary(uniqueKeysWithValues: labels.map { ($0.english, $0.russian) })

        XCTAssertEqual(labels.count, 1_000)
        XCTAssertEqual(labelsByEnglish["laptop"], "Ноутбук")
        XCTAssertEqual(labelsByEnglish["perfume"], "Духи")
    }


    @MainActor
    func testPocketVisionModelSavesRecordAndSubmitsFeedbackOnlyOnce() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = RecognitionStore(rootURL: root)
        let model = PocketVisionModel(store: store)
        model.selectedImage = makeImage()
        model.predictions = [Prediction(label: "Мяч для гольфа", score: 0.92)]

        model.saveCurrent()
        model.saveCurrent()
        XCTAssertEqual(model.history.count, 1)
        XCTAssertNotNil(model.activeRecordID)

        model.submitFeedback(isCorrect: false)
        model.submitFeedback(isCorrect: true)
        XCTAssertTrue(model.feedbackSubmitted)
        XCTAssertEqual(try store.loadFeedback().count, 1)
        XCTAssertFalse(try store.loadFeedback()[0].isCorrect)

        model.delete(model.history[0])
        XCTAssertTrue(model.history.isEmpty)
        XCTAssertNil(model.activeRecordID)
    }

    @MainActor
    func testSaveFailureIsShownToTheUser() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try Data("not a folder".utf8).write(to: root)
        defer { try? FileManager.default.removeItem(at: root) }

        let model = PocketVisionModel(store: RecognitionStore(rootURL: root))
        model.selectedImage = makeImage()
        model.predictions = [Prediction(label: "Мяч для гольфа", score: 0.92)]

        model.saveCurrent()

        XCTAssertEqual(model.errorMessage, "Не удалось сохранить запись. Проверьте свободное место на iPhone и попробуйте снова.")
        XCTAssertTrue(model.history.isEmpty)
        XCTAssertNil(model.activeRecordID)
    }

    @MainActor
    func testUnreadableHistoryProducesRecoverableMessage() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        try Data("broken json".utf8).write(to: root.appendingPathComponent("history.json"))
        defer { try? FileManager.default.removeItem(at: root) }

        let model = PocketVisionModel(store: RecognitionStore(rootURL: root))

        XCTAssertTrue(model.history.isEmpty)
        XCTAssertEqual(model.errorMessage, "Не удалось загрузить коллекцию. Сохранённые записи могут быть повреждены.")
    }

    @MainActor
    func testResetRecognitionClearsTransientState() {
        let model = PocketVisionModel(store: RecognitionStore(rootURL: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)))
        model.selectedImage = makeImage()
        model.predictions = [Prediction(label: "Линь", score: 0.8)]
        model.errorMessage = "ошибка"
        model.feedbackSubmitted = true

        model.resetRecognition()

        XCTAssertNil(model.selectedImage)
        XCTAssertTrue(model.predictions.isEmpty)
        XCTAssertNil(model.errorMessage)
        XCTAssertFalse(model.feedbackSubmitted)
    }

    @MainActor
    private func makeImage() -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: 224, height: 224), format: format).image { context in
            UIColor(red: 0.1, green: 0.45, blue: 0.8, alpha: 1).setFill()
            context.fill(CGRect(x: 0, y: 0, width: 224, height: 224))
            UIColor.white.setFill()
            context.fill(CGRect(x: 48, y: 48, width: 128, height: 128))
        }
    }
}
