import SwiftUI
import PhotosUI

struct OnboardingView: ActionableView {

    @ObservedObject var viewModel: OnboardingViewModel
    @FocusState private var isTextFieldFocused: Bool
    private let accentGreen = Color(hex: "2E7D5A")

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                AppTheme.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Fixed header section
                        headerView

                        HStack(spacing: 4) {
                            ForEach(0..<OnboardingStep.allCases.count, id: \.self) { index in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(index <= viewModel.currentStep.rawValue ? accentGreen : Color.white.opacity(0.2))
                                    .frame(height: 3)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)

                        titleSection
                            .padding(.top, 24)

                        // Centered step content
                        VStack {
                            Spacer(minLength: 20)
                            stepContent
                                .padding(.horizontal, 24)
                            Spacer(minLength: 20)
                        }
                        .frame(minHeight: geometry.size.height - 280) // Space for header, title, and button
                    }
                }

                // Loading overlay
                if viewModel.isLoading {
                    Color.black.opacity(0.5).ignoresSafeArea()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: accentGreen))
                        .scaleEffect(1.5)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            bottomButton
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
                .background(AppTheme.background.opacity(0.95))
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            // Auto-focus text field on pages with text input
            if viewModel.currentStep == .fullName || viewModel.currentStep == .socialMedia {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isTextFieldFocused = true
                }
            }
        }
        .onChange(of: viewModel.currentStep) { newStep in
            // Auto-focus when navigating to text input pages
            if newStep == .fullName || newStep == .socialMedia {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isTextFieldFocused = true
                }
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            if viewModel.currentStep != .fullName {
                Button {
                    viewModel.previousStep()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
            } else {
                Color.clear.frame(width: 24)
            }

            Spacer()

            Text("Registration")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)

            Spacer()

            Color.clear.frame(width: 24)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    // MARK: - Title Section

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(viewModel.currentStep.title)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)

            Text(viewModel.currentStep.subtitle)
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.6))
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
    }

    // MARK: - Step Content

    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.currentStep {
        case .fullName:
            fullNameStepContent
        case .birthday:
            birthdayStepContent
        case .gender:
            genderStepContent
        case .languages:
            languagesStepContent
        case .socialMedia:
            socialMediaStepContent
        }
    }

    // MARK: - Full Name Step

    private var fullNameStepContent: some View {
        VStack(spacing: 24) {
            TextField("", text: $viewModel.fullName)
                .placeholder(when: viewModel.fullName.isEmpty, alignment: .leading) {
                    Text("Enter your full name")
                        .foregroundColor(.white.opacity(0.5))
                }
                .font(.system(size: 17))
                .foregroundColor(.white)
                .focused($isTextFieldFocused)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
                .textContentType(.name)
                .autocorrectionDisabled()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Birthday Step

    private var birthdayStepContent: some View {
        VStack(spacing: 24) {
            DatePicker(
                "",
                selection: $viewModel.birthday,
                in: ...Calendar.current.date(byAdding: .year, value: -18, to: Date())!,
                displayedComponents: .date
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .colorScheme(.dark)
            .tint(accentGreen)
            .frame(maxWidth: .infinity)

            if !viewModel.isAdult {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("You must be 18 or older to join")
                        .font(.system(size: 14))
                        .foregroundColor(.orange)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.orange.opacity(0.15))
                .cornerRadius(10)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Gender Step

    private var genderStepContent: some View {
        VStack(spacing: 12) {
            ForEach(Gender.allCases, id: \.self) { gender in
                Button {
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    viewModel.selectGender(gender)
                } label: {
                    HStack(spacing: 12) {
                        if !gender.icon.isEmpty {
                            Text(gender.icon)
                                .font(.system(size: 20))
                        }

                        Text(gender.displayName)
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(accentGreen)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(accentGreen.opacity(0.6))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(accentGreen.opacity(0.15))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(viewModel.selectedGender == gender ? accentGreen : Color.clear, lineWidth: 2)
                    )
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Languages Step

    private var languagesStepContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            FlowLayout(spacing: 10) {
                ForEach(Language.allLanguages) { language in
                    Button {
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred(intensity: 0.6)
                        viewModel.toggleLanguage(language.id)
                    } label: {
                        Text(language.name)
                            .font(.system(size: 15, weight: viewModel.selectedLanguages.contains(language.id) ? .semibold : .regular))
                            .foregroundColor(viewModel.selectedLanguages.contains(language.id) ? accentGreen : .white.opacity(0.7))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(viewModel.selectedLanguages.contains(language.id) ? accentGreen.opacity(0.2) : Color.white.opacity(0.08))
                            )
                            .overlay(
                                Capsule()
                                    .stroke(viewModel.selectedLanguages.contains(language.id) ? accentGreen.opacity(0.5) : Color.white.opacity(0.15), lineWidth: 1)
                            )
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Social Media Step

    private var socialMediaStepContent: some View {
        VStack(spacing: 20) {
            // Instagram
            HStack(spacing: 12) {
                Image("instagram_icon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
                    .cornerRadius(10)

                Text("@")
                    .foregroundColor(.white.opacity(0.5))

                TextField("", text: $viewModel.instagramUsername)
                    .placeholder(when: viewModel.instagramUsername.isEmpty, alignment: .leading) {
                        Text("Username")
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .focused($isTextFieldFocused)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )

        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Bottom Button

    private var bottomButton: some View {
        Group {
            if viewModel.currentStep == .socialMedia {
                // Social media step - Skip or Continue
                Button {
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    viewModel.skipSocialMedia()
                } label: {
                    Text(viewModel.instagramUsername.isEmpty ? "Skip for now" : "Continue")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(viewModel.instagramUsername.isEmpty ? accentGreen : .black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(viewModel.instagramUsername.isEmpty ? accentGreen.opacity(0.15) : accentGreen)
                        )
                }
            } else if viewModel.currentStep != .gender {
                // Other steps (except gender which auto-advances)
                Button {
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    viewModel.nextStep()
                } label: {
                    Text("Continue")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(viewModel.canProceed ? .black : .white.opacity(0.4))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(viewModel.canProceed ? accentGreen : Color.white.opacity(0.1))
                        )
                }
                .disabled(!viewModel.canProceed)
            }
        }
    }
}

// MARK: - Flow Layout for Language Tags

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return CGSize(width: proposal.width ?? 0, height: result.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            let point = result.positions[index]
            subview.place(at: CGPoint(x: bounds.minX + point.x, y: bounds.minY + point.y), proposal: .unspecified)
        }
    }

    struct FlowResult {
        var positions: [CGPoint] = []
        var height: CGFloat = 0

        init(in width: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if currentX + size.width > width && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }

                positions.append(CGPoint(x: currentX, y: currentY))
                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
            }

            height = currentY + lineHeight
        }
    }
}

// MARK: - Text Field Style

struct OnboardingTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(AppTheme.card)
            .cornerRadius(12)
            .foregroundColor(AppTheme.textPrimary)
    }
}

