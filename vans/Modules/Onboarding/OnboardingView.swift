import SwiftUI
import PhotosUI

struct OnboardingView: ActionableView {

    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress bar
                ProgressView(value: viewModel.progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: AppTheme.accent))
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                // Step indicator
                Text("Step \(viewModel.currentStep.rawValue + 1) of \(OnboardingStep.allCases.count)")
                    .font(.caption)
                    .foregroundColor(AppTheme.textTertiary)
                    .padding(.top, 8)

                // Content
                ScrollView {
                    VStack(spacing: 24) {
                        // Title
                        VStack(spacing: 8) {
                            Text(viewModel.currentStep.title)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(AppTheme.textPrimary)

                            Text(viewModel.currentStep.subtitle)
                                .font(.body)
                                .foregroundColor(AppTheme.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 32)

                        // Step content
                        stepContent
                            .padding(.horizontal, 24)
                    }
                }

                // Navigation buttons
                HStack(spacing: 16) {
                    if viewModel.currentStep != .photo {
                        Button(action: { viewModel.previousStep() }) {
                            Text("Back")
                                .font(.headline)
                                .foregroundColor(AppTheme.textPrimary)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(AppTheme.card)
                                .cornerRadius(12)
                        }
                    }

                    Button(action: { viewModel.nextStep() }) {
                        Text(viewModel.isLastStep ? "Submit" : "Continue")
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(viewModel.canProceed ? AppTheme.accent : AppTheme.textTertiary)
                            .cornerRadius(12)
                    }
                    .disabled(!viewModel.canProceed)
                }
                .padding(24)
            }

            if viewModel.isLoading {
                AppTheme.background.opacity(0.8).ignoresSafeArea()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.primary))
                    .scaleEffect(1.5)
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
        .onAppear {
            viewModel.loadSetupData()
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.currentStep {
        case .photo:
            photoStepContent
        case .basicInfo:
            basicInfoStepContent
        case .vanLifeStatus:
            vanLifeStatusStepContent
        case .region:
            regionStepContent
        case .activities:
            activitiesStepContent
        case .bio:
            bioStepContent
        }
    }

    private var photoStepContent: some View {
        VStack(spacing: 24) {
            PhotosPicker(selection: $viewModel.selectedPhotoItem, matching: .images) {
                if let image = viewModel.photoImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 200, height: 200)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(AppTheme.primary, lineWidth: 3))
                } else {
                    ZStack {
                        Circle()
                            .fill(AppTheme.card)
                            .frame(width: 200, height: 200)

                        VStack(spacing: 8) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 40))
                            Text("Add Photo")
                                .font(.headline)
                        }
                        .foregroundColor(AppTheme.textPrimary)
                    }
                }
            }

            Text("Choose a photo that clearly shows your face")
                .font(.caption)
                .foregroundColor(AppTheme.textSecondary)
        }
        .padding(.top, 40)
    }

    private var basicInfoStepContent: some View {
        VStack(spacing: 20) {
            // First name
            VStack(alignment: .leading, spacing: 8) {
                Text("First Name")
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)

                TextField("", text: $viewModel.firstName)
                    .textFieldStyle(OnboardingTextFieldStyle())
                    .textContentType(.givenName)
            }

            // Age
            VStack(alignment: .leading, spacing: 8) {
                Text("Age (must be 18+)")
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)

                TextField("", text: $viewModel.age)
                    .textFieldStyle(OnboardingTextFieldStyle())
                    .keyboardType(.numberPad)
            }

            // Gender
            VStack(alignment: .leading, spacing: 8) {
                Text("Gender")
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)

                HStack(spacing: 12) {
                    ForEach(Gender.allCases, id: \.self) { gender in
                        Button(action: { viewModel.selectedGender = gender }) {
                            Text(gender.displayName)
                                .font(.subheadline)
                                .foregroundColor(viewModel.selectedGender == gender ? .black : AppTheme.textPrimary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(viewModel.selectedGender == gender ? AppTheme.accent : AppTheme.card)
                                .cornerRadius(8)
                        }
                    }
                }
            }
        }
    }

    private var vanLifeStatusStepContent: some View {
        VStack(spacing: 16) {
            ForEach(VanLifeStatus.allCases, id: \.self) { status in
                Button(action: { viewModel.selectedVanLifeStatus = status }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(status.displayName)
                                .font(.headline)
                                .foregroundColor(AppTheme.textPrimary)

                            Text(statusDescription(for: status))
                                .font(.caption)
                                .foregroundColor(AppTheme.textSecondary)
                        }

                        Spacer()

                        if viewModel.selectedVanLifeStatus == status {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(AppTheme.accent)
                        }
                    }
                    .padding()
                    .background(viewModel.selectedVanLifeStatus == status ? AppTheme.accentDark : AppTheme.card)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(viewModel.selectedVanLifeStatus == status ? AppTheme.accent : Color.clear, lineWidth: 1)
                    )
                }
            }
        }
    }

    private func statusDescription(for status: VanLifeStatus) -> String {
        switch status {
        case .fullTime: return "Living in my van full-time"
        case .partTime: return "Part-time van life, part-time home"
        case .planning: return "Planning to start van life soon"
        }
    }

    private var regionStepContent: some View {
        VStack(spacing: 12) {
            if viewModel.regions.isEmpty {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.primary))
            } else {
                ForEach(viewModel.regions) { region in
                    Button(action: { viewModel.selectedRegion = region }) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(region.name)
                                    .font(.headline)
                                    .foregroundColor(AppTheme.textPrimary)
                                Text(region.country)
                                    .font(.caption)
                                    .foregroundColor(AppTheme.textSecondary)
                            }

                            Spacer()

                            if viewModel.selectedRegion?.id == region.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(AppTheme.accent)
                            }
                        }
                        .padding()
                        .background(viewModel.selectedRegion?.id == region.id ? AppTheme.accentDark : AppTheme.card)
                        .cornerRadius(12)
                    }
                }
            }
        }
    }

    private var activitiesStepContent: some View {
        VStack(spacing: 16) {
            Text("Select up to 5 activities")
                .font(.caption)
                .foregroundColor(AppTheme.textSecondary)

            if viewModel.activities.isEmpty {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.primary))
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
                    ForEach(viewModel.activities) { activity in
                        Button(action: { viewModel.toggleActivity(activity.id) }) {
                            VStack(spacing: 8) {
                                Image(systemName: activity.icon)
                                    .font(.title2)
                                Text(activity.name)
                                    .font(.caption)
                            }
                            .foregroundColor(viewModel.selectedActivities.contains(activity.id) ? .black : AppTheme.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(viewModel.selectedActivities.contains(activity.id) ? AppTheme.accent : AppTheme.card)
                            .cornerRadius(12)
                        }
                    }
                }
            }

            Text("\(viewModel.selectedActivities.count)/5 selected")
                .font(.caption)
                .foregroundColor(AppTheme.textSecondary)
        }
    }

    private var bioStepContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Bio (optional)")
                .font(.caption)
                .foregroundColor(AppTheme.textSecondary)

            TextEditor(text: $viewModel.bio)
                .frame(height: 150)
                .padding(12)
                .background(AppTheme.card)
                .cornerRadius(12)
                .foregroundColor(AppTheme.textPrimary)
                .scrollContentBackground(.hidden)

            Text("\(viewModel.bio.count)/300")
                .font(.caption)
                .foregroundColor(AppTheme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
}

struct OnboardingTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(AppTheme.card)
            .cornerRadius(12)
            .foregroundColor(AppTheme.textPrimary)
    }
}
