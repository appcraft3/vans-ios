import SwiftUI

struct PaywallView: View {
    @StateObject private var viewModel = PaywallViewModel()
    @Environment(\.dismiss) private var dismiss

    private let accentGreen = Color(hex: "2E7D5A")
    private let paywallBg = Color(hex: "0F1115")

    private let features: [(icon: String, title: String, desc: String)] = [
        ("bolt.shield", "Priority Review", "Skip the wait and get approved faster"),
        ("checkmark.seal.fill", "Verified+ Badge", "Badge stays active while subscribed"),
        ("chart.line.uptrend.xyaxis", "Visibility Boost", "Higher placement in events and map"),
        ("headset", "Priority Support", "Faster support and review times"),
    ]

    private let bullets = [
        "Skip the long wait (priority review)",
        "Verified+ badge while subscribed",
        "Better visibility in Events & Explore",
        "Cancel anytime",
    ]

    var body: some View {
        ZStack {
            paywallBg.ignoresSafeArea()

            StarfieldBackground(starCount: 40, twinkleCount: 10)
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    headerSection
                    featureCarousel
                    bulletList
                    planSelector
                    ctaSection
                    footerSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 40)
            }

            // Close button
            VStack {
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.6))
                            .padding(10)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.08))
                            )
                    }
                    .padding(.trailing, 20)
                    .padding(.top, 12)
                }
                Spacer()
            }
        }
        .task {
            await viewModel.loadOfferings()
        }
        .onChange(of: viewModel.didPurchase) { purchased in
            if purchased { dismiss() }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 10) {
            Image(systemName: "mountain.2.fill")
                .font(.system(size: 40))
                .foregroundColor(accentGreen)
                .padding(.top, 20)

            Text("Unlock VanGo Pro")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)

            Text("Priority access, better visibility, and community perks — all in one subscription.")
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 10)
        }
    }

    // MARK: - Feature Carousel

    private var featureCarousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(features, id: \.title) { feature in
                    VStack(alignment: .leading, spacing: 8) {
                        Image(systemName: feature.icon)
                            .font(.system(size: 18))
                            .foregroundColor(accentGreen)

                        Text(feature.title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)

                        Text(feature.desc)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.5))
                            .lineLimit(2)
                    }
                    .frame(width: 160, alignment: .leading)
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.white.opacity(0.06))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal, 4)
        }
    }

    // MARK: - Bullets

    private var bulletList: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(bullets, id: \.self) { bullet in
                HStack(spacing: 10) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(accentGreen)
                        .frame(width: 20, height: 20)
                        .background(
                            Circle()
                                .fill(accentGreen.opacity(0.15))
                        )

                    Text(bullet)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    // MARK: - Plan Selector

    private var planSelector: some View {
        HStack(spacing: 10) {
            planCard(
                title: "Monthly",
                price: viewModel.monthlyPrice,
                subtitle: "per month",
                isSelected: viewModel.selectedPlan == .monthly,
                badge: nil
            ) {
                viewModel.selectedPlan = .monthly
            }

            planCard(
                title: "Yearly",
                price: viewModel.yearlyPrice,
                subtitle: viewModel.yearlyMonthlyEquivalent.isEmpty
                    ? "per year"
                    : "\(viewModel.yearlyMonthlyEquivalent)/mo",
                isSelected: viewModel.selectedPlan == .yearly,
                badge: viewModel.discountPercentage > 0 ? "Save \(viewModel.discountPercentage)%" : "Best Value"
            ) {
                viewModel.selectedPlan = .yearly
            }
        }
    }

    private func planCard(
        title: String,
        price: String,
        subtitle: String,
        isSelected: Bool,
        badge: String?,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                if let badge {
                    Text(badge)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule().fill(accentGreen)
                        )
                } else {
                    Spacer().frame(height: 18)
                }

                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))

                Text(price)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)

                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.4))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected ? accentGreen.opacity(0.12) : Color.white.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        isSelected ? accentGreen.opacity(0.5) : Color.white.opacity(0.06),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
        }
    }

    // MARK: - CTA

    private var ctaSection: some View {
        VStack(spacing: 12) {
            Button {
                Task { await viewModel.purchase() }
            } label: {
                Group {
                    if viewModel.isPurchasing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Join VanGo Pro")
                            .font(.system(size: 17, weight: .bold))
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(accentGreen)
                )
            }
            .disabled(viewModel.isPurchasing || viewModel.isRestoring)

//            Button {
//                dismiss()
//            } label: {
//                Text("Not now")
//                    .font(.system(size: 15))
//                    .foregroundColor(.white.opacity(0.4))
//            }
        }
    }

    // MARK: - Footer

    private var footerSection: some View {
        VStack(spacing: 8) {
            Text("Auto-renews. Cancel anytime in Settings.")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.25))

            Button {
                Task { await viewModel.restore() }
            } label: {
                if viewModel.isRestoring {
                    ProgressView()
                        .tint(.white.opacity(0.4))
                        .scaleEffect(0.7)
                } else {
                    Text("Restore Purchases")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.35))
                        .underline()
                }
            }
            .disabled(viewModel.isPurchasing || viewModel.isRestoring)
        }
    }
}
