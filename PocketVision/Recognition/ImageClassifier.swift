import CoreML
import Foundation
import ImageIO
import UIKit
import Vision

struct ImageClassifier {
    func classify(_ image: UIImage) async throws -> [Prediction] {
        guard let cgImage = image.cgImage else { throw ImageClassificationError.invalidImage }
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let request = VNCoreMLRequest(model: try PocketVisionRuntime.model.get())
                    request.imageCropAndScaleOption = .centerCrop
                    try VNImageRequestHandler(cgImage: cgImage, orientation: CGImagePropertyOrientation(image.imageOrientation)).perform([request])
                    let observations = (request.results as? [VNClassificationObservation] ?? []).prefix(3)
                    continuation.resume(returning: observations.map {
                        Prediction(label: Self.localized($0.identifier), score: Double($0.confidence))
                    })
                } catch {
                    if error is ImageClassificationError {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(throwing: ImageClassificationError.processingFailed)
                    }
                }
            }
        }
    }

    private static func localized(_ label: String) -> String {
        let translations = [
            "tench": "Линь",
            "English springer": "Английский спрингер-спаниель",
            "cassette player": "Кассетный плеер",
            "chain saw": "Бензопила",
            "church": "Церковь",
            "French horn": "Валторна",
            "garbage truck": "Мусоровоз",
            "gas pump": "Топливная колонка",
            "golf ball": "Мяч для гольфа",
            "parachute": "Парашют",
            "laptop": "Ноутбук",
            "notebook": "Ноутбук",
            "perfume": "Духи",
            "desktop computer": "Настольный компьютер",
            "computer keyboard": "Клавиатура",
            "computer mouse": "Компьютерная мышь",
            "monitor": "Монитор",
            "screen": "Экран",
            "television": "Телевизор",
            "cellular telephone": "Мобильный телефон",
            "smartphone": "Смартфон",
            "menu": "Меню",
            "pill bottle": "Флакон с лекарством",
            "packet": "Пакет",
            "envelope": "Конверт",
        ]
        return translations[label] ?? localizedImageNetLabels[label] ?? label.capitalized
    }

    private static let localizedImageNetLabels: [String: String] = {
        guard let url = Bundle.main.url(forResource: "ImageNetClassLabels", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let labels = try? JSONDecoder().decode([ImageNetClassLabel].self, from: data) else {
            return [:]
        }
        return Dictionary(uniqueKeysWithValues: labels.map { ($0.english, $0.russian) })
    }()

}

private struct ImageNetClassLabel: Decodable {
    let english: String
    let russian: String
}

enum ImageClassificationError: LocalizedError {
    case invalidImage
    case modelUnavailable
    case processingFailed

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            "Не удалось прочитать изображение. Выберите другое фото."
        case .modelUnavailable:
            "Модель распознавания недоступна. Перезапустите приложение."
        case .processingFailed:
            "Не получилось обработать фото. Попробуйте выбрать другое изображение."
        }
    }
}

private enum PocketVisionRuntime {
    static let model: Result<VNCoreMLModel, Error> = {
        guard let modelURL = Bundle(for: PocketVisionModel.self).url(forResource: "PocketVisionClassifier", withExtension: "mlmodelc") else {
            return .failure(ImageClassificationError.modelUnavailable)
        }

        do {
            let coreMLModel = try MLModel(contentsOf: modelURL)
            return .success(try VNCoreMLModel(for: coreMLModel))
        } catch {
            return .failure(ImageClassificationError.modelUnavailable)
        }
    }()
}

private extension CGImagePropertyOrientation {
    init(_ orientation: UIImage.Orientation) {
        switch orientation {
        case .up: self = .up
        case .upMirrored: self = .upMirrored
        case .down: self = .down
        case .downMirrored: self = .downMirrored
        case .left: self = .left
        case .leftMirrored: self = .leftMirrored
        case .right: self = .right
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}
