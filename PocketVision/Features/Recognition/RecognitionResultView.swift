import SwiftUI
import UIKit

struct RecognitionResultView: View {
    @EnvironmentObject private var model: PocketVisionModel
    @State private var feedbackDialog = false
    var onBack: () -> Void

    private var top: Prediction? { model.predictions.first }
    private var status: RecognitionStatus { RecognitionStatus(score: top?.score ?? 0) }
    private var hasConfidentPrediction: Bool { status != .unsure }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Button(action: onBack) {
                        Label("Камера", systemImage: "chevron.left")
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(PVTheme.blue)
                    .frame(minHeight: 44)
                    Spacer()
                    Text("Результат")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(PVTheme.ink)
                    Spacer()
                    Color.clear.frame(width: 66, height: 44)
                }

                if let image = model.selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 230)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .overlay {
                            FocusCorners()
                                .stroke(PVTheme.blue, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                                .padding(18)
                        }
                        .accessibilityLabel("Выбранное фото для распознавания")
                }

                if model.isRecognizing {
                    VStack(alignment: .leading, spacing: 14) {
                        ProgressView().tint(PVTheme.blue)
                        Text("Рассматриваем изображение…")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(PVTheme.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 12)
                } else if let top {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(hasConfidentPrediction ? top.label : "Не удалось определить предмет")
                            .font(PVTheme.pageTitle(28))
                            .tracking(-0.5)
                            .foregroundStyle(PVTheme.ink)
                            .fixedSize(horizontal: false, vertical: true)

                        HStack {
                            Text("Оценка модели")
                                .foregroundStyle(PVTheme.secondary)
                            Spacer()
                            Text(top.score, format: .percent.precision(.fractionLength(0)))
                                .fontWeight(.bold)
                                .foregroundStyle(PVTheme.ink)
                        }
                        .font(.system(size: 15))

                        ProgressView(value: top.score)
                            .tint(PVTheme.blue)
                            .scaleEffect(x: 1, y: 1.6, anchor: .center)
                            .padding(.vertical, 3)

                        HStack(spacing: 7) {
                            Image(systemName: status == .unsure ? "questionmark.circle" : "sparkle.magnifyingglass")
                            Text(status.title)
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(status.color)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(status.background, in: Capsule())

                        if !hasConfidentPrediction {
                            Text("Ниже — ближайшие варианты модели, а не подтверждённое распознавание.")
                                .font(.system(size: 14))
                                .foregroundStyle(PVTheme.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Text(hasConfidentPrediction ? "Другие варианты" : "Ближайшие варианты")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(PVTheme.ink)

                        VStack(spacing: 0) {
                            ForEach(model.predictions) { prediction in
                                PredictionRow(prediction: prediction)
                                if prediction.id != model.predictions.last?.id {
                                    Divider().overlay(PVTheme.border)
                                }
                            }
                        }

                        Label("Оценка модели может отличаться от точности.", systemImage: "info.circle")
                            .font(.system(size: 12))
                            .foregroundStyle(PVTheme.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        if model.feedbackSubmitted {
                            Label("Спасибо, отзыв сохранён на iPhone.", systemImage: "checkmark.circle")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(PVTheme.blue)
                        } else {
                            Button("Результат неверный?") { feedbackDialog = true }
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(PVTheme.blue)
                                .frame(minHeight: 44, alignment: .leading)
                        }
                    }
                } else if !model.isRecognizing {
                    ContentUnavailableView(
                        "Не удалось определить",
                        systemImage: "viewfinder",
                        description: Text(model.errorMessage ?? "Попробуйте выбрать другое фото.")
                    )
                }

                if top != nil {
                    VStack(spacing: 10) {
                        Button {
                            model.saveCurrent()
                        } label: {
                            Label(
                                model.activeRecordID == nil
                                    ? (hasConfidentPrediction ? "Сохранить в коллекцию" : "Сохранить фото и варианты")
                                    : "Сохранено",
                                systemImage: model.activeRecordID == nil ? "square.and.arrow.down" : "checkmark"
                            )
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(model.activeRecordID != nil)

                        Button(action: onBack) {
                            Text("Другое фото")
                                .frame(maxWidth: .infinity)
                                .frame(minHeight: 44)
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(PVTheme.blue)
                    }
                    .padding(.top, 3)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 30)
        }
        .background(PVTheme.background.ignoresSafeArea())
        .confirmationDialog("Оцените результат", isPresented: $feedbackDialog, titleVisibility: .visible) {
            Button("Модель угадала") { model.submitFeedback(isCorrect: true) }
            Button("Модель ошиблась") { model.submitFeedback(isCorrect: false) }
            Button("Отмена", role: .cancel) {}
        } message: {
            Text("Отзыв сохранится только на этом iPhone и поможет оценить ошибки модели.")
        }
    }
}
