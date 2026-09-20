import SwiftUI
import UIKit

@MainActor
final class PocketVisionModel: ObservableObject {
    @Published var selectedImage: UIImage?
    @Published var predictions: [Prediction] = []
    @Published var history: [RecognitionRecord] = []
    @Published var isRecognizing = false
    @Published var errorMessage: String?
    @Published var activeRecordID: UUID?
    @Published var feedbackSubmitted = false

    private let classifier = ImageClassifier()
    private let store: RecognitionStore

    init(store: RecognitionStore = RecognitionStore()) {
        self.store = store
        do {
            history = try store.load()
        } catch {
            history = []
            errorMessage = "Не удалось загрузить коллекцию. Сохранённые записи могут быть повреждены."
        }
    }

    var activeRecord: RecognitionRecord? {
        guard let activeRecordID else { return nil }
        return history.first { $0.id == activeRecordID }
    }

    func recognize(_ image: UIImage) {
        selectedImage = image
        predictions = []
        isRecognizing = true
        errorMessage = nil
        activeRecordID = nil
        feedbackSubmitted = false

        Task {
            do {
                predictions = try await classifier.classify(image)
                if predictions.isEmpty { errorMessage = "Модель не нашла подходящих категорий. Попробуйте другое фото." }
            } catch let error as LocalizedError {
                errorMessage = error.errorDescription ?? "Не получилось обработать фото. Попробуйте снова."
            } catch {
                errorMessage = "Не получилось обработать фото. Выберите другое изображение и попробуйте снова."
            }
            isRecognizing = false
        }
    }

    func open(_ record: RecognitionRecord) {
        guard let image = store.image(for: record) else {
            errorMessage = "Фото этой записи больше недоступно."
            return
        }
        selectedImage = image
        predictions = record.predictions
        activeRecordID = record.id
        feedbackSubmitted = false
    }

    func image(for record: RecognitionRecord) -> UIImage? { store.image(for: record) }

    func resetRecognition() {
        selectedImage = nil
        predictions = []
        activeRecordID = nil
        errorMessage = nil
        feedbackSubmitted = false
    }

    func saveCurrent() {
        guard let image = selectedImage, !predictions.isEmpty else { return }
        if let activeRecordID, history.contains(where: { $0.id == activeRecordID }) { return }
        do {
            let record = try store.save(image: image, predictions: predictions)
            history.insert(record, at: 0)
            activeRecordID = record.id
        } catch {
            errorMessage = "Не удалось сохранить запись. Проверьте свободное место на iPhone и попробуйте снова."
        }
    }

    func submitFeedback(isCorrect: Bool) {
        guard !predictions.isEmpty, !feedbackSubmitted else { return }
        do {
            try store.saveFeedback(RecognitionFeedback(id: UUID(), createdAt: .now, isCorrect: isCorrect, predictions: predictions))
            feedbackSubmitted = true
        } catch {
            errorMessage = "Не удалось сохранить отзыв на этом iPhone. Попробуйте позже."
        }
    }

    func delete(_ record: RecognitionRecord) {
        do {
            try store.delete(record)
            history.removeAll { $0.id == record.id }
            if activeRecordID == record.id { activeRecordID = nil }
        } catch {
            errorMessage = "Не удалось удалить запись. Попробуйте ещё раз."
        }
    }

    func clearHistory() {
        do {
            try store.clear()
            history = []
            activeRecordID = nil
        } catch {
            errorMessage = "Не удалось очистить коллекцию. Попробуйте ещё раз."
        }
    }
}
