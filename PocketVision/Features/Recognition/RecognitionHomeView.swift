import PhotosUI
import SwiftUI
import UIKit

struct RecognitionHomeView: View {
    @EnvironmentObject private var model: PocketVisionModel
    @State private var photoItem: PhotosPickerItem?
    @State private var cameraPresented = false
    @State private var cameraUnavailable = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack(alignment: .center) {
                    Text("Pocket Vision")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(PVTheme.ink)
                    Spacer()
                    HStack(spacing: 6) {
                        Circle().fill(PVTheme.blue).frame(width: 7, height: 7)
                        Text("Офлайн")
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(PVTheme.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(PVTheme.paleBlue, in: Capsule())
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Распознавание работает на устройстве")
                }

                Text("Посмотрим\nвнимательнее")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .tracking(-0.8)
                    .foregroundStyle(PVTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)

                Label {
                    Text("Модель распознаёт объекты из 1 000 категорий ImageNet. Если предмета нет в этом списке, результат может быть неверным.")
                } icon: {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(PVTheme.blue)
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(PVTheme.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                ZStack(alignment: .bottomLeading) {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(PVTheme.surface)
                    VStack(spacing: 12) {
                        Image(systemName: "viewfinder")
                            .font(.system(size: 44, weight: .light))
                            .foregroundStyle(PVTheme.blue)
                        Text("Ваш кадр появится здесь")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(PVTheme.secondary)
                        Text("Снимите предмет целиком при хорошем освещении")
                            .font(.system(size: 13))
                            .foregroundStyle(PVTheme.secondary.opacity(0.85))
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 250)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(28)

                    FocusCorners()
                        .stroke(PVTheme.blue.opacity(0.7), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                        .padding(20)
                }
                .frame(height: 270)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Область предварительного просмотра. Выберите фото или сделайте снимок.")

                VStack(spacing: 12) {
                    Button {
                        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
                            cameraUnavailable = true
                            return
                        }
                        cameraPresented = true
                    } label: {
                        Label("Сделать фото", systemImage: "camera")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    PhotosPicker(selection: $photoItem, matching: .images, photoLibrary: .shared()) {
                        Label("Выбрать фото", systemImage: "photo")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .onChange(of: photoItem) { _, item in
                        guard let item else { return }
                        Task {
                            guard let data = try? await item.loadTransferable(type: Data.self),
                                  let image = UIImage(data: data) else {
                                model.errorMessage = "Не удалось открыть это изображение. Попробуйте выбрать другое фото."
                                return
                            }
                            model.recognize(image)
                            photoItem = nil
                        }
                    }
                }

                Label("Снимки обрабатываются на iPhone", systemImage: "lock.shield")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(PVTheme.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 2)
            }
            .padding(.horizontal, 22)
            .padding(.top, 14)
            .padding(.bottom, 24)
        }
        .background(PVTheme.background.ignoresSafeArea())
        .fullScreenCover(isPresented: $cameraPresented) {
            CameraPicker(onImage: { image in
                cameraPresented = false
                model.recognize(image)
            }, onCancel: { cameraPresented = false })
            .ignoresSafeArea()
        }
        .alert("Камера недоступна", isPresented: $cameraUnavailable) {
            Button("Понятно", role: .cancel) {}
        } message: {
            Text("На этом устройстве нельзя сделать снимок. Выберите изображение из медиатеки.")
        }
    }
}
