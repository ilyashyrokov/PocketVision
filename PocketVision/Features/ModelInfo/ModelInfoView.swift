import SwiftUI

struct ModelInfoView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("Модель")
                    .font(PVTheme.pageTitle())
                    .foregroundStyle(PVTheme.ink)

                VStack(alignment: .leading, spacing: 14) {
                    Label("Pocket Vision · 1 000 категорий", systemImage: "viewfinder")
                        .font(.system(size: 19, weight: .bold, design: .rounded))
                        .foregroundStyle(PVTheme.ink)
                    Text("MobileNetV3-Small с весами ImageNet-1K. Модель выбирает из 1 000 известных категорий и работает на iPhone без подключения к сети.")
                        .font(.system(size: 15))
                        .lineSpacing(4)
                        .foregroundStyle(PVTheme.secondary)
                    Divider().overlay(PVTheme.border)
                    InfoLine(title: "Архитектура", value: "MobileNetV3-Small · ImageNet-1K")
                    InfoLine(title: "Формат", value: "Core ML · FP16")
                    InfoLine(title: "Вход", value: "Центральный фрагмент 224 × 224")
                    InfoLine(title: "Категории", value: "1 000 классов ImageNet-1K")
                    InfoLine(title: "Обработка", value: "На iPhone")
                }
                .padding(18)
                .background(.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))

                VStack(alignment: .leading, spacing: 14) {
                        Text("Оценка исходных весов")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(PVTheme.ink)
                    HStack(spacing: 12) {
                        MetricValue(title: "Top‑1", value: "67,7%")
                        MetricValue(title: "Top‑5", value: "87,4%")
                    }
                    Text("ImageNet-1K validation · метрики TorchVision для выбранных весов")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(PVTheme.secondary)
                    Text("Это классификатор, а не детектор: он может выбрать ближайшую категорию, даже если предмета нет среди этих 1 000 классов. При оценке ниже 50% приложение показывает варианты как предположения. Оценка модели не является вероятностью правильного ответа.")
                        .font(.system(size: 14))
                        .lineSpacing(4)
                        .foregroundStyle(PVTheme.secondary)
                }
                .padding(18)
                .background(.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))

                VStack(alignment: .leading, spacing: 10) {
                    Text("Как читать результат")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(PVTheme.ink)
                    Text("Оценка — это softmax score модели, а не откалиброванная вероятность правильного ответа. Результат зависит от кадрирования, освещения и того, насколько предмет похож на категории ImageNet.")
                        .font(.system(size: 15))
                        .lineSpacing(4)
                        .foregroundStyle(PVTheme.secondary)
                }
                .padding(18)
                .background(.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))

                Label("Фото сохраняются только после вашего действия.", systemImage: "lock.shield")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(PVTheme.blue)
                    .padding(.horizontal, 4)
            }
            .padding(.horizontal, 22)
            .padding(.top, 20)
            .padding(.bottom, 32)
        }
        .background(PVTheme.background.ignoresSafeArea())
    }
}
