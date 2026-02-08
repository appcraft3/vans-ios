import SwiftUI

struct EventsListView: ActionableView {
    @ObservedObject var viewModel: EventsListViewModel
    @State private var showCreateEvent = false
    @State private var showLocationFilter = false
    @State private var currentIndex = 0
    @State private var dragOffset: CGFloat = 0

    private let accentGreen = Color(hex: "2E7D5A") // accentPrimary

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar

                if viewModel.isLoading && viewModel.events.isEmpty {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: accentGreen))
                        .scaleEffect(1.5)
                    Spacer()
                } else if viewModel.events.isEmpty {
                    Spacer()
                    emptyState
                    Spacer()
                } else if currentIndex >= viewModel.events.count {
                    Spacer()
                    allSeenState
                    Spacer()
                } else {
                    // Card counter
                    Text("\(currentIndex + 1) of \(viewModel.events.count)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppTheme.textTertiary)
                        .padding(.bottom, 10)

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
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack {
            Text("Events")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(AppTheme.textPrimary)

            Spacer()

            Button {
                showLocationFilter = true
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: viewModel.selectedLocation != nil ? "mappin.circle.fill" : "mappin")
                        .font(.subheadline)
                    if let location = viewModel.selectedLocation {
                        Text(location.name)
                            .font(.caption)
                            .lineLimit(1)
                        Button {
                            viewModel.clearLocationFilter()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption2)
                        }
                    }
                }
                .foregroundColor(viewModel.selectedLocation != nil ? accentGreen : AppTheme.textSecondary)
            }

            if viewModel.canCreateEvents {
                Button {
                    showCreateEvent = true
                } label: {
                    Image(systemName: "plus")
                        .font(.title3.weight(.medium))
                        .foregroundColor(AppTheme.textPrimary)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
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
            let cardH = geo.size.height
            let dragProgress = min(1.0, max(0, -dragOffset / (cardH * 0.25)))

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
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 86)
    }

    @ViewBuilder
    private func stackedCard(
        event: VanEvent,
        stackPos: Int,
        dragProgress: CGFloat,
        cardW: CGFloat,
        cardH: CGFloat
    ) -> some View {
        // Back cards peek from the TOP of the front card
        let scaleDrop: CGFloat = 0.04
        let peekPerCard: CGFloat = 8.0

        let scale = 1.0 - CGFloat(stackPos) * scaleDrop
        let peek = peekPerCard * CGFloat(stackPos)

        // Offset so the back card's top edge sits `peek` pt above the front card's top
        // With center-anchored scaleEffect: visual top = center_y - (cardH * scale / 2)
        // We want: back_visual_top = front_top - peek = -cardH/2 - peek
        // So: restingY - cardH * scale / 2 = -cardH/2 - peek
        // restingY = -cardH/2 - peek + cardH * scale / 2 = -(cardH * (1 - scale) / 2 + peek)
        let restingY = -(cardH * (1.0 - scale) / 2.0 + peek)

        let baseOpacity: Double = stackPos == 0 ? 1.0 : stackPos == 1 ? 0.6 : 0.3

        // During drag, interpolate behind cards toward front position
        let lerp: CGFloat = stackPos == 1 ? dragProgress * 0.45 : dragProgress * 0.15

        let yOff = stackPos == 0 ? dragOffset : restingY * (1.0 - lerp)
        let scl = stackPos == 0 ? 1.0 : scale + (1.0 - scale) * lerp
        let opa = stackPos == 0 ? 1.0 : baseOpacity + (1.0 - baseOpacity) * lerp

        EventSwipeCard(
            event: event,
            cardWidth: cardW,
            cardHeight: cardH,
            greenColor: accentGreen
        )
        .scaleEffect(scl)
        .offset(y: yOff)
        .opacity(opa)
    }

    private var visibleCards: [EnumeratedSequence<[VanEvent]>.Element] {
        Array(viewModel.events.enumerated())
            .filter { $0.offset >= currentIndex && $0.offset < currentIndex + 3 }
    }

    // MARK: - Swipe Gesture

    private func swipeGesture(cardHeight: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 15)
            .onChanged { value in
                if value.translation.height < 0 {
                    dragOffset = value.translation.height
                } else {
                    dragOffset = value.translation.height * 0.2 // resist downward
                }
            }
            .onEnded { value in
                let threshold = -cardHeight * 0.22
                let shouldDismiss = value.translation.height < threshold
                    || value.predictedEndTranslation.height < -cardHeight * 0.5

                if shouldDismiss {
                    // Fly card off the top
                    withAnimation(.easeOut(duration: 0.28)) {
                        dragOffset = -cardHeight * 1.5
                    }
                    // Bring next card forward
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                        dragOffset = 0
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                            currentIndex += 1
                        }
                    }
                } else {
                    // Snap back
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

    var body: some View {
        ZStack {
            // Background image
            // TODO: Replace with real event images from backend
            AsyncImage(url: URL(string: "https://picsum.photos/seed/\(event.id)/600/900")) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    placeholderBg
                case .empty:
                    placeholderBg
                        .overlay(ProgressView().tint(.white.opacity(0.25)))
                @unknown default:
                    placeholderBg
                }
            }
            .frame(width: cardWidth, height: cardHeight)

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

                // Bottom: event info
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
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(width: cardWidth, height: cardHeight)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.35), radius: 12, y: 6)
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
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundColor(statusColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.2))
            .clipShape(Capsule())
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
