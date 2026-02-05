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

                                    // Builder Help Banner (show for completed or ongoing events)
                                    if event.status == .completed || event.status == .ongoing {
                                        BuilderHelpBanner(eventId: viewModel.eventId)
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

// MARK: - Builder Help Banner

struct BuilderHelpBanner: View {
    let eventId: String
    @State private var showBuilderSheet = false
    @State private var selectedCategory: BuilderCategory?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "wrench.and.screwdriver.fill")
                    .font(.title2)
                    .foregroundColor(AppTheme.primary)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Need help with your van?")
                        .font(.headline)
                        .foregroundColor(AppTheme.textPrimary)

                    Text("Get trusted peer help from builders in the community")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }
            }

            // Category buttons
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(BuilderCategory.allCases.prefix(5)) { category in
                    Button {
                        selectedCategory = category
                        showBuilderSheet = true
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: category.icon)
                                .font(.title3)
                            Text(category.displayName)
                                .font(.caption2)
                        }
                        .foregroundColor(AppTheme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(AppTheme.surface)
                        .cornerRadius(10)
                    }
                }
            }
        }
        .padding(16)
        .background(AppTheme.primary.opacity(0.1))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppTheme.primary.opacity(0.3), lineWidth: 1)
        )
        .sheet(isPresented: $showBuilderSheet) {
            BuilderListSheetView(category: selectedCategory, sourceEventId: eventId)
        }
    }
}

// MARK: - Builder List Sheet View (Wrapper for presentation)

struct BuilderListSheetView: View {
    let category: BuilderCategory?
    let sourceEventId: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            BuilderListContentView(category: category, sourceEventId: sourceEventId, onDismiss: { dismiss() })
        }
    }
}

struct BuilderListContentView: View {
    @StateObject private var viewModel: BuilderListSheetViewModel
    let onDismiss: () -> Void

    init(category: BuilderCategory?, sourceEventId: String, onDismiss: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: BuilderListSheetViewModel(
            initialCategory: category,
            sourceEventId: sourceEventId
        ))
        self.onDismiss = onDismiss
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Category Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        CategoryChip(
                            title: "All",
                            icon: "square.grid.2x2.fill",
                            isSelected: viewModel.selectedCategory == nil
                        ) {
                            viewModel.selectCategory(nil)
                        }

                        ForEach(BuilderCategory.allCases) { category in
                            CategoryChip(
                                title: category.displayName,
                                icon: category.icon,
                                isSelected: viewModel.selectedCategory == category
                            ) {
                                viewModel.selectCategory(category)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 12)

                // Content
                if viewModel.isLoading && viewModel.builders.isEmpty {
                    VStack {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.primary))
                        Spacer()
                    }
                } else if viewModel.builders.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "wrench.and.screwdriver")
                            .font(.system(size: 50))
                            .foregroundColor(AppTheme.textTertiary)
                        Text("No builders found")
                            .font(.headline)
                            .foregroundColor(AppTheme.textPrimary)
                        Text("Check back soon!")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textSecondary)
                        Spacer()
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.builders) { builder in
                                BuilderCard(
                                    builder: builder,
                                    onTap: { viewModel.selectedBuilder = builder },
                                    onBook: { viewModel.builderToBook = builder }
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .navigationTitle("Get Help")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Close") {
                    onDismiss()
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.loadBuilders()
            }
        }
        .sheet(item: $viewModel.builderToBook) { builder in
            BookSessionSheetView(builder: builder, category: viewModel.selectedCategory, sourceEventId: viewModel.sourceEventId)
        }
    }
}

// MARK: - Builder List Sheet ViewModel

@MainActor
final class BuilderListSheetViewModel: ObservableObject {
    @Published var builders: [BuilderProfile] = []
    @Published var selectedCategory: BuilderCategory?
    @Published var isLoading = false
    @Published var selectedBuilder: BuilderProfile?
    @Published var builderToBook: BuilderProfile?

    let sourceEventId: String
    private let functions = Functions.functions()

    init(initialCategory: BuilderCategory?, sourceEventId: String) {
        self.selectedCategory = initialCategory
        self.sourceEventId = sourceEventId
    }

    func selectCategory(_ category: BuilderCategory?) {
        selectedCategory = category
        Task { await loadBuilders() }
    }

    func loadBuilders() async {
        guard !isLoading else { return }
        isLoading = true

        do {
            var params: [String: Any] = ["limit": 20, "eventId": sourceEventId]
            if let category = selectedCategory {
                params["category"] = category.rawValue
            }

            let result = try await functions.httpsCallable("getBuilders").call(params)

            guard let data = result.data as? [String: Any],
                  let success = data["success"] as? Bool, success,
                  let buildersData = data["builders"] as? [[String: Any]] else {
                return
            }

            builders = buildersData.compactMap { parseBuilder($0) }
        } catch {
            print("Error loading builders: \(error)")
        }

        isLoading = false
    }

    private func parseBuilder(_ data: [String: Any]) -> BuilderProfile? {
        guard let userId = data["odId"] as? String ?? data["userId"] as? String,
              let categoriesRaw = data["categories"] as? [String],
              let bio = data["bio"] as? String,
              let pricesData = data["sessionPrices"] as? [String: Any],
              let p15 = pricesData["15"] as? Int,
              let p30 = pricesData["30"] as? Int else { return nil }

        let categories = categoriesRaw.compactMap { BuilderCategory(rawValue: $0) }
        var profile: UserProfile?
        if let pd = data["profile"] as? [String: Any] {
            profile = UserProfile(
                firstName: pd["firstName"] as? String ?? "",
                photoUrl: pd["photoUrl"] as? String ?? "",
                age: pd["age"] as? Int ?? 0,
                gender: Gender(rawValue: pd["gender"] as? String ?? "") ?? .male,
                vanLifeStatus: VanLifeStatus(rawValue: pd["vanLifeStatus"] as? String ?? "") ?? .planning,
                region: pd["region"] as? String ?? "",
                activities: pd["activities"] as? [String] ?? [],
                bio: pd["bio"] as? String
            )
        }

        return BuilderProfile(
            userId: userId,
            categories: categories,
            bio: bio,
            sessionPrices: SessionPrices(fifteenMin: p15, thirtyMin: p30),
            availability: data["availability"] as? String ?? "",
            status: .approved,
            totalSessions: data["totalSessions"] as? Int ?? 0,
            completedSessions: data["completedSessions"] as? Int ?? 0,
            positiveReviews: data["positiveReviews"] as? Int ?? 0,
            negativeReviews: data["negativeReviews"] as? Int ?? 0,
            rating: data["rating"] as? Int ?? 100,
            createdAt: nil, updatedAt: nil,
            profile: profile, trust: nil, isPremium: data["isPremium"] as? Bool,
            sharedEventsCount: data["sharedEventsCount"] as? Int
        )
    }
}

// MARK: - Book Session Sheet View

struct BookSessionSheetView: View {
    let builder: BuilderProfile
    let category: BuilderCategory?
    let sourceEventId: String
    @Environment(\.dismiss) private var dismiss

    @State private var selectedCategory: BuilderCategory?
    @State private var selectedDuration: Int = 15
    @State private var isBooking = false
    @State private var errorMessage: String?
    @State private var successMessage: String?

    private let functions = Functions.functions()

    init(builder: BuilderProfile, category: BuilderCategory?, sourceEventId: String) {
        self.builder = builder
        self.category = category
        self.sourceEventId = sourceEventId
        _selectedCategory = State(initialValue: category ?? builder.categories.first)
    }

    var currentPrice: Int {
        builder.sessionPrices.price(for: selectedDuration)
    }

    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Builder info
                        HStack(spacing: 12) {
                            if let photoUrl = builder.profile?.photoUrl {
                                KFImage(URL(string: photoUrl))
                                    .placeholder { Circle().fill(AppTheme.surface) }
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 50, height: 50)
                                    .clipShape(Circle())
                            }

                            VStack(alignment: .leading) {
                                Text(builder.profile?.firstName ?? "Builder")
                                    .font(.headline)
                                    .foregroundColor(AppTheme.textPrimary)
                                Text("\(builder.rating)% positive")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.textSecondary)
                            }
                            Spacer()
                        }
                        .padding()
                        .background(AppTheme.card)
                        .cornerRadius(12)

                        // Category
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Category")
                                .font(.headline)
                                .foregroundColor(AppTheme.textPrimary)

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                ForEach(builder.categories) { cat in
                                    Button {
                                        selectedCategory = cat
                                    } label: {
                                        HStack {
                                            Image(systemName: cat.icon)
                                            Text(cat.displayName)
                                            Spacer()
                                            if selectedCategory == cat {
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                        .font(.subheadline)
                                        .foregroundColor(selectedCategory == cat ? .black : AppTheme.textPrimary)
                                        .padding()
                                        .background(selectedCategory == cat ? AppTheme.primary : AppTheme.card)
                                        .cornerRadius(10)
                                    }
                                }
                            }
                        }

                        // Duration
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Duration")
                                .font(.headline)
                                .foregroundColor(AppTheme.textPrimary)

                            HStack(spacing: 12) {
                                DurationCard(duration: 15, price: builder.sessionPrices.fifteenMin, description: "Quick help", isSelected: selectedDuration == 15) {
                                    selectedDuration = 15
                                }
                                DurationCard(duration: 30, price: builder.sessionPrices.thirtyMin, description: "In-depth", isSelected: selectedDuration == 30) {
                                    selectedDuration = 30
                                }
                            }
                        }

                        // Messages
                        if let error = errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(AppTheme.error)
                        }
                        if let success = successMessage {
                            Text(success)
                                .font(.caption)
                                .foregroundColor(AppTheme.accent)
                        }

                        // Book button
                        Button {
                            Task { await bookSession() }
                        } label: {
                            HStack {
                                if isBooking {
                                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .black))
                                } else {
                                    Text("Pay $\(currentPrice) & Start")
                                }
                            }
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppTheme.accent)
                            .cornerRadius(14)
                        }
                        .disabled(isBooking || selectedCategory == nil)
                    }
                    .padding()
                }
            }
            .navigationTitle("Book Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func bookSession() async {
        guard let category = selectedCategory else { return }
        isBooking = true
        errorMessage = nil

        do {
            let params: [String: Any] = [
                "builderId": builder.userId,
                "category": category.rawValue,
                "duration": selectedDuration,
                "sourceEventId": sourceEventId
            ]

            let result = try await functions.httpsCallable("createBuilderSession").call(params)

            guard let data = result.data as? [String: Any],
                  let success = data["success"] as? Bool, success,
                  let sessionData = data["session"] as? [String: Any],
                  let sessionId = sessionData["id"] as? String else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create session"])
            }

            // Auto-confirm payment for testing
            let payResult = try await functions.httpsCallable("confirmBuilderSessionPayment").call([
                "sessionId": sessionId,
                "paymentId": "test_\(UUID().uuidString)"
            ])

            if let payData = payResult.data as? [String: Any],
               let paySuccess = payData["success"] as? Bool, paySuccess {
                successMessage = "Session created! Chat is now open."
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    dismiss()
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isBooking = false
    }
}

import FirebaseFunctions

// MARK: - Helper Views

private struct CategoryChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? .black : AppTheme.textPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? AppTheme.accent : AppTheme.surface)
            .cornerRadius(16)
        }
    }
}

private struct BuilderCard: View {
    let builder: BuilderProfile
    let onTap: () -> Void
    let onBook: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onTap) {
                HStack(spacing: 12) {
                    // Photo
                    if let photoUrl = builder.profile?.photoUrl {
                        KFImage(URL(string: photoUrl))
                            .placeholder {
                                Circle().fill(AppTheme.surface)
                            }
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(AppTheme.surface)
                            .frame(width: 50, height: 50)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundColor(AppTheme.textSecondary)
                            )
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(builder.profile?.firstName ?? "Builder")
                            .font(.headline)
                            .foregroundColor(AppTheme.textPrimary)

                        HStack(spacing: 8) {
                            if builder.completedSessions > 0 {
                                HStack(spacing: 2) {
                                    Image(systemName: "hand.thumbsup.fill")
                                        .font(.caption2)
                                    Text("\(builder.rating)%")
                                        .font(.caption)
                                }
                                .foregroundColor(builder.rating >= 80 ? AppTheme.accent : AppTheme.textSecondary)
                            }

                            Text("From $\(builder.sessionPrices.fifteenMin)")
                                .font(.caption)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(AppTheme.textTertiary)
                }
                .padding()
            }
            .buttonStyle(.plain)

            // Book button
            Button(action: onBook) {
                Text("Book Session")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(AppTheme.accent)
            }
        }
        .background(AppTheme.card)
        .cornerRadius(12)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct DurationCard: View {
    let duration: Int
    let price: Int
    let description: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text("\(duration) min")
                    .font(.headline)
                    .foregroundColor(isSelected ? .black : AppTheme.textPrimary)

                Text("$\(price)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(isSelected ? .black : AppTheme.primary)

                Text(description)
                    .font(.caption)
                    .foregroundColor(isSelected ? .black.opacity(0.7) : AppTheme.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? AppTheme.accent : AppTheme.surface)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? AppTheme.accent : Color.clear, lineWidth: 2)
            )
        }
    }
}
