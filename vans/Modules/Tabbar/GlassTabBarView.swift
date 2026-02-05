import SwiftUI
import Combine

struct GlassTabBarView: View {
    struct TabItem: Identifiable {
        let id: Int
        let title: String
        let systemImage: String
    }

    let tabs: [TabItem] = [
        .init(id: 0, title: String(localized: "Messages"), systemImage: "bubble.left.and.bubble.right.fill"),
        .init(id: 1, title: String(localized: "Explore"), systemImage: "magnifyingglass"),
        .init(id: 2, title: String(localized: "Events"), systemImage: "calendar"),
        .init(id: 3, title: String(localized: "Profile"), systemImage: "person.circle")
    ]

    @Binding var selectedIndex: Int
    @Namespace private var highlightNS

    // MARK: - Colors
    private var accentColor: Color { AppTheme.primary }
    private var inactiveColor: Color { AppTheme.textSecondary }

    var body: some View {
        ZStack {
            BlurView(style: .systemUltraThinMaterialDark)
                .overlay(
                    AppTheme.surface.opacity(0.85)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(AppTheme.divider, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .shadow(color: .black.opacity(0.5), radius: 20, y: 10)

            HStack(spacing: 0) {
                ForEach(tabs) { tab in
                    Button {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
                            selectedIndex = tab.id
                        }
                    } label: {
                        VStack(spacing: 6) {
                            ZStack {
                                if selectedIndex == tab.id {
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .fill(AppTheme.accentDark)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                                .stroke(AppTheme.accent.opacity(0.5), lineWidth: 1)
                                        )
                                        .matchedGeometryEffect(id: "HIGHLIGHT_BG", in: highlightNS)
                                }

                                Image(systemName: tab.systemImage)
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(selectedIndex == tab.id ? accentColor : inactiveColor)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .frame(minWidth: 44)
                            }

                            Text(tab.title)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(selectedIndex == tab.id ? AppTheme.primary : inactiveColor)
                                .frame(height: 16)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 10)
        }
        .frame(height: 78)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
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
