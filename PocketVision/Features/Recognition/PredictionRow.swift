import SwiftUI

struct PredictionRow: View {
    let prediction: Prediction
    var body: some View {
        HStack {
            Text(prediction.label)
                .foregroundStyle(PVTheme.ink)
            Spacer(minLength: 12)
            Text(prediction.score, format: .percent.precision(.fractionLength(0)))
                .fontWeight(.semibold)
                .foregroundStyle(PVTheme.blue)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(PVTheme.paleBlue, in: Capsule())
        }
        .font(.system(size: 15))
        .frame(minHeight: 48)
        .accessibilityElement(children: .combine)
    }
}
