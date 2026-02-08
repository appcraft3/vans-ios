import SwiftUI
import MapKit
import PhotosUI

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
            await viewModel.loadStories()
        }
        .onAppear {
            viewModel.startStoryRefreshTimer()
        }
        .onDisappear {
            viewModel.stopStoryRefreshTimer()
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
        .fullScreenCover(isPresented: $viewModel.showStoryViewer) {
            if let story = viewModel.selectedStory {
                StoryViewerView(story: story)
            }
        }
        .alert("Error", isPresented: .constant(viewModel.storyPostError != nil)) {
            Button("OK") { viewModel.storyPostError = nil }
        } message: {
            Text(viewModel.storyPostError ?? "")
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
        .padding(.top, 20)
        .padding(.bottom, 10)
    }

    // MARK: - Stories

    private var storiesSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                addStoryButton

                ForEach(viewModel.stories) { story in
                    storyBubble(story)
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 12)
    }

    private var addStoryButton: some View {
        PhotosPicker(selection: $viewModel.selectedStoryPhotoItem, matching: .images) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.06))
                        .frame(width: 56, height: 56)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.15), lineWidth: 1.5)
                        )

                    if viewModel.isPostingStory {
                        ProgressView()
                            .tint(accentGreen)
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(accentGreen)
                    }
                }

                Text(viewModel.hasOwnStory ? "Update" : "Add")
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
        .disabled(viewModel.isPostingStory)
    }

    private func storyBubble(_ story: Story) -> some View {
        Button {
            viewModel.viewStory(story)
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    StoryProgressRing(freshness: story.freshness)
                        .frame(width: 58, height: 58)

                    CachedProfileImage(url: story.user.photoUrl, size: 50)
                }

                Text(story.user.firstName)
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.textSecondary)
                    .lineLimit(1)
                    .frame(width: 56)
            }
            .padding(.top, 2)
        }
    }

    // MARK: - Search + Filter

    private var searchFilterBar: some View {
        VStack(spacing: 10) {
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
                    // "All" chip
                    let allActive = viewModel.selectedActivityFilter == nil

                    Button {
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred(intensity: 0.6)
                        viewModel.clearActivityFilter()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "square.grid.2x2")
                                .font(.system(size: 11))
                            Text("All")
                                .font(.system(size: 13, weight: allActive ? .semibold : .regular))
                        }
                        .foregroundColor(allActive ? accentGreen : AppTheme.textSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(
                            Capsule()
                                .fill(allActive ? accentGreen.opacity(0.12) : Color.clear)
                        )
                        .overlay(
                            Capsule()
                                .stroke(
                                    allActive ? accentGreen.opacity(0.3) : Color.white.opacity(0.08),
                                    lineWidth: 1
                                )
                        )
                    }

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
        .padding(.bottom, 10)
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
