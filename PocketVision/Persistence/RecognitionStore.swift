import Foundation
import UIKit

final class RecognitionStore {
    private let fileManager = FileManager.default
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let root: URL

    init(rootURL: URL? = nil) {
        if let rootURL {
            root = rootURL
        } else {
            let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            root = base.appendingPathComponent("PocketVision", isDirectory: true)
        }
    }

    private var images: URL { root.appendingPathComponent("Images", isDirectory: true) }
    private var index: URL { root.appendingPathComponent("history.json") }
    private var feedbackIndex: URL { root.appendingPathComponent("feedback.json") }

    func load() throws -> [RecognitionRecord] {
        guard fileManager.fileExists(atPath: index.path) else { return [] }
        let data = try Data(contentsOf: index)
        let records = try decoder.decode([RecognitionRecord].self, from: data)
        return records.sorted { $0.createdAt > $1.createdAt }
    }

    func save(image: UIImage, predictions: [Prediction]) throws -> RecognitionRecord {
        try fileManager.createDirectory(at: images, withIntermediateDirectories: true)
        let id = UUID()
        let filename = "\(id.uuidString).jpg"
        guard let data = image.jpegData(compressionQuality: 0.82) else {
            throw RecognitionStoreError.imageEncodingFailed
        }
        let imageURL = images.appendingPathComponent(filename)
        try data.write(to: imageURL, options: .atomic)
        let record = RecognitionRecord(id: id, createdAt: .now, predictions: predictions, imageFilename: filename)
        do {
            var records = try load()
            records.insert(record, at: 0)
            try persist(records)
        } catch {
            try? fileManager.removeItem(at: imageURL)
            throw error
        }
        return record
    }

    func image(for record: RecognitionRecord) -> UIImage? {
        guard let data = try? Data(contentsOf: images.appendingPathComponent(record.imageFilename)) else { return nil }
        return UIImage(data: data)
    }

    func delete(_ record: RecognitionRecord) throws {
        var records = try load()
        records.removeAll { $0.id == record.id }
        try persist(records)
        try? fileManager.removeItem(at: images.appendingPathComponent(record.imageFilename))
    }

    func loadFeedback() throws -> [RecognitionFeedback] {
        guard fileManager.fileExists(atPath: feedbackIndex.path) else { return [] }
        let data = try Data(contentsOf: feedbackIndex)
        return try decoder.decode([RecognitionFeedback].self, from: data)
    }

    func saveFeedback(_ feedback: RecognitionFeedback) throws {
        try fileManager.createDirectory(at: root, withIntermediateDirectories: true)
        var items = try loadFeedback()
        items.append(feedback)
        let data = try encoder.encode(items)
        try data.write(to: feedbackIndex, options: .atomic)
    }

    func clear() throws {
        try persist([])
        try? fileManager.removeItem(at: images)
    }

    private func persist(_ records: [RecognitionRecord]) throws {
        try fileManager.createDirectory(at: root, withIntermediateDirectories: true)
        let data = try encoder.encode(records)
        try data.write(to: index, options: .atomic)
    }
}

private enum RecognitionStoreError: Error {
    case imageEncodingFailed
}
