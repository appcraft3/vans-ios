import SwiftUI
import Combine

struct GlassTabBarView: View {
    struct TabItem: Identifiable {
        let id: Int
        let title: String
        let icon: String
        let activeIcon: String
        let isPrimary: Bool
    }

    let tabs: [TabItem] = [
        .init(id: 0, title: String(localized: "Explore"), icon: "safari", activeIcon: "safari.fill", isPrimary: false),
        .init(id: 1, title: String(localized: "Events"), icon: "calendar", activeIcon: "calendar.circle.fill", isPrimary: true),
        .init(id: 2, title: String(localized: "Messages"), icon: "bubble.left", activeIcon: "bubble.left.fill", isPrimary: false),
        .init(id: 3, title: String(localized: "Profile"), icon: "person.crop.circle", activeIcon: "person.crop.circle.fill", isPrimary: false),
    ]

    @Binding var selectedIndex: Int

    // MARK: - Style
    private let activeColor = AppTheme.secondary      // Sage green
    private let inactiveColor = Color.white.opacity(0.32)
    private let barColor = AppTheme.background        // #121212

    var body: some View {
        VStack(spacing: 0) {
            // Top gradient: transparent → solid (merges into content)
            LinearGradient(
                stops: [
                    .init(color: barColor.opacity(0), location: 0),
                    .init(color: barColor.opacity(0.45), location: 0.35),
                    .init(color: barColor.opacity(0.8), location: 0.65),
                    .init(color: barColor, location: 1.0),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 30)

            // Tab icons on solid background
            HStack(spacing: 0) {
                ForEach(tabs) { tab in
                    tabButton(for: tab)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 2)
            .padding(.bottom, 10)
            .background(barColor)

            // Fills the safe area below with solid color
            barColor
        }
    }

    // MARK: - Tab Button

    @ViewBuilder
    private func tabButton(for tab: TabItem) -> some View {
        let isSelected = selectedIndex == tab.id

        Button {
            let generator = UIImpactFeedbackGenerator(style: .soft)
            generator.impactOccurred(intensity: 0.5)
            withAnimation(.spring(response: 0.3, dampingFraction: 0.78)) {
                selectedIndex = tab.id
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: isSelected ? tab.activeIcon : tab.icon)
                    .symbolRenderingMode(.monochrome)
                    .font(.system(
                        size: tab.isPrimary ? 22 : 20,
                        weight: isSelected ? .medium : .light
                    ))
                    .foregroundStyle(isSelected ? activeColor : inactiveColor)
                    .frame(height: 28)

                Text(tab.title)
                    .font(.system(size: 10, weight: isSelected ? .medium : .regular))
                    .foregroundStyle(isSelected ? activeColor : inactiveColor.opacity(0.8))
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct BlurView: UIViewRepresentable {
    let style: UIBlurEffect.Style
    func makeUIView(context: Context) -> UIVisualEffectView {
        let v = UIVisualEffectView(effect: UIBlurEffect(style: style))
        v.isUserInteractionEnabled = false
        return v
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

struct GlassTabBarWrapper: View {
    @State private var currentIndex: Int = 0

    let selectedIndexPublisher: AnyPublisher<Int, Never>
    let onSelect: (Int) -> Void

    var body: some View {
        GlassTabBarView(
            selectedIndex: Binding(
                get: { currentIndex },
                set: { newValue in
                    currentIndex = newValue
                    onSelect(newValue)
                }
            )
        )
        .onReceive(selectedIndexPublisher) { newValue in
            currentIndex = newValue
        }
    }
}
