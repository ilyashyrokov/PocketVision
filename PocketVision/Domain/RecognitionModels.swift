import SwiftUI

struct Prediction: Identifiable, Codable, Hashable {
    var id: String { label }
    let label: String
    let score: Double
}

struct RecognitionRecord: Identifiable, Codable, Hashable {
    let id: UUID
    let createdAt: Date
    let predictions: [Prediction]
    let imageFilename: String

    var primary: Prediction? { predictions.first }
}

struct RecognitionFeedback: Identifiable, Codable {
    let id: UUID
    let createdAt: Date
    let isCorrect: Bool
    let predictions: [Prediction]
}

enum RecognitionStatus: Equatable {
    case likely, possible, unsure

    init(score: Double) {
        switch score {
        case 0.70...: self = .likely
        case 0.50..<0.70: self = .possible
        default: self = .unsure
        }
    }

    var title: String {
        switch self {
        case .likely: "Похоже на этот предмет"
        case .possible: "Возможный вариант"
        case .unsure: "Низкая уверенность"
        }
    }

    var color: Color { self == .unsure ? PVTheme.amber : PVTheme.blue }
    var background: Color { self == .unsure ? PVTheme.paleAmber : PVTheme.paleBlue }
}
