import SwiftUI

enum PVTheme {
    static let background = Color(hex: 0xF4F6FA)
    static let surface = Color.white
    static let ink = Color(hex: 0x192033)
    static let secondary = Color(hex: 0x69748B)
    static let blue = Color(hex: 0x315BFF)
    static let paleBlue = Color(hex: 0xE9EEFF)
    static let border = Color(hex: 0xDCE2EF)
    static let amber = Color(hex: 0xA76500)
    static let paleAmber = Color(hex: 0xFFF3D8)

    static func pageTitle(_ size: CGFloat = 30) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}
