import SwiftUI
import PhotosUI

struct CreateEventView: View {
    @StateObject private var viewModel = CreateEventViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showingLocationSearch = false

    private let accentGreen = Color(hex: "2E7D5A")

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                AppTheme.background.ignoresSafeArea()

                // Subtle top glow
                VStack {
                    RadialGradient(
                        colors: [accentGreen.opacity(0.08), Color.clear],
                        center: .top,
                        startRadius: 0,
                        endRadius: 400
                    )
                    .frame(height: 300)
                    .ignoresSafeArea()
                    Spacer()
                }

                VStack(spacing: 0) {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            // Photos Section
                            photosSection

                            // Event Details Card
                            eventDetailsCard

                            // Activity Type
                            activitySection

                            // Location Card
                            locationCard

                            // When Card
                            whenCard

                            // Settings Card
                            settingsCard

                            Spacer(minLength: 70)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                    }

                    // Bottom CTA
                    bottomButton
                }
            }
            .navigationTitle("New Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(AppTheme.background, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.textSecondary)
                }
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .sheet(isPresented: $showingLocationSearch) {
                LocationSearchView { location in
                    viewModel.selectedLocation = location
                }
            }
            .onChange(of: viewModel.selectedPhotos) { _ in
                Task {
                    await viewModel.loadImages()
                }
            }
        }
    }

    // MARK: - Photos

    private var photosSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(icon: "photo.on.rectangle.angled", title: "Photos")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    // Add button
                    if viewModel.selectedImages.count < 10 {
                        PhotosPicker(
                            selection: $viewModel.selectedPhotos,
                            maxSelectionCount: 10,
                            matching: .images
                        ) {
                            VStack(spacing: 8) {
                                ZStack {
                                    Circle()
                                        .fill(accentGreen.opacity(0.15))
                                        .frame(width: 40, height: 40)
                                    Image(systemName: "plus")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(accentGreen)
                                }
                                Text(viewModel.selectedImages.isEmpty ? "Add Photos" : "Add More")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(AppTheme.textSecondary)
                            }
                            .frame(width: 110, height: 110)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color.white.opacity(0.04))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(accentGreen.opacity(0.2), lineWidth: 1)
                            )
                        }
                    }

                    // Thumbnails
                    ForEach(Array(viewModel.selectedImages.enumerated()), id: \.offset) { index, image in
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 110, height: 110)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                                )

                            // First photo badge
                            if index == 0 {
                                Text("Cover")
                                    .font(.system(size: 9, weight: .bold))
                                    .textCase(.uppercase)
                                    .tracking(0.5)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(Capsule().fill(accentGreen))
                                    .padding(6)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                            }

                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    viewModel.removeImage(at: index)
                                }
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 22, height: 22)
                                    .background(Circle().fill(.ultraThinMaterial).environment(\.colorScheme, .dark))
                                    .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 1))
                            }
                            .padding(6)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: - Event Details Card

    private var eventDetailsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(icon: "pencil.line", title: "Details")

            VStack(spacing: 0) {
                // Title
                HStack(spacing: 12) {
                    Image(systemName: "textformat")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(accentGreen)
                        .frame(width: 20)

                    ZStack(alignment: .leading) {
                        if viewModel.title.isEmpty {
                            Text("Event title")
                                .font(.system(size: 15))
                                .foregroundColor(Color.white.opacity(0.35))
                        }
                        TextField("", text: $viewModel.title)
                            .font(.system(size: 15))
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 13)

                Divider().overlay(Color.white.opacity(0.06))

                // Description
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "text.alignleft")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(accentGreen)
                        .frame(width: 20)
                        .padding(.top, 2)

                    ZStack(alignment: .topLeading) {
                        if viewModel.description.isEmpty {
                            Text("What's this event about?")
                                .font(.system(size: 15))
                                .foregroundColor(Color.white.opacity(0.35))
                                .padding(.top, 0.5)
                        }
                        TextField("", text: $viewModel.description, axis: .vertical)
                            .lineLimit(2...5)
                            .font(.system(size: 15))
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 13)
            }
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
    }

    // MARK: - Activity Section

    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(icon: "figure.hiking", title: "Activity")

            ActivityPicker(selected: $viewModel.activityType)
        }
    }

    // MARK: - Location Card

    private var locationCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(icon: "mappin.and.ellipse", title: "Location")

            Button {
                showingLocationSearch = true
            } label: {
                HStack(spacing: 12) {
                    if let location = viewModel.selectedLocation {
                        ZStack {
                            Circle()
                                .fill(accentGreen.opacity(0.15))
                                .frame(width: 36, height: 36)
                            Image(systemName: location.icon)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(accentGreen)
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text(location.name)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.white)

                            Text(location.address)
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.textSecondary)
                                .lineLimit(1)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AppTheme.textTertiary)
                    } else {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.06))
                                .frame(width: 36, height: 36)
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppTheme.textTertiary)
                        }

                        Text("Search for a location...")
                            .font(.system(size: 15))
                            .foregroundColor(AppTheme.textTertiary)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AppTheme.textTertiary)
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(0.06))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(viewModel.selectedLocation != nil ? accentGreen.opacity(0.25) : Color.white.opacity(0.08), lineWidth: 1)
                )
            }
        }
    }

    // MARK: - When Card

    private var whenCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(icon: "clock", title: "When")

            VStack(spacing: 0) {
                // Start
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(accentGreen.opacity(0.15))
                            .frame(width: 32, height: 32)
                        Image(systemName: "play.fill")
                            .font(.system(size: 11))
                            .foregroundColor(accentGreen)
                    }

                    Text("Starts")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)

                    Spacer()

                    DatePicker("", selection: $viewModel.date, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .tint(accentGreen)
                        .colorScheme(.dark)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)

                Divider().overlay(Color.white.opacity(0.06))

                // End
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color(hex: "E8B86D").opacity(0.15))
                            .frame(width: 32, height: 32)
                        Image(systemName: "stop.fill")
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "E8B86D"))
                    }

                    Text("Ends")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)

                    Spacer()

                    DatePicker("", selection: $viewModel.endDate, in: viewModel.date..., displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .tint(accentGreen)
                        .colorScheme(.dark)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
            }
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
    }

    // MARK: - Settings Card

    private var settingsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(icon: "slider.horizontal.3", title: "Settings")

            VStack(spacing: 0) {
                // Max Attendees
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(accentGreen.opacity(0.15))
                            .frame(width: 32, height: 32)
                        Image(systemName: "person.2")
                            .font(.system(size: 12))
                            .foregroundColor(accentGreen)
                    }

                    Text("\(viewModel.maxAttendees)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 36)

                    Text("max people")
                        .font(.system(size: 13))
                        .foregroundColor(AppTheme.textSecondary)

                    Spacer()

                    Stepper("", value: $viewModel.maxAttendees, in: 2...100)
                        .labelsHidden()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)

                Divider().overlay(Color.white.opacity(0.06))

                // Check-in toggle
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(viewModel.allowCheckIn ? accentGreen.opacity(0.15) : Color.white.opacity(0.06))
                            .frame(width: 32, height: 32)
                        Image(systemName: viewModel.allowCheckIn ? "checkmark.circle.fill" : "star.fill")
                            .font(.system(size: 13))
                            .foregroundColor(viewModel.allowCheckIn ? accentGreen : Color(hex: "E8B86D"))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(viewModel.allowCheckIn ? "Check-in Event" : "Interest Only")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white)
                        Text(viewModel.allowCheckIn ? "Attendees verify with a code on arrival" : "People mark interest, no check-in needed")
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.textSecondary)
                    }

                    Spacer()

                    Toggle("", isOn: $viewModel.allowCheckIn)
                        .labelsHidden()
                        .tint(accentGreen)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
            }
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
    }

    // MARK: - Bottom Button

    private var bottomButton: some View {
        VStack(spacing: 0) {
            LinearGradient(
                stops: [
                    .init(color: AppTheme.background.opacity(0), location: 0),
                    .init(color: AppTheme.background.opacity(0.85), location: 0.35),
                    .init(color: AppTheme.background, location: 1.0),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 28)

            Button {
                Task {
                    let success = await viewModel.createEvent()
                    if success {
                        dismiss()
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.black)
                        if let progress = viewModel.uploadProgress {
                            Text(progress)
                                .font(.system(size: 14, weight: .medium))
                        }
                    } else {
                        Image(systemName: "sparkles")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Create Event")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
                .foregroundColor(viewModel.isValid ? .black : AppTheme.textTertiary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    Group {
                        if viewModel.isValid {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [accentGreen, accentGreen.opacity(0.85)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        } else {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.white.opacity(0.06))
                        }
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(
                            viewModel.isValid ? accentGreen.opacity(0.5) : Color.white.opacity(0.06),
                            lineWidth: 1
                        )
                )
                .shadow(color: viewModel.isValid ? accentGreen.opacity(0.25) : .clear, radius: 16, y: 6)
            }
            .disabled(!viewModel.isValid || viewModel.isLoading)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            .background(AppTheme.background)
        }
    }

    // MARK: - Section Header

    private func sectionHeader(icon: String, title: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(accentGreen)
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(AppTheme.textSecondary)
                .textCase(.uppercase)
                .tracking(1.0)
        }
    }
}

// MARK: - Activity Picker

struct ActivityPicker: View {
    @Binding var selected: String

    private let accentGreen = Color(hex: "2E7D5A")

    let activities = [
        ("hiking", "Hiking", "figure.hiking"),
        ("surfing", "Surfing", "figure.surfing"),
        ("climbing", "Climbing", "figure.climbing"),
        ("cycling", "Cycling", "figure.outdoor.cycle"),
        ("kayaking", "Kayaking", "figure.rowing"),
        ("photography", "Photography", "camera"),
        ("yoga", "Yoga", "figure.yoga"),
        ("cooking", "Cooking", "fork.knife"),
        ("stargazing", "Stargazing", "star"),
        ("remote_work", "Coworking", "laptopcomputer"),
    ]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(activities, id: \.0) { activity in
                    let isSelected = selected == activity.0
                    Button {
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred(intensity: 0.5)
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selected = activity.0
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: activity.2)
                                .font(.system(size: 13, weight: .medium))
                            Text(activity.1)
                                .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                        }
                        .foregroundColor(isSelected ? .white : AppTheme.textSecondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(
                            Capsule()
                                .fill(isSelected ? accentGreen.opacity(0.25) : Color.white.opacity(0.04))
                        )
                        .overlay(
                            Capsule()
                                .stroke(isSelected ? accentGreen.opacity(0.5) : Color.white.opacity(0.06), lineWidth: 1)
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Styles

struct DarkTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(12)
            .background(Color.white.opacity(0.06))
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
    }
}
