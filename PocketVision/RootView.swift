import SwiftUI

private enum AppTab: Hashable {
    case camera, collection, model
}

struct PocketVisionRootView: View {
    @EnvironmentObject private var model: PocketVisionModel
    @State private var selectedTab: AppTab = .camera

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                Group {
                    if model.selectedImage != nil {
                        RecognitionResultView(onBack: model.resetRecognition)
                    } else {
                        RecognitionHomeView()
                    }
                }
                .toolbar(.hidden, for: .navigationBar)
            }
            .tabItem { Label("Камера", systemImage: "camera") }
            .tag(AppTab.camera)

            NavigationStack { CollectionView() }
                .tabItem { Label("Коллекция", systemImage: "square.grid.2x2") }
                .tag(AppTab.collection)

            NavigationStack { ModelInfoView() }
                .tabItem { Label("Модель", systemImage: "cube") }
                .tag(AppTab.model)
        }
        .tint(PVTheme.blue)
        .alert("Не удалось выполнить действие", isPresented: Binding(
            get: { model.errorMessage != nil },
            set: { if !$0 { model.errorMessage = nil } }
        )) {
            Button("Понятно", role: .cancel) { model.errorMessage = nil }
        } message: {
            Text(model.errorMessage ?? "Попробуйте ещё раз.")
        }
    }
}
