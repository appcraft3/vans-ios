import SwiftUI

struct CreateEventView: View {
    @StateObject private var viewModel = CreateEventViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Title
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Event Title")
                                .font(.subheadline)
                                .foregroundColor(AppTheme.textSecondary)
                            TextField("e.g., Morning Hike Meetup", text: $viewModel.title)
                                .textFieldStyle(DarkTextFieldStyle())
                        }

                        // Description
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description")
                                .font(.subheadline)
                                .foregroundColor(AppTheme.textSecondary)
                            TextField("What's this event about?", text: $viewModel.description, axis: .vertical)
                                .lineLimit(3...6)
                                .textFieldStyle(DarkTextFieldStyle())
                        }

                        // Activity Type
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Activity Type")
                                .font(.subheadline)
                                .foregroundColor(AppTheme.textSecondary)
                            ActivityPicker(selected: $viewModel.activityType)
                        }

                        // Region
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Region")
                                .font(.subheadline)
                                .foregroundColor(AppTheme.textSecondary)
                            TextField("e.g., US West Coast", text: $viewModel.region)
                                .textFieldStyle(DarkTextFieldStyle())
                        }

                        // Approximate Area
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Approximate Area")
                                .font(.subheadline)
                                .foregroundColor(AppTheme.textSecondary)
                            TextField("e.g., Joshua Tree National Park", text: $viewModel.approximateArea)
                                .textFieldStyle(DarkTextFieldStyle())
                        }

                        // Date & Time
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Date & Time")
                                .font(.subheadline)
                                .foregroundColor(AppTheme.textSecondary)
                            DatePicker("", selection: $viewModel.date, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .tint(AppTheme.primary)
                                .colorScheme(.dark)
                        }

                        // End Date
                        VStack(alignment: .leading, spacing: 8) {
                            Text("End Time")
                                .font(.subheadline)
                                .foregroundColor(AppTheme.textSecondary)
                            DatePicker("", selection: $viewModel.endDate, in: viewModel.date..., displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .tint(AppTheme.primary)
                                .colorScheme(.dark)
                        }

                        // Max Attendees
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Max Attendees")
                                .font(.subheadline)
                                .foregroundColor(AppTheme.textSecondary)
                            Stepper("\(viewModel.maxAttendees) people", value: $viewModel.maxAttendees, in: 2...100)
                                .foregroundColor(AppTheme.textPrimary)
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(20)
                }

                // Bottom Button
                VStack {
                    Spacer()
                    Button {
                        Task {
                            let success = await viewModel.createEvent()
                            if success {
                                dismiss()
                            }
                        }
                    } label: {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .tint(.black)
                            } else {
                                Image(systemName: "plus.circle.fill")
                                Text("Create Event")
                            }
                        }
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.isValid ? AppTheme.accent : AppTheme.textTertiary)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(!viewModel.isValid || viewModel.isLoading)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
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
                    .foregroundColor(AppTheme.textPrimary)
                }
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
}

struct DarkTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(12)
            .background(AppTheme.card)
            .foregroundColor(AppTheme.textPrimary)
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct ActivityPicker: View {
    @Binding var selected: String

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
            HStack(spacing: 12) {
                ForEach(activities, id: \.0) { activity in
                    Button {
                        selected = activity.0
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: activity.2)
                                .font(.system(size: 20))
                            Text(activity.1)
                                .font(.caption)
                        }
                        .foregroundColor(selected == activity.0 ? .black : AppTheme.textPrimary)
                        .frame(width: 70, height: 60)
                        .background(selected == activity.0 ? AppTheme.accent : AppTheme.card)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
    }
}
