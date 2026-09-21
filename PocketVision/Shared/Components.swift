import SwiftUI

struct InfoLine: View {
    let title: String
    let value: String
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title).foregroundStyle(PVTheme.secondary)
            Spacer()
            Text(value).fontWeight(.semibold).foregroundStyle(PVTheme.ink).multilineTextAlignment(.trailing)
        }
        .font(.system(size: 14))
    }
}

struct MetricValue: View {
    let title: String
    let value: String
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.system(size: 13, weight: .medium)).foregroundStyle(PVTheme.secondary)
            Text(value).font(.system(size: 24, weight: .bold, design: .rounded)).foregroundStyle(PVTheme.blue)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(PVTheme.paleBlue, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .frame(minHeight: 54)
            .background(PVTheme.blue.opacity(configuration.isPressed ? 0.82 : 1), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.99 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(PVTheme.ink)
            .padding(.horizontal, 18)
            .frame(minHeight: 54)
            .background(PVTheme.surface.opacity(configuration.isPressed ? 0.75 : 1), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(PVTheme.border, lineWidth: 1))
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct FocusCorners: Shape {
    func path(in rect: CGRect) -> Path {
        let width = min(rect.width * 0.12, 34)
        let height = min(rect.height * 0.12, 34)
        let inset: CGFloat = 4
        var path = Path()
        for (x, y, sx, sy) in [
            (inset, inset, CGFloat(1), CGFloat(1)), (rect.maxX - inset, inset, CGFloat(-1), CGFloat(1)),
            (inset, rect.maxY - inset, CGFloat(1), CGFloat(-1)), (rect.maxX - inset, rect.maxY - inset, CGFloat(-1), CGFloat(-1))
        ] {
            path.move(to: CGPoint(x: x, y: y + sy * height))
            path.addLine(to: CGPoint(x: x, y: y))
            path.addLine(to: CGPoint(x: x + sx * width, y: y))
        }
        return path
    }
}
