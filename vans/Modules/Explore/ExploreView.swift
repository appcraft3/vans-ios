import SwiftUI
import MapKit

struct ExploreView: ActionableView {
    @ObservedObject var viewModel: ExploreViewModel

    private let accentGreen = Color(hex: "2E7D5A")

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar
                storiesSection
                searchFilterBar
                mapSection
            }
        }
        .navigationBarHidden(true)
        .task {
            viewModel.requestLocationPermission()
            await viewModel.loadEvents()
        }
        .sheet(isPresented: $viewModel.showEventDetailSheet) {
            if let event = viewModel.detailEvent {
                EventPreviewSheet(event: event) {
                    viewModel.openEventDetail(event)
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
        .sheet(isPresented: $viewModel.showLocationSearch) {
            LocationSearchView { location in
                viewModel.moveMapTo(location.coordinate)
            }
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack {
            Text("Explore")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(AppTheme.textPrimary)

            Spacer()

            if viewModel.isLoading {
                ProgressView()
                    .tint(accentGreen)
                    .scaleEffect(0.8)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 4)
    }

    // MARK: - Stories (placeholder)

    private var storiesSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(0..<6, id: \.self) { _ in
                    VStack(spacing: 6) {
                        Circle()
                            .fill(Color.white.opacity(0.06))
                            .frame(width: 56, height: 56)
                            .overlay(
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            colors: [accentGreen, accentGreen.opacity(0.3)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 2
                                    )
                            )

                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white.opacity(0.08))
                            .frame(width: 36, height: 6)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Search + Filter

    private var searchFilterBar: some View {
        VStack(spacing: 8) {
            // Search bar
            Button {
                viewModel.showLocationSearch = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.textTertiary)
                    Text("Search location...")
                        .font(.system(size: 15))
                        .foregroundColor(AppTheme.textTertiary)
                    Spacer()
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
            .padding(.horizontal, 16)

            // Activity filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(viewModel.activityTypes, id: \.key) { type in
                        let isActive = viewModel.selectedActivityFilter == type.key

                        Button {
                            let impact = UIImpactFeedbackGenerator(style: .light)
                            impact.impactOccurred(intensity: 0.6)
                            viewModel.toggleActivityFilter(type.key)
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: type.icon)
                                    .font(.system(size: 11))
                                Text(type.label)
                                    .font(.system(size: 13, weight: isActive ? .semibold : .regular))
                            }
                            .foregroundColor(isActive ? accentGreen : AppTheme.textSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(
                                Capsule()
                                    .fill(isActive ? accentGreen.opacity(0.12) : Color.clear)
                            )
                            .overlay(
                                Capsule()
                                    .stroke(
                                        isActive ? accentGreen.opacity(0.3) : Color.white.opacity(0.08),
                                        lineWidth: 1
                                    )
                            )
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.bottom, 8)
    }

    // MARK: - Map

    private var mapSection: some View {
        ZStack {
            DarkMapView(
                annotations: viewModel.annotations,
                region: $viewModel.mapRegion,
                selectedAnnotation: $viewModel.selectedAnnotation,
                onAnnotationTap: { annotation in
                    viewModel.selectAnnotation(annotation)
                }
            )
            .ignoresSafeArea(edges: .bottom)

            // Recenter button (top-right)
            VStack {
                HStack {
                    Spacer()

                    Button {
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                        viewModel.centerOnUserLocation()
                    } label: {
                        Image(systemName: "location.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(accentGreen)
                            .padding(10)
                            .background(
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .environment(\.colorScheme, .dark)
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
                            )
                    }
                    .padding(.trailing, 16)
                    .padding(.top, 12)
                }

                Spacer()
            }

            // Preview card (bottom)
            VStack {
                Spacer()

                if let event = viewModel.previewEvent {
                    EventPreviewCard(
                        event: event,
                        onTap: {
                            viewModel.showFullDetail(for: event)
                        },
                        onDismiss: {
                            viewModel.dismissPreview()
                        }
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 100)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: viewModel.previewEvent?.id)
        }
    }
}
