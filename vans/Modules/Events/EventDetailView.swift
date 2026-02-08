import SwiftUI
import Kingfisher

struct EventDetailView: View {
    @StateObject var viewModel: EventDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showCheckInSheet = false
    @State private var checkInCode = ""
    @State private var selectedTab = 0

    private let accentGreen = Color(hex: "2E7D5A")

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            if viewModel.isLoading && viewModel.event == nil {
                ProgressView()
                    .tint(accentGreen)
                    .scaleEffect(1.5)
            } else if let event = viewModel.event {
                VStack(spacing: 0) {
                    // Top bar: back button + segment
                    topBar(event: event)

                    if selectedTab == 0 {
                        detailsTab(event: event)
                    } else {
                        EventChatView(eventId: viewModel.eventId) { senderId in
                            if let attendee = viewModel.attendees.first(where: { $0.id == senderId }) {
                                viewModel.openUserProfile(attendee)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .task {
            await viewModel.loadEventDetails()
        }
        .sheet(isPresented: $showCheckInSheet) {
            CheckInSheet(code: $checkInCode) {
                Task {
                    await viewModel.checkIn(code: checkInCode)
                    showCheckInSheet = false
                }
            }
            .presentationDetents([.height(250)])
        }
        .sheet(item: $viewModel.selectedAttendeeForReview) { attendee in
            ReviewSheet(attendee: attendee) { isPositive in
                Task {
                    await viewModel.submitReview(for: attendee.id, isPositive: isPositive)
                }
            }
            .presentationDetents([.height(300)])
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .alert("Success", isPresented: .constant(viewModel.successMessage != nil)) {
            Button("OK") { viewModel.successMessage = nil }
        } message: {
            Text(viewModel.successMessage ?? "")
        }
    }

    // MARK: - Top Bar (Back + Segment)

    @ViewBuilder
    private func topBar(event: VanEvent) -> some View {
        HStack(spacing: 10) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.06))
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            }

            if event.isInterested {
                HStack(spacing: 4) {
                    ForEach(["Details", "Chat"], id: \.self) { tab in
                        let index = tab == "Details" ? 0 : 1
                        let isSelected = selectedTab == index

                        Button {
                            let impact = UIImpactFeedbackGenerator(style: .light)
                            impact.impactOccurred(intensity: 0.5)
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                selectedTab = index
                            }
                        } label: {
                            Text(tab)
                                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                                .foregroundColor(isSelected ? .white : AppTheme.textTertiary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    Capsule()
                                        .fill(isSelected ? accentGreen.opacity(0.35) : Color.clear)
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(isSelected ? accentGreen.opacity(0.5) : Color.clear, lineWidth: 1)
                                )
                        }
                    }
                }
                .padding(4)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.06))
                )
            } else {
                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: - Details Tab

    @ViewBuilder
    private func detailsTab(event: VanEvent) -> some View {
        ZStack(alignment: .bottom) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    // Hero Image
                    heroImage(event: event)

                    VStack(alignment: .leading, spacing: 20) {
                        // Info pills
                        infoPills(event: event)

                        // About
                        if !event.description.isEmpty {
                            aboutSection(event: event)
                        }

                        // Photo Gallery
                        photoGallery(event: event)

                        // Admin Section
                        if viewModel.isAdmin, let checkInCode = viewModel.checkInCode {
                            AdminSection(
                                event: event,
                                checkInCode: checkInCode,
                                onEnableCheckIn: { Task { await viewModel.enableCheckIn() } },
                                onCompleteEvent: { Task { await viewModel.completeEvent() } }
                            )
                        }

                        // Interest limit indicator
                        if viewModel.canSendInterests {
                            InterestLimitBanner(
                                interestsCount: viewModel.interestsCount,
                                interestLimit: viewModel.interestLimit
                            )
                        }

                        // Attendees
                        if !viewModel.attendees.isEmpty {
                            AttendeesSection(
                                attendees: viewModel.attendees,
                                canReview: viewModel.canReview,
                                canSendInterests: viewModel.canSendInterests,
                                interestsRemaining: viewModel.interestsRemaining,
                                processingInterestFor: viewModel.processingInterestFor,
                                onTapAttendee: { attendee in
                                    viewModel.openUserProfile(attendee)
                                },
                                onReview: { attendee in
                                    viewModel.openReviewSheet(for: attendee)
                                },
                                onToggleInterest: { attendee in
                                    Task { await viewModel.toggleInterest(for: attendee) }
                                }
                            )
                        }

                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                }
            }

            // Bottom action
            bottomActionButton(for: event)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Hero Image

    @ViewBuilder
    private func heroImage(event: VanEvent) -> some View {
        GeometryReader { geo in
            let imgW = geo.size.width
            let imgH = imgW * 0.75 // 4:3 aspect ratio

            ZStack(alignment: .bottomLeading) {
                // Background image
                AsyncImage(url: URL(string: "https://picsum.photos/seed/\(event.id)/800/600")) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: imgW, height: imgH)
                            .clipped()
                    case .failure:
                        Rectangle().fill(Color(hex: "1A2820"))
                    case .empty:
                        Rectangle().fill(Color(hex: "1A2820"))
                            .overlay(ProgressView().tint(.white.opacity(0.25)))
                    @unknown default:
                        Rectangle().fill(Color(hex: "1A2820"))
                    }
                }
                .frame(width: imgW, height: imgH)

                // Green gradient overlays
                VStack(spacing: 0) {
                    Spacer()

                    // Bottom gradient (green tint)
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: accentGreen.opacity(0.5), location: 0.35),
                            .init(color: accentGreen.opacity(0.85), location: 0.7),
                            .init(color: AppTheme.background, location: 1.0),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: imgH * 0.6)
                }
                .frame(width: imgW, height: imgH)

                // Title overlay at bottom
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 10) {
                        StatusBadge(status: event.status)

                        if event.hasBuilder {
                            HStack(spacing: 4) {
                                Image(systemName: "wrench.and.screwdriver.fill")
                                    .font(.system(size: 9))
                                Text("Builder")
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .foregroundColor(AppTheme.primary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(.ultraThinMaterial)
                                    .environment(\.colorScheme, .dark)
                            )
                            .overlay(
                                Capsule()
                                    .stroke(AppTheme.primary.opacity(0.4), lineWidth: 1)
                            )
                        }

                        Spacer()

                        Image(systemName: event.activityIcon)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.85))
                            .padding(10)
                            .background(.white.opacity(0.12))
                            .clipShape(Circle())
                    }

                    Text(event.activityType.capitalized)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                        .textCase(.uppercase)
                        .tracking(1.5)

                    Text(event.title)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
            .frame(width: imgW, height: imgH)
        }
        .aspectRatio(4/3, contentMode: .fit)
    }

    // MARK: - Info Pills

    @ViewBuilder
    private func infoPills(event: VanEvent) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                infoPill(icon: "calendar", text: event.formattedDate)
                infoPill(icon: "mappin", text: event.approximateArea.isEmpty ? event.region : event.approximateArea)
                infoPill(icon: "person.2", text: "\(event.attendeesCount)/\(event.maxAttendees)")
            }
        }
    }

    private func infoPill(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(accentGreen)
            Text(text)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(AppTheme.textSecondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    // MARK: - About Section

    @ViewBuilder
    private func aboutSection(event: VanEvent) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("About")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)

            Text(event.description)
                .font(.system(size: 15))
                .foregroundColor(AppTheme.textSecondary)
                .lineSpacing(4)
        }
    }

    // MARK: - Photo Gallery

    @ViewBuilder
    private func photoGallery(event: VanEvent) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Gallery")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(0..<5, id: \.self) { index in
                        AsyncImage(url: URL(string: "https://picsum.photos/seed/\(event.id)_\(index)/400/300")) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            case .failure:
                                Rectangle().fill(Color(hex: "1A2820"))
                                    .overlay(
                                        Image(systemName: "photo")
                                            .foregroundColor(.white.opacity(0.15))
                                    )
                            case .empty:
                                Rectangle().fill(Color(hex: "1A2820"))
                                    .overlay(ProgressView().tint(.white.opacity(0.2)))
                            @unknown default:
                                Rectangle().fill(Color(hex: "1A2820"))
                            }
                        }
                        .frame(width: 160, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                    }
                }
            }
        }
    }

    // MARK: - Bottom Action Button

    @ViewBuilder
    private func bottomActionButton(for event: VanEvent) -> some View {
        if event.status == .completed && viewModel.canReview {
            Text("Event Completed - Leave Reviews Above")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(AppTheme.textTertiary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(AppTheme.card)
                )
        } else if event.isAttending {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                Text("Attending")
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(accentGreen)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(accentGreen.opacity(0.15))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(accentGreen.opacity(0.3), lineWidth: 1)
            )
        } else if event.isInterested {
            if event.status == .ongoing && event.checkInEnabled {
                Button {
                    showCheckInSheet = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "qrcode.viewfinder")
                        Text("Check In to Attend")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(accentGreen)
                    )
                }
            } else {
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "star.fill")
                        Text("You're Interested")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(AppTheme.primary.opacity(0.12))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(AppTheme.primary.opacity(0.25), lineWidth: 1)
                    )

                    if event.status == .upcoming {
                        Text("Check-in available when event starts")
                            .font(.caption)
                            .foregroundColor(AppTheme.textTertiary)
                    } else if event.status == .ongoing && !event.checkInEnabled {
                        Text("Waiting for organizer to enable check-in")
                            .font(.caption)
                            .foregroundColor(AppTheme.textTertiary)
                    }

                    Button {
                        Task { await viewModel.leaveEvent() }
                    } label: {
                        Text("Not Going")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textTertiary)
                    }
                    .disabled(viewModel.isProcessing)
                }
            }
        } else if event.status == .upcoming || event.status == .ongoing {
            Button {
                Task { await viewModel.joinEvent() }
            } label: {
                HStack(spacing: 8) {
                    if viewModel.isProcessing {
                        ProgressView()
                            .tint(.black)
                    } else {
                        Image(systemName: "star")
                        Text("I'm Interested")
                    }
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(accentGreen)
                )
            }
            .disabled(viewModel.isProcessing || event.attendeesCount >= event.maxAttendees)
        } else {
            Text("Event \(event.status.rawValue.capitalized)")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(AppTheme.textTertiary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(AppTheme.card)
                )
        }
    }
}

// MARK: - Admin Section

struct AdminSection: View {
    let event: VanEvent
    let checkInCode: String
    let onEnableCheckIn: () -> Void
    let onCompleteEvent: () -> Void

    private let accentGreen = Color(hex: "2E7D5A")

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.primary)
                Text("Admin Controls")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(AppTheme.primary)
            }

            HStack {
                Text("Check-in Code")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.textSecondary)
                Spacer()
                Text(checkInCode)
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.white.opacity(0.08))
                    )
            }

            if event.status == .upcoming {
                Button(action: onEnableCheckIn) {
                    HStack(spacing: 6) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 12))
                        Text("Enable Check-In & Start Event")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(accentGreen)
                    )
                }
            }

            if event.status == .ongoing {
                Button(action: onCompleteEvent) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                        Text("Complete Event")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(AppTheme.secondary)
                    )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppTheme.primary.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppTheme.primary.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Interest Limit Banner

struct InterestLimitBanner: View {
    let interestsCount: Int
    let interestLimit: Int

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "heart.circle.fill")
                .font(.title2)
                .foregroundColor(AppTheme.error)

            VStack(alignment: .leading, spacing: 2) {
                Text("Mark who you'd like to connect with")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                Text("If they mark you too, you'll match after the event!")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.textSecondary)
            }

            Spacer()

            Text("\(interestsCount)/\(interestLimit)")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(interestsCount >= interestLimit ? AppTheme.error : Color(hex: "2E7D5A"))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AppTheme.error.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(AppTheme.error.opacity(0.25), lineWidth: 1)
        )
    }
}

// MARK: - Attendees Section

struct AttendeesSection: View {
    let attendees: [EventAttendee]
    let canReview: Bool
    let canSendInterests: Bool
    let interestsRemaining: Int
    let processingInterestFor: String?
    let onTapAttendee: (EventAttendee) -> Void
    let onReview: (EventAttendee) -> Void
    let onToggleInterest: (EventAttendee) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Participants")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)

                Text("\(attendees.count)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(hex: "2E7D5A"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(Color(hex: "2E7D5A").opacity(0.15))
                    )

                Spacer()

                if canSendInterests {
                    HStack(spacing: 4) {
                        Image(systemName: "heart")
                            .font(.system(size: 10))
                        Text("Tap to connect")
                            .font(.system(size: 11))
                    }
                    .foregroundColor(AppTheme.textTertiary)
                }
            }

            ForEach(attendees) { attendee in
                AttendeeCard(
                    attendee: attendee,
                    canReview: canReview,
                    canSendInterests: canSendInterests,
                    interestsRemaining: interestsRemaining,
                    isProcessing: processingInterestFor == attendee.id,
                    onTap: { onTapAttendee(attendee) },
                    onReview: { onReview(attendee) },
                    onToggleInterest: { onToggleInterest(attendee) }
                )
            }
        }
    }
}

// MARK: - Attendee Card

struct AttendeeCard: View {
    let attendee: EventAttendee
    let canReview: Bool
    let canSendInterests: Bool
    let interestsRemaining: Int
    let isProcessing: Bool
    let onTap: () -> Void
    let onReview: () -> Void
    let onToggleInterest: () -> Void

    private let accentGreen = Color(hex: "2E7D5A")

    private var showInterestButton: Bool {
        canSendInterests && attendee.checkedIn
    }

    private var canToggleInterest: Bool {
        attendee.isInterestedIn || interestsRemaining > 0
    }

    var body: some View {
        HStack(spacing: 12) {
            Button {
                onTap()
            } label: {
                HStack(spacing: 12) {
                    KFImage(URL(string: attendee.profile.photoUrl))
                        .resizable()
                        .placeholder {
                            Circle()
                                .fill(Color.white.opacity(0.08))
                        }
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 48, height: 48)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text(attendee.profile.firstName)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.white)

                            Text("\(attendee.profile.age)")
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.textSecondary)

                            if attendee.trust.badges.contains("trusted_builder") {
                                Image(systemName: "wrench.and.screwdriver.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(AppTheme.primary)
                            }
                        }

                        HStack(spacing: 4) {
                            if attendee.checkedIn {
                                HStack(spacing: 3) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 10))
                                    Text("Here")
                                        .font(.system(size: 11, weight: .medium))
                                }
                                .foregroundColor(accentGreen)
                            } else {
                                HStack(spacing: 3) {
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 10))
                                    Text("Interested")
                                        .font(.system(size: 11, weight: .medium))
                                }
                                .foregroundColor(AppTheme.primary)
                            }
                            if attendee.trust.eventsAttended > 0 {
                                Text("• \(attendee.trust.eventsAttended) events")
                                    .font(.system(size: 11))
                                    .foregroundColor(AppTheme.textTertiary)
                            }
                        }
                    }
                }
            }
            .buttonStyle(.plain)

            Spacer()

            if showInterestButton {
                Button {
                    onToggleInterest()
                } label: {
                    ZStack {
                        if isProcessing {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: attendee.isInterestedIn ? "heart.fill" : "heart")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(attendee.isInterestedIn ? AppTheme.error : AppTheme.textTertiary)
                                .scaleEffect(attendee.isInterestedIn ? 1.1 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.5), value: attendee.isInterestedIn)
                        }
                    }
                    .frame(width: 42, height: 42)
                    .background(
                        Circle()
                            .fill(attendee.isInterestedIn ? AppTheme.error.opacity(0.12) : Color.white.opacity(0.06))
                    )
                    .overlay(
                        Circle()
                            .stroke(attendee.isInterestedIn ? AppTheme.error.opacity(0.3) : Color.white.opacity(0.08), lineWidth: 1)
                    )
                }
                .disabled(isProcessing || !canToggleInterest)
            } else if canReview {
                Button {
                    onReview()
                } label: {
                    Text("Review")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(accentGreen)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(
                            Capsule()
                                .fill(accentGreen.opacity(0.12))
                        )
                        .overlay(
                            Capsule()
                                .stroke(accentGreen.opacity(0.3), lineWidth: 1)
                        )
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}

// MARK: - Check-In Sheet

struct CheckInSheet: View {
    @Binding var code: String
    let onSubmit: () -> Void
    @Environment(\.dismiss) private var dismiss

    private let accentGreen = Color(hex: "2E7D5A")

    var body: some View {
        VStack(spacing: 20) {
            Text("Enter Check-In Code")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)

            Text("Ask the event organizer for the code")
                .font(.system(size: 14))
                .foregroundColor(AppTheme.textSecondary)

            TextField("Code", text: $code)
                .font(.system(size: 16, weight: .medium))
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(0.06))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .textInputAutocapitalization(.characters)
                .foregroundColor(.white)
                .padding(.horizontal)

            HStack(spacing: 16) {
                Button("Cancel") {
                    dismiss()
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(AppTheme.textSecondary)

                Button {
                    onSubmit()
                } label: {
                    Text("Check In")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(accentGreen)
                        )
                }
                .disabled(code.isEmpty)
                .opacity(code.isEmpty ? 0.5 : 1.0)
            }
        }
        .padding()
        .background(AppTheme.background.ignoresSafeArea())
    }
}

// MARK: - Review Sheet

struct ReviewSheet: View {
    let attendee: EventAttendee
    let onSubmit: (Bool) -> Void
    @Environment(\.dismiss) private var dismiss

    private let accentGreen = Color(hex: "2E7D5A")

    var body: some View {
        VStack(spacing: 24) {
            KFImage(URL(string: attendee.profile.photoUrl))
                .resizable()
                .placeholder {
                    Circle()
                        .fill(Color.white.opacity(0.08))
                }
                .aspectRatio(contentMode: .fill)
                .frame(width: 80, height: 80)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )

            Text("How was meeting \(attendee.profile.firstName)?")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)

            Text("Your review helps build trust in our community")
                .font(.system(size: 14))
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 24) {
                Button {
                    onSubmit(false)
                    dismiss()
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "hand.thumbsdown.fill")
                            .font(.system(size: 28))
                        Text("Not Great")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(AppTheme.error)
                    .frame(width: 90, height: 90)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(AppTheme.error.opacity(0.08))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(AppTheme.error.opacity(0.25), lineWidth: 1)
                    )
                }

                Button {
                    onSubmit(true)
                    dismiss()
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "hand.thumbsup.fill")
                            .font(.system(size: 28))
                        Text("Great!")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(accentGreen)
                    .frame(width: 90, height: 90)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(accentGreen.opacity(0.08))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(accentGreen.opacity(0.25), lineWidth: 1)
                    )
                }
            }
        }
        .padding()
        .background(AppTheme.background.ignoresSafeArea())
    }
}

import FirebaseFunctions
