import Foundation
import Combine
import SwiftUI
import PhotosUI

enum OnboardingStep: Int, CaseIterable {
    case fullName = 0
    case birthday = 1
    case gender = 2
    case languages = 3
    case socialMedia = 4

    var title: String {
        switch self {
        case .fullName: return "My full name..."
        case .birthday: return "When's your birthday?"
        case .gender: return "How do you identify?"
        case .languages: return "I speak these languages..."
        case .socialMedia: return "Social media account"
        }
    }

    var subtitle: String {
        switch self {
        case .fullName: return "This is how you will appear on the app"
        case .birthday: return "We need to verify that you are over 18. This helps us find events with like-minded people for you."
        case .gender: return "This info will help you access gender-specific events and create a safe space"
        case .languages: return "This will help you see events only in the languages you speak"
        case .socialMedia: return "Let people know more about you"
        }
    }
}

final class OnboardingViewModel: ActionableViewModel {

    @Published var currentStep: OnboardingStep = .fullName
    @Published var isLoading: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""

    // Full name step
    @Published var fullName: String = ""

    // Birthday step
    @Published var birthday: Date = Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date()

    // Gender step
    @Published var selectedGender: Gender?

    // Languages step
    @Published var selectedLanguages: Set<String> = []

    // Social media step
    @Published var instagramUsername: String = ""
    @Published var linkedinUrl: String = ""

    // Keep these for later steps (after waitlist)
    @Published var selectedVanLifeStatus: VanLifeStatus?
    @Published var regions: [Region] = []
    @Published var selectedRegion: Region?
    @Published var activities: [Activity] = []
    @Published var selectedActivities: Set<String> = []
    @Published var bio: String = ""
    @Published var photoUrl: String = ""
    @Published var photoImage: UIImage?
    @Published var selectedPhotoItem: PhotosPickerItem?

    private weak var coordinator: OnboardingCoordinating?
    private var cancellables = Set<AnyCancellable>()

    var progress: Double {
        Double(currentStep.rawValue + 1) / Double(OnboardingStep.allCases.count)
    }

    var calculatedAge: Int {
        let calendar = Calendar.current
        let now = Date()
        let ageComponents = calendar.dateComponents([.year], from: birthday, to: now)
        return ageComponents.year ?? 0
    }

    var isAdult: Bool {
        calculatedAge >= 18
    }

    var canProceed: Bool {
        switch currentStep {
        case .fullName:
            return !fullName.trimmingCharacters(in: .whitespaces).isEmpty
        case .birthday:
            return isAdult
        case .gender:
            return selectedGender != nil
        case .languages:
            return !selectedLanguages.isEmpty
        case .socialMedia:
            return true // Optional step
        }
    }

    var isLastStep: Bool {
        currentStep == .socialMedia
    }

    init(coordinator: OnboardingCoordinating?) {
        self.coordinator = coordinator
        setupPhotoObserver()
    }

    private func setupPhotoObserver() {
        $selectedPhotoItem
            .compactMap { $0 }
            .sink { [weak self] item in
                Task {
                    await self?.loadPhoto(from: item)
                }
            }
            .store(in: &cancellables)
    }

    @MainActor
    private func loadPhoto(from item: PhotosPickerItem) async {
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                self.photoImage = image
                self.photoUrl = "photo_selected"
            }
        } catch {
            showError(message: "Failed to load photo")
        }
    }

    func loadSetupData() {
        Task { @MainActor in
            isLoading = true
            do {
                let data = try await AuthManager.shared.getProfileSetupData()
                self.activities = data.activities
                self.regions = data.regions
            } catch {
                // Don't show error for now, data will be loaded later
            }
            isLoading = false
        }
    }

    func nextStep() {
        guard canProceed else { return }

        if isLastStep {
            submitProfile()
        } else if let nextStep = OnboardingStep(rawValue: currentStep.rawValue + 1) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                currentStep = nextStep
            }
        }
    }

    func previousStep() {
        if let prevStep = OnboardingStep(rawValue: currentStep.rawValue - 1) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                currentStep = prevStep
            }
        }
    }

    func selectGender(_ gender: Gender) {
        selectedGender = gender
        // Auto-advance after selection
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.nextStep()
        }
    }

    func toggleLanguage(_ languageId: String) {
        if selectedLanguages.contains(languageId) {
            selectedLanguages.remove(languageId)
        } else {
            selectedLanguages.insert(languageId)
        }
    }

    func toggleActivity(_ activityId: String) {
        if selectedActivities.contains(activityId) {
            selectedActivities.remove(activityId)
        } else if selectedActivities.count < 5 {
            selectedActivities.insert(activityId)
        }
    }

    func skipSocialMedia() {
        submitProfile()
    }

    private func submitProfile() {
        guard let gender = selectedGender else {
            showError(message: "Please complete all required fields")
            return
        }

        Task { @MainActor in
            isLoading = true
            do {
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withFullDate]
                let birthdayString = formatter.string(from: birthday)

                // Extract first name from full name
                let firstName = fullName.trimmingCharacters(in: .whitespaces).components(separatedBy: " ").first ?? fullName

                _ = try await AuthManager.shared.submitProfile(
                    firstName: firstName,
                    photoUrl: "https://placeholder.com/avatar.jpg", // Will be set later
                    age: calculatedAge,
                    gender: gender,
                    vanLifeStatus: .planning, // Default, will be set later
                    region: "global", // Default, will be set later
                    activities: [], // Will be set later
                    bio: nil,
                    birthday: birthdayString,
                    languages: Array(selectedLanguages),
                    instagramUsername: instagramUsername.isEmpty ? nil : instagramUsername.trimmingCharacters(in: .whitespaces),
                    linkedinUrl: linkedinUrl.isEmpty ? nil : linkedinUrl.trimmingCharacters(in: .whitespaces)
                )

                coordinator?.finishOnboarding()
            } catch {
                showError(message: error.localizedDescription)
            }
            isLoading = false
        }
    }

    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
}
