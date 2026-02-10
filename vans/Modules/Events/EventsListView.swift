import SwiftUI
import Kingfisher

// MARK: - Date Filter

enum EventDateFilter: String, CaseIterable {
    case all = "All"
    case today = "Today"
    case thisWeek = "This Week"
    case nextWeek = "Next Week"
    case later = "Later"
}

struct EventsListView: ActionableView {
    @ObservedObject var viewModel: EventsListViewModel
    @State private var showCreateEvent = false
    @State private var showLocationFilter = false
    @State private var currentIndex = 0
    @State private var dragOffset: CGFloat = 0
    @State private var dateFilter: EventDateFilter = .all

    private let accentGreen = Color(hex: "2E7D5A") // accentPrimary

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar
                dateFilterBar

                if viewModel.isLoading && viewModel.events.isEmpty {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: accentGreen))
                        .scaleEffect(1.5)
                    Spacer()
                } else if filteredEvents.isEmpty {
                    Spacer()
                    emptyState
                    Spacer()
                } else if currentIndex >= filteredEvents.count {
                    Spacer()
                    allSeenState
                    Spacer()
                } else {
                    cardStack
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showCreateEvent, onDismiss: {
            Task { await viewModel.refreshEvents() }
        }) {
            CreateEventView()
        }
        .sheet(isPresented: $showLocationFilter) {
            LocationSearchView { location in
                viewModel.selectedLocation = location
                Task { await viewModel.loadEvents() }
            }
        }
        .task {
            await viewModel.loadEvents()
        }
        .onChange(of: viewModel.events.count) { _ in
            currentIndex = 0
            dragOffset = 0
        }
        .onChange(of: dateFilter) { _ in
            currentIndex = 0
            dragOffset = 0
        }
    }

    // MARK: - Filtered Events

    private var filteredEvents: [VanEvent] {
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)

        switch dateFilter {
        case .all:
            return viewModel.events
        case .today:
            let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday)!
            return viewModel.events.filter { $0.date >= startOfToday && $0.date < endOfToday }
        case .thisWeek:
            guard let weekEnd = calendar.date(byAdding: .day, value: 7 - calendar.component(.weekday, from: now) + 1, to: startOfToday) else { return viewModel.events }
            return viewModel.events.filter { $0.date >= startOfToday && $0.date < weekEnd }
        case .nextWeek:
            guard let thisWeekEnd = calendar.date(byAdding: .day, value: 7 - calendar.component(.weekday, from: now) + 1, to: startOfToday),
                  let nextWeekEnd = calendar.date(byAdding: .day, value: 7, to: thisWeekEnd) else { return viewModel.events }
            return viewModel.events.filter { $0.date >= thisWeekEnd && $0.date < nextWeekEnd }
        case .later:
            guard let thisWeekEnd = calendar.date(byAdding: .day, value: 7 - calendar.component(.weekday, from: now) + 1, to: startOfToday),
                  let nextWeekEnd = calendar.date(byAdding: .day, value: 7, to: thisWeekEnd) else { return viewModel.events }
            return viewModel.events.filter { $0.date >= nextWeekEnd }
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack {
            Text("Events")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(AppTheme.textPrimary)

            Spacer()

            Button {
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
                showLocationFilter = true
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: viewModel.selectedLocation != nil ? "mappin.circle.fill" : "mappin")
                        .font(.system(size: 14, weight: .medium))
                    if let location = viewModel.selectedLocation {
                        Text(location.name)
                            .font(.caption)
                            .lineLimit(1)
                        Button {
                            viewModel.clearLocationFilter()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.4))
                        }
                    }
                }
                .foregroundColor(viewModel.selectedLocation != nil ? accentGreen : .white.opacity(0.7))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(0.06))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(
                            viewModel.selectedLocation != nil ? accentGreen.opacity(0.4) : Color.white.opacity(0.12),
                            lineWidth: 1
                        )
                )
            }

            if viewModel.canCreateEvents {
                Button {
                    showCreateEvent = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(8)
                        .background(
                            Circle().fill(Color.white.opacity(0.06))
                        )
                        .overlay(
                            Circle().stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 10)
    }

    // MARK: - Date Filter

    private var dateFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(EventDateFilter.allCases, id: \.self) { filter in
                    Button {
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred(intensity: 0.6)
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            dateFilter = filter
                        }
                    } label: {
                        Text(filter.rawValue)
                            .font(.system(size: 14, weight: dateFilter == filter ? .semibold : .regular))
                            .foregroundColor(dateFilter == filter ? accentGreen : AppTheme.textSecondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(
                                Capsule()
                                    .fill(dateFilter == filter ? accentGreen.opacity(0.12) : Color.clear)
                            )
                            .overlay(
                                Capsule()
                                    .stroke(dateFilter == filter ? accentGreen.opacity(0.3) : Color.clear, lineWidth: 1)
                            )
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 12)
    }

    // MARK: - Empty / All-Seen States

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 48))
                .foregroundColor(AppTheme.textTertiary)
            Text("No upcoming events")
                .foregroundColor(AppTheme.textSecondary)
                .font(.headline)
            Text("Check back later for community meetups")
                .foregroundColor(AppTheme.textTertiary)
                .font(.subheadline)
        }
    }

    private var allSeenState: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 48))
                .foregroundColor(accentGreen.opacity(0.6))
            Text("You've seen all events")
                .foregroundColor(AppTheme.textSecondary)
                .font(.headline)
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    currentIndex = 0
                }
            } label: {
                Text("Start Over")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(accentGreen)
            }
        }
    }

    // MARK: - Card Stack

    private var cardStack: some View {
        GeometryReader { geo in
            let cardW = geo.size.width
            let cardH = geo.size.height - 36
            // Progress 0→1 as user drags up (clamped). Reaches 1.0 at 40% card height.
            let dragProgress = min(1.0, max(0, -dragOffset / (cardH * 0.4)))

            ZStack {
                ForEach(visibleCards.reversed(), id: \.offset) { item in
                    let stackPos = item.offset - currentIndex

                    stackedCard(
                        event: item.element,
                        stackPos: stackPos,
                        dragProgress: dragProgress,
                        cardW: cardW,
                        cardH: cardH
                    )
                    .zIndex(Double(100 - stackPos))
                    .onTapGesture {
                        if stackPos == 0 {
                            viewModel.openEventDetail(item.element)
                        }
                    }
                    .gesture(stackPos == 0 ? swipeGesture(cardHeight: cardH) : nil)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
        .clipped()
        .padding(.horizontal, 16)
        .padding(.bottom, 86)
    }

    // Compute resting Y offset for a given stack position
    private func restingY(stackPos: Int, cardH: CGFloat) -> CGFloat {
        guard stackPos > 0 else { return 0 }
        let scaleDrop: CGFloat = 0.04
        let peekPerCard: CGFloat = 12.0
        let scale = 1.0 - CGFloat(stackPos) * scaleDrop
        let peek = peekPerCard * CGFloat(stackPos)
        return -(cardH * (1.0 - scale) / 2.0 + peek)
    }

    private func restingScale(stackPos: Int) -> CGFloat {
        guard stackPos > 0 else { return 1.0 }
        return 1.0 - CGFloat(stackPos) * 0.04
    }

    private func restingOpacity(stackPos: Int) -> Double {
        switch stackPos {
        case 0: return 1.0
        case 1: return 0.6
        default: return 0.3
        }
    }

    private func stackedCard(
        event: VanEvent,
        stackPos: Int,
        dragProgress: CGFloat,
        cardW: CGFloat,
        cardH: CGFloat
    ) -> some View {
        let curY = restingY(stackPos: stackPos, cardH: cardH)
        let nextY = restingY(stackPos: max(0, stackPos - 1), cardH: cardH)
        let curScale = restingScale(stackPos: stackPos)
        let nextScale = restingScale(stackPos: max(0, stackPos - 1))
        let curOpa = restingOpacity(stackPos: stackPos)
        let nextOpa = restingOpacity(stackPos: max(0, stackPos - 1))

        let isFront = stackPos == 0
        let yOff = isFront ? dragOffset : curY + (nextY - curY) * dragProgress
        let scl = isFront ? 1.0 : curScale + (nextScale - curScale) * dragProgress
        let opa = isFront ? curOpa : curOpa + (nextOpa - curOpa) * dragProgress

        return EventSwipeCard(
            event: event,
            cardWidth: cardW,
            cardHeight: cardH,
            greenColor: accentGreen,
            onInterestTap: {
                viewModel.toggleInterest(for: event)
            }
        )
        .scaleEffect(scl)
        .offset(y: yOff)
        .opacity(opa)
    }

    private var visibleCards: [EnumeratedSequence<[VanEvent]>.Element] {
        Array(filteredEvents.enumerated())
            .filter { $0.offset >= currentIndex && $0.offset < currentIndex + 3 }
    }

    // MARK: - Swipe Gesture

    private func swipeGesture(cardHeight: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 15)
            .onChanged { value in
                if value.translation.height < 0 {
                    dragOffset = value.translation.height
                } else {
                    dragOffset = value.translation.height * 0.2
                }
            }
            .onEnded { value in
                let threshold = -cardHeight * 0.22
                let shouldDismiss = value.translation.height < threshold
                    || value.predictedEndTranslation.height < -cardHeight * 0.5

                if shouldDismiss {
                    // Fly front card off the top; behind cards follow via dragProgress → 1.0
                    withAnimation(.easeOut(duration: 0.3)) {
                        dragOffset = -cardHeight * 1.5
                    }
                    // After fly-off, behind cards are already at their next positions
                    // (dragProgress clamped to 1.0), so index change causes no jump
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
                        currentIndex += 1
                        dragOffset = 0
                    }
                } else {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
                        dragOffset = 0
                    }
                }
            }
    }
}

// MARK: - Event Swipe Card

struct EventSwipeCard: View {
    let event: VanEvent
    let cardWidth: CGFloat
    let cardHeight: CGFloat
    let greenColor: Color
    var onInterestTap: (() -> Void)? = nil

    private let heartColor = Color(hex: "E8B86D") // accentWarning / sand-gold

    var body: some View {
        ZStack {
            // Background image
            if let firstPhoto = event.photos.first, let url = URL(string: firstPhoto) {
                KFImage(url)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: cardWidth, height: cardHeight)
            } else {
                placeholderBg
                    .overlay(
                        Image(systemName: event.activityIcon)
                            .font(.system(size: 40))
                            .foregroundColor(.white.opacity(0.15))
                    )
                    .frame(width: cardWidth, height: cardHeight)
            }

            // Green gradient overlays
            VStack(spacing: 0) {
                // Top gradient
                LinearGradient(
                    stops: [
                        .init(color: greenColor.opacity(0.8), location: 0),
                        .init(color: greenColor.opacity(0.35), location: 0.5),
                        .init(color: .clear, location: 1.0),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: cardHeight * 0.28)

                Spacer()

                // Bottom gradient
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: greenColor.opacity(0.45), location: 0.35),
                        .init(color: greenColor.opacity(0.9), location: 1.0),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: cardHeight * 0.45)
            }

            // Content overlay
            VStack {
                // Top bar: status + activity icon
                HStack {
                    StatusBadge(status: event.status)

                    Spacer()

                    Image(systemName: event.activityIcon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .padding(10)
                        .background(.white.opacity(0.12))
                        .clipShape(Circle())
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)

                Spacer()

                // Bottom: event info + interest button
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(event.activityType.capitalized)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white.opacity(0.65))
                            .textCase(.uppercase)
                            .tracking(1.5)

                        Text(event.title)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(2)

                        HStack(spacing: 14) {
                            Label(event.formattedDate, systemImage: "calendar")
                            Label("\(event.attendeesCount)/\(event.maxAttendees)", systemImage: "person.2")
                        }
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))

                        if !event.approximateArea.isEmpty || !event.region.isEmpty {
                            Label(
                                event.approximateArea.isEmpty ? event.region : event.approximateArea,
                                systemImage: "mappin"
                            )
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.65))
                        }
                    }

                    Spacer()

                    // Interest / heart button
                    interestButton
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
        .frame(width: cardWidth, height: cardHeight)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.35), radius: 12, y: 6)
    }

    // MARK: - Interest Button

    private var interestButton: some View {
        Button {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            onInterestTap?()
        } label: {
            VStack(spacing: 3) {
                Text("\(event.attendeesCount)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)

                Image(systemName: event.isInterested ? "heart.fill" : "heart")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(event.isInterested ? heartColor : .white.opacity(0.75))
                    .scaleEffect(event.isInterested ? 1.15 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.5), value: event.isInterested)
            }
            .padding(.leading, 8)
        }
        .buttonStyle(.plain)
    }

    private var placeholderBg: some View {
        Rectangle().fill(Color(hex: "1A2820"))
    }
}

// MARK: - Status Badge

struct StatusBadge: View {
    let status: VanEvent.EventStatus

    var body: some View {
        Text(status.rawValue.capitalized)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
            )
            .overlay(
                Capsule()
                    .stroke(statusColor.opacity(0.5), lineWidth: 1)
            )
    }

    var statusColor: Color {
        switch status {
        case .upcoming: return AppTheme.secondary
        case .ongoing: return AppTheme.accent
        case .completed: return AppTheme.textTertiary
        case .cancelled: return AppTheme.error
        }
    }
}
