import SwiftUI
import UIKit

struct CollectionView: View {
    @EnvironmentObject private var model: PocketVisionModel
    @State private var selectedRecord: RecognitionRecord?
    @State private var confirmClear = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Коллекция")
                        .font(PVTheme.pageTitle())
                        .foregroundStyle(PVTheme.ink)
                    Spacer()
                    if !model.history.isEmpty {
                        Menu {
                            Button("Очистить коллекцию", role: .destructive) { confirmClear = true }
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(PVTheme.blue)
                                .frame(width: 44, height: 44)
                                .background(PVTheme.paleBlue, in: Circle())
                        }
                        .accessibilityLabel("Действия с коллекцией")
                    }
                }

                if model.history.isEmpty {
                    ContentUnavailableView {
                        Label("Здесь будут ваши находки", systemImage: "square.grid.2x2")
                    } description: {
                        Text("Сохраните результат распознавания, чтобы вернуться к нему позже.")
                    }
                    .padding(.top, 70)
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(model.history) { record in
                            Button { selectedRecord = record } label: {
                                HistoryRow(record: record, image: model.image(for: record))
                            }
                            .buttonStyle(.plain)
                            .swipeActions {
                                Button("Удалить", systemImage: "trash", role: .destructive) { model.delete(record) }
                            }
                            Divider().overlay(PVTheme.border)
                        }
                    }
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
        .background(PVTheme.background.ignoresSafeArea())
        .navigationDestination(item: $selectedRecord) { record in
            HistoryDetailView(record: record)
                .toolbar(.hidden, for: .navigationBar)
        }
        .confirmationDialog("Очистить коллекцию?", isPresented: $confirmClear, titleVisibility: .visible) {
            Button("Удалить все записи", role: .destructive) { model.clearHistory() }
            Button("Отмена", role: .cancel) {}
        } message: {
            Text("Фото и результаты будут удалены с этого iPhone.")
        }
    }
}

struct HistoryDetailView: View {
    @EnvironmentObject private var model: PocketVisionModel
    @Environment(\.dismiss) private var dismiss
    let record: RecognitionRecord

    var body: some View {
        Group {
            if model.image(for: record) != nil {
                RecognitionResultView(onBack: { dismiss() })
                    .onAppear { model.open(record) }
            } else {
                ContentUnavailableView("Фото недоступно", systemImage: "photo", description: Text("Эта запись больше не содержит исходного изображения."))
            }
        }
    }
}

struct HistoryRow: View {
    let record: RecognitionRecord
    let image: UIImage?

    var body: some View {
        HStack(spacing: 14) {
            Group {
                if let image {
                    Image(uiImage: image).resizable().scaledToFill()
                } else {
                    ZStack { Color.white; Image(systemName: "photo").foregroundStyle(PVTheme.secondary) }
                }
            }
            .frame(width: 86, height: 86)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 7) {
                Text(record.primary?.label ?? "Без названия")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(PVTheme.ink)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                if let primary = record.primary {
                    Text(primary.score, format: .percent.precision(.fractionLength(0)))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(PVTheme.blue)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(PVTheme.paleBlue, in: Capsule())
                }
                Text(record.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 12))
                    .foregroundStyle(PVTheme.secondary)
            }
            Spacer(minLength: 4)
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(PVTheme.secondary.opacity(0.7))
        }
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}
