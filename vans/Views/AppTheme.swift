import SwiftUI

// MARK: - App Theme Colors
struct AppTheme {
    // MARK: - Background Colors
    static let background = Color(hex: "121212")
    static let surface = Color(hex: "1E1E1E")
    static let card = Color(hex: "252525")

    // MARK: - Accent Colors
    static let primary = Color(hex: "E8B86D")      // Sand/Gold - primary accent
    static let secondary = Color(hex: "7A9E8E")    // Sage green - secondary accent
    static let accent = Color(hex: "5B8A67")       // Forest green - buttons
    static let accentDark = Color(hex: "2D4A3E")   // Dark green - icons

    // MARK: - Text Colors
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: "9A9A9A")
    static let textTertiary = Color(hex: "636366")

    // MARK: - Status Colors
    static let success = Color(hex: "5B8A67")
    static let warning = Color(hex: "E8B86D")
    static let error = Color(hex: "D64545")
    static let info = Color(hex: "7A9E8E")

    // MARK: - Component Colors
    static let buttonPrimary = Color(hex: "5B8A67")
    static let buttonSecondary = Color(hex: "7A9E8E")
    static let inputBackground = Color(hex: "2A2A2A")
    static let divider = Color(hex: "333333")

    // MARK: - Gradients
    static let primaryGradient = LinearGradient(
        colors: [Color(hex: "5B8A67"), Color(hex: "4A7C59")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let accentGradient = LinearGradient(
        colors: [Color(hex: "E8B86D"), Color(hex: "D4A65A")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Color Extension for Hex Support
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Modifiers
struct ThemedCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(AppTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct ThemedButtonModifier: ViewModifier {
    let style: ButtonStyle

    enum ButtonStyle {
        case primary
        case secondary
        case outline
    }

    func body(content: Content) -> some View {
        switch style {
        case .primary:
            content
                .font(.headline)
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppTheme.buttonPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        case .secondary:
            content
                .font(.headline)
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppTheme.buttonSecondary)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        case .outline:
            content
                .font(.headline)
                .foregroundColor(AppTheme.textPrimary)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(AppTheme.divider, lineWidth: 1)
                )
        }
    }
}

extension View {
    func themedCard() -> some View {
        modifier(ThemedCardModifier())
    }

    func themedButton(_ style: ThemedButtonModifier.ButtonStyle = .primary) -> some View {
        modifier(ThemedButtonModifier(style: style))
    }
}
