import SwiftUI

struct EventsListView: ActionableView {
    @ObservedObject var viewModel: EventsListViewModel
    @State private var showCreateEvent = false
    @State private var showLocationFilter = false

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Events")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.textPrimary)
                    Spacer()

                    if viewModel.canCreateEvents {
                        Button {
                            showCreateEvent = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(AppTheme.primary)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 8)

                // Location Filter
                Button {
                    showLocationFilter = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.subheadline)

                        if let location = viewModel.selectedLocation {
                            Text(location.name)
                                .font(.subheadline)
                                .lineLimit(1)

                            Button {
                                viewModel.clearLocationFilter()
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.textTertiary)
                            }
                        } else {
                            Text("All Locations")
                                .font(.subheadline)

                            Image(systemName: "chevron.down")
                                .font(.caption2)
                        }
                    }
                    .foregroundColor(viewModel.selectedLocation != nil ? AppTheme.primary : AppTheme.textSecondary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(viewModel.selectedLocation != nil ? AppTheme.primary.opacity(0.15) : AppTheme.card)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(viewModel.selectedLocation != nil ? AppTheme.primary.opacity(0.3) : AppTheme.divider, lineWidth: 1)
                    )
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 12)

                if viewModel.isLoading && viewModel.events.isEmpty {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.primary))
                        .scaleEffect(1.5)
                    Spacer()
                } else if viewModel.events.isEmpty {
                    Spacer()
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
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.events) { event in
                                EventCard(event: event) {
                                    viewModel.openEventDetail(event)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 120)
                    }
                    .refreshable {
                        await viewModel.refreshEvents()
                    }
                }
            }
            .frame(maxHeight: .infinity)
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
    }
}

struct EventCard: View {
    let event: VanEvent
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: event.activityIcon)
                        .font(.system(size: 24))
                        .foregroundColor(AppTheme.accent)
                        .frame(width: 44, height: 44)
                        .background(AppTheme.accentDark)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(event.title)
                            .font(.headline)
                            .foregroundColor(AppTheme.textPrimary)
                            .lineLimit(1)

                        Text(event.activityType.capitalized)
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                    }

                    Spacer()

                    StatusBadge(status: event.status)
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.caption)
                            .foregroundColor(AppTheme.textTertiary)
                        Text(event.formattedDate)
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textSecondary)
                    }

                    HStack(spacing: 6) {
                        Image(systemName: "mappin.circle")
                            .font(.caption)
                            .foregroundColor(AppTheme.textTertiary)
                        Text(event.approximateArea.isEmpty ? event.region : event.approximateArea)
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textSecondary)
                    }

                    HStack(spacing: 6) {
                        Image(systemName: "person.2")
                            .font(.caption)
                            .foregroundColor(AppTheme.textTertiary)
                        Text("\(event.attendeesCount)/\(event.maxAttendees) interested")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textSecondary)

                        if event.hasBuilder {
                            Spacer()
                            HStack(spacing: 4) {
                                Image(systemName: "wrench.and.screwdriver.fill")
                                    .font(.caption2)
                                Text("Builder")
                                    .font(.caption2)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(AppTheme.primary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppTheme.primary.opacity(0.2))
                            .cornerRadius(8)
                        }
                    }
                }

                if event.isInterested {
                    HStack {
                        Image(systemName: event.isAttending ? "checkmark.circle.fill" : "star.fill")
                            .foregroundColor(event.isAttending ? AppTheme.accent : AppTheme.primary)
                        Text(event.isAttending ? "Attending" : "Interested")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(event.isAttending ? AppTheme.accent : AppTheme.primary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background((event.isAttending ? AppTheme.accent : AppTheme.primary).opacity(0.2))
                    .clipShape(Capsule())
                }
            }
            .padding(16)
            .background(AppTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppTheme.divider, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

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
