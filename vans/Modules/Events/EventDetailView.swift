import SwiftUI
import Kingfisher

struct EventDetailView: View {
    @StateObject var viewModel: EventDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showCheckInSheet = false
    @State private var checkInCode = ""
    @State private var selectedTab = 0

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Custom Navigation Header
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Back")
                        }
                        .foregroundColor(AppTheme.textPrimary)
                    }

                    Spacer()

                    Text("Event")
                        .font(.headline)
                        .foregroundColor(AppTheme.textPrimary)

                    Spacer()

                    // Invisible spacer for centering
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Back")
                    }
                    .opacity(0)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(AppTheme.background)

                if viewModel.isLoading && viewModel.event == nil {
                    Spacer()
                    ProgressView()
                        .tint(AppTheme.primary)
                    Spacer()
                } else if let event = viewModel.event {
                    // Tab Picker (only show if interested or attending)
                    if event.isInterested {
                        Picker("", selection: $selectedTab) {
                            Text("Details").tag(0)
                            Text("Chat").tag(1)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }

                    if selectedTab == 0 {
                        // Details Tab
                        ZStack(alignment: .bottom) {
                            ScrollView(showsIndicators: false) {
                                VStack(alignment: .leading, spacing: 24) {
                                    // Header
                                    EventDetailHeader(event: event, isAdmin: viewModel.isAdmin)

                                    // Description
                                    if !event.description.isEmpty {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("About")
                                                .font(.headline)
                                                .foregroundColor(AppTheme.textPrimary)
                                            Text(event.description)
                                                .font(.body)
                                                .foregroundColor(AppTheme.textSecondary)
                                        }
                                    }

                                    // Admin Section
                                    if viewModel.isAdmin, let checkInCode = viewModel.checkInCode {
                                        AdminSection(
                                            event: event,
                                            checkInCode: checkInCode,
                                            onEnableCheckIn: { Task { await viewModel.enableCheckIn() } },
                                            onCompleteEvent: { Task { await viewModel.completeEvent() } }
                                        )
                                    }

                                    // Interest limit indicator (only when can send interests)
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
                                .padding(16)
                            }

                            // Bottom action button
                            bottomActionButton(for: event)
                                .padding(.horizontal, 16)
                                .padding(.bottom, 16)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        // Chat Tab
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

    @ViewBuilder
    private func bottomActionButton(for event: VanEvent) -> some View {
        if event.status == .completed && viewModel.canReview {
            Text("Event Completed - Leave Reviews Above")
                .font(.headline)
                .foregroundColor(AppTheme.textTertiary)
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        } else if event.isAttending {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                Text("Attending")
            }
            .font(.headline)
            .foregroundColor(AppTheme.accent)
            .frame(maxWidth: .infinity)
            .padding()
            .background(AppTheme.accent.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        } else if event.isInterested {
            if event.status == .ongoing && event.checkInEnabled {
                Button {
                    showCheckInSheet = true
                } label: {
                    HStack {
                        Image(systemName: "qrcode.viewfinder")
                        Text("Check In to Attend")
                    }
                    .font(.headline)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppTheme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            } else {
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "star.fill")
                        Text("You're Interested")
                    }
                    .font(.headline)
                    .foregroundColor(AppTheme.primary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppTheme.primary.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 14))

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
                HStack {
                    if viewModel.isProcessing {
                        ProgressView()
                            .tint(.black)
                    } else {
                        Image(systemName: "star")
                        Text("I'm Interested")
                    }
                }
                .font(.headline)
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppTheme.primary)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(viewModel.isProcessing || event.attendeesCount >= event.maxAttendees)
        } else {
            Text("Event \(event.status.rawValue.capitalized)")
                .font(.headline)
                .foregroundColor(AppTheme.textTertiary)
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}

struct EventDetailHeader: View {
    let event: VanEvent
    let isAdmin: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: event.activityIcon)
                    .font(.system(size: 32))
                    .foregroundColor(AppTheme.accent)
                    .frame(width: 64, height: 64)
                    .background(AppTheme.accentDark)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.textPrimary)

                    Text(event.activityType.capitalized)
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                }

                Spacer()

                StatusBadge(status: event.status)
            }

            VStack(alignment: .leading, spacing: 12) {
                InfoRow(icon: "calendar", text: event.formattedDate)
                InfoRow(icon: "mappin.circle", text: event.approximateArea.isEmpty ? event.region : event.approximateArea)
                InfoRow(icon: "person.2", text: "\(event.attendeesCount)/\(event.maxAttendees) interested")
            }
        }
        .padding(16)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct InfoRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(AppTheme.textTertiary)
                .frame(width: 20)
            Text(text)
                .font(.subheadline)
                .foregroundColor(AppTheme.textSecondary)
        }
    }
}

struct AdminSection: View {
    let event: VanEvent
    let checkInCode: String
    let onEnableCheckIn: () -> Void
    let onCompleteEvent: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Admin Controls")
                .font(.headline)
                .foregroundColor(AppTheme.primary)

            HStack {
                Text("Check-in Code:")
                    .foregroundColor(AppTheme.textSecondary)
                Text(checkInCode)
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.textPrimary)
            }

            if event.status == .upcoming {
                Button(action: onEnableCheckIn) {
                    Text("Enable Check-In & Start Event")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(AppTheme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }

            if event.status == .ongoing {
                Button(action: onCompleteEvent) {
                    Text("Complete Event")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(AppTheme.secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding(16)
        .background(AppTheme.primary.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

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
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(AppTheme.textPrimary)
                Text("If they mark you too, you'll match after the event!")
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
            }

            Spacer()

            Text("\(interestsCount)/\(interestLimit)")
                .font(.headline)
                .foregroundColor(interestsCount >= interestLimit ? AppTheme.error : AppTheme.accent)
        }
        .padding(16)
        .background(AppTheme.error.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppTheme.error.opacity(0.3), lineWidth: 1)
        )
    }
}

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
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Participants (\(attendees.count))")
                    .font(.headline)
                    .foregroundColor(AppTheme.textPrimary)

                Spacer()

                if canSendInterests {
                    Text("Tap ❤️ to connect")
                        .font(.caption)
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

struct AttendeeCard: View {
    let attendee: EventAttendee
    let canReview: Bool
    let canSendInterests: Bool
    let interestsRemaining: Int
    let isProcessing: Bool
    let onTap: () -> Void
    let onReview: () -> Void
    let onToggleInterest: () -> Void

    // Only show interest button for checked-in attendees
    private var showInterestButton: Bool {
        canSendInterests && attendee.checkedIn
    }

    // Can add interest if remaining or already interested (to remove)
    private var canToggleInterest: Bool {
        attendee.isInterestedIn || interestsRemaining > 0
    }

    var body: some View {
        HStack(spacing: 12) {
            // Tappable profile area
            Button {
                onTap()
            } label: {
                HStack(spacing: 12) {
                    KFImage(URL(string: attendee.profile.photoUrl))
                        .resizable()
                        .placeholder {
                            Circle()
                                .fill(AppTheme.card)
                        }
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text(attendee.profile.firstName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(AppTheme.textPrimary)

                            Text("\(attendee.profile.age)")
                                .font(.caption)
                                .foregroundColor(AppTheme.textSecondary)

                            // Builder badge
                            if attendee.trust.badges.contains("trusted_builder") {
                                Image(systemName: "wrench.and.screwdriver.fill")
                                    .font(.caption2)
                                    .foregroundColor(AppTheme.primary)
                            }
                        }

                        HStack(spacing: 4) {
                            if attendee.checkedIn {
                                HStack(spacing: 2) {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Here")
                                }
                                .foregroundColor(AppTheme.accent)
                                .font(.caption2)
                            } else {
                                HStack(spacing: 2) {
                                    Image(systemName: "star.fill")
                                    Text("Interested")
                                }
                                .foregroundColor(AppTheme.primary)
                                .font(.caption2)
                            }
                            if attendee.trust.eventsAttended > 0 {
                                Text("• \(attendee.trust.eventsAttended) events")
                                    .font(.caption2)
                                    .foregroundColor(AppTheme.textTertiary)
                            }
                        }
                    }
                }
            }
            .buttonStyle(.plain)

            Spacer()

            // Action buttons
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
                                .font(.title2)
                                .foregroundColor(attendee.isInterestedIn ? AppTheme.error : AppTheme.textTertiary)
                        }
                    }
                    .frame(width: 44, height: 44)
                    .background(attendee.isInterestedIn ? AppTheme.error.opacity(0.15) : AppTheme.surface)
                    .clipShape(Circle())
                }
                .disabled(isProcessing || !canToggleInterest)
            } else if canReview {
                Button {
                    onReview()
                } label: {
                    Text("Review")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(AppTheme.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(AppTheme.secondary.opacity(0.2))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(12)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct CheckInSheet: View {
    @Binding var code: String
    let onSubmit: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text("Enter Check-In Code")
                .font(.headline)

            Text("Ask the event organizer for the code")
                .font(.subheadline)
                .foregroundColor(.secondary)

            TextField("Code", text: $code)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.characters)
                .padding(.horizontal)

            HStack(spacing: 16) {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(.secondary)

                Button("Check In") {
                    onSubmit()
                }
                .fontWeight(.semibold)
                .disabled(code.isEmpty)
            }
        }
        .padding()
    }
}

struct ReviewSheet: View {
    let attendee: EventAttendee
    let onSubmit: (Bool) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            KFImage(URL(string: attendee.profile.photoUrl))
                .resizable()
                .placeholder {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                }
                .aspectRatio(contentMode: .fill)
                .frame(width: 80, height: 80)
                .clipShape(Circle())

            Text("How was meeting \(attendee.profile.firstName)?")
                .font(.headline)

            Text("Your review helps build trust in our community")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 32) {
                Button {
                    onSubmit(false)
                    dismiss()
                } label: {
                    VStack {
                        Image(systemName: "hand.thumbsdown.fill")
                            .font(.system(size: 32))
                        Text("Not Great")
                            .font(.caption)
                    }
                    .foregroundColor(AppTheme.error)
                    .frame(width: 80, height: 80)
                    .background(AppTheme.error.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                Button {
                    onSubmit(true)
                    dismiss()
                } label: {
                    VStack {
                        Image(systemName: "hand.thumbsup.fill")
                            .font(.system(size: 32))
                        Text("Great!")
                            .font(.caption)
                    }
                    .foregroundColor(AppTheme.accent)
                    .frame(width: 80, height: 80)
                    .background(AppTheme.accent.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
        }
        .padding()
    }
}

import FirebaseFunctions

