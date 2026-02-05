import SwiftUI
import Kingfisher

struct MySessionsView: View {
    @StateObject private var viewModel = MySessionsViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerSection

                // Segment picker
                segmentPicker

                // Content
                if viewModel.isLoading && viewModel.sessions.isEmpty {
                    loadingView
                } else if viewModel.sessions.isEmpty {
                    emptyStateView
                } else {
                    sessionsList
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            Task {
                await viewModel.loadSessions()
            }
        }
    }

    private var headerSection: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(AppTheme.textPrimary)
            }

            Spacer()

            Text("My Sessions")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.textPrimary)

            Spacer()

            Color.clear.frame(width: 24, height: 24)
        }
        .padding()
    }

    private var segmentPicker: some View {
        HStack(spacing: 0) {
            SegmentButton(
                title: "As Client",
                isSelected: !viewModel.showingAsBuilder
            ) {
                viewModel.toggleMode(asBuilder: false)
            }

            SegmentButton(
                title: "As Builder",
                isSelected: viewModel.showingAsBuilder
            ) {
                viewModel.toggleMode(asBuilder: true)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 16)
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.primary))
            Text("Loading sessions...")
                .font(.subheadline)
                .foregroundColor(AppTheme.textSecondary)
            Spacer()
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: viewModel.showingAsBuilder ? "wrench.and.screwdriver" : "bubble.left.and.bubble.right")
                .font(.system(size: 50))
                .foregroundColor(AppTheme.textTertiary)

            VStack(spacing: 8) {
                Text(viewModel.showingAsBuilder ? "No sessions yet" : "No help sessions yet")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.textPrimary)

                Text(viewModel.showingAsBuilder
                    ? "When someone books a session with you, it will appear here."
                    : "Book a session with a trusted builder to get help with your van build.")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
        .padding()
    }

    private var sessionsList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.sessions) { session in
                    SessionCard(
                        session: session,
                        asBuilder: viewModel.showingAsBuilder,
                        onTap: { viewModel.openSession(session) }
                    )
                }
            }
            .padding()
            .padding(.bottom, 100)
        }
    }
}

// MARK: - Segment Button

struct SegmentButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .black : AppTheme.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isSelected ? AppTheme.primary : AppTheme.card)
        }
    }
}

// MARK: - Session Card

struct SessionCard: View {
    let session: BuilderSession
    let asBuilder: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Header
                HStack(spacing: 12) {
                    // Other user photo
                    if let photoUrl = session.otherUser?.profile?.photoUrl {
                        KFImage(URL(string: photoUrl))
                            .placeholder {
                                Circle().fill(AppTheme.surface)
                            }
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 48, height: 48)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(AppTheme.surface)
                            .frame(width: 48, height: 48)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundColor(AppTheme.textSecondary)
                            )
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text(session.otherUser?.profile?.firstName ?? (asBuilder ? "Client" : "Builder"))
                                .font(.headline)
                                .foregroundColor(AppTheme.textPrimary)

                            if !asBuilder {
                                Image(systemName: "wrench.and.screwdriver.fill")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.primary)
                            }
                        }

                        HStack(spacing: 4) {
                            Image(systemName: session.category.icon)
                                .font(.caption2)
                            Text(session.category.displayName)
                                .font(.caption)
                        }
                        .foregroundColor(AppTheme.textSecondary)
                    }

                    Spacer()

                    // Status badge
                    StatusBadge(status: session.status)
                }

                // Session details
                HStack(spacing: 16) {
                    DetailItem(
                        icon: "clock",
                        text: "\(session.duration) min"
                    )

                    DetailItem(
                        icon: "dollarsign.circle",
                        text: "$\(session.price)"
                    )

                    if session.chatEnabled {
                        DetailItem(
                            icon: "message.fill",
                            text: "Chat open",
                            color: AppTheme.accent
                        )
                    }

                    Spacer()

                    if session.canReview && !asBuilder {
                        Text("Leave review")
                            .font(.caption)
                            .foregroundColor(AppTheme.primary)
                    }
                }
            }
            .padding()
            .background(AppTheme.card)
            .cornerRadius(16)
        }
    }
}

// MARK: - Status Badge

struct StatusBadge: View {
    let status: SessionStatus

    var body: some View {
        Text(status.displayName)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundColor(textColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .cornerRadius(8)
    }

    private var textColor: Color {
        switch status {
        case .pendingPayment: return AppTheme.warning
        case .paid, .inProgress: return AppTheme.accent
        case .completed: return AppTheme.textSecondary
        case .cancelled, .refunded: return AppTheme.error
        }
    }

    private var backgroundColor: Color {
        textColor.opacity(0.2)
    }
}

// MARK: - Detail Item

struct DetailItem: View {
    let icon: String
    let text: String
    var color: Color = AppTheme.textSecondary

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(.caption)
        }
        .foregroundColor(color)
    }
}

// MARK: - View Model

@MainActor
final class MySessionsViewModel: ObservableObject {
    @Published var sessions: [BuilderSession] = []
    @Published var showingAsBuilder = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let functions = Functions.functions()

    func toggleMode(asBuilder: Bool) {
        showingAsBuilder = asBuilder
        Task {
            await loadSessions()
        }
    }

    func loadSessions() async {
        guard !isLoading else { return }
        isLoading = true

        do {
            let result = try await functions.httpsCallable("getBuilderSessions").call([
                "asBuilder": showingAsBuilder,
                "limit": 50
            ])

            guard let data = result.data as? [String: Any],
                  let success = data["success"] as? Bool,
                  success,
                  let sessionsData = data["sessions"] as? [[String: Any]] else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to load sessions"])
            }

            sessions = sessionsData.compactMap { parseSession($0) }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func openSession(_ session: BuilderSession) {
        // This would navigate to the session view
        // For now, this needs to be connected to a coordinator
    }

    private func parseSession(_ data: [String: Any]) -> BuilderSession? {
        guard let id = data["id"] as? String,
              let builderId = data["builderId"] as? String,
              let clientId = data["clientId"] as? String,
              let categoryRaw = data["category"] as? String,
              let category = BuilderCategory(rawValue: categoryRaw),
              let duration = data["duration"] as? Int,
              let price = data["price"] as? Int,
              let statusRaw = data["status"] as? String,
              let status = SessionStatus(rawValue: statusRaw) else {
            return nil
        }

        var otherUser: SessionOtherUser?
        if let otherUserData = data["otherUser"] as? [String: Any] {
            let odId = otherUserData["odId"] as? String ?? ""
            var profile: UserProfile?
            if let profileData = otherUserData["profile"] as? [String: Any] {
                profile = UserProfile(
                    firstName: profileData["firstName"] as? String ?? "",
                    photoUrl: profileData["photoUrl"] as? String ?? "",
                    age: profileData["age"] as? Int ?? 0,
                    gender: Gender(rawValue: profileData["gender"] as? String ?? "") ?? .male,
                    vanLifeStatus: VanLifeStatus(rawValue: profileData["vanLifeStatus"] as? String ?? "") ?? .planning,
                    region: profileData["region"] as? String ?? "",
                    activities: profileData["activities"] as? [String] ?? [],
                    bio: profileData["bio"] as? String
                )
            }
            otherUser = SessionOtherUser(odId: odId, profile: profile, trust: nil)
        }

        return BuilderSession(
            id: id,
            builderId: builderId,
            clientId: clientId,
            category: category,
            duration: duration,
            price: price,
            status: status,
            sourceEventId: data["sourceEventId"] as? String,
            scheduledAt: data["scheduledAt"] as? String,
            paidAt: data["paidAt"] as? String,
            startedAt: data["startedAt"] as? String,
            completedAt: data["completedAt"] as? String,
            cancelledAt: data["cancelledAt"] as? String,
            cancelReason: data["cancelReason"] as? String,
            chatEnabled: data["chatEnabled"] as? Bool ?? false,
            reviewed: data["reviewed"] as? Bool ?? false,
            createdAt: data["createdAt"] as? String,
            otherUser: otherUser
        )
    }
}

import FirebaseFunctions
