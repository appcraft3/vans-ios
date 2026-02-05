import Foundation
import Combine
import SwiftUI
import PhotosUI

enum OnboardingStep: Int, CaseIterable {
    case photo = 0
    case basicInfo = 1
    case vanLifeStatus = 2
    case region = 3
    case activities = 4
    case bio = 5

    var title: String {
        switch self {
        case .photo: return "Add a Photo"
        case .basicInfo: return "About You"
        case .vanLifeStatus: return "Van Life Journey"
        case .region: return "Your Region"
        case .activities: return "Your Interests"
        case .bio: return "Your Story"
        }
    }

    var subtitle: String {
        switch self {
        case .photo: return "Show the community who you are"
        case .basicInfo: return "Let's get to know you"
        case .vanLifeStatus: return "Where are you in your journey?"
        case .region: return "Where do you roam?"
        case .activities: return "What do you love doing?"
        case .bio: return "Share a bit about yourself"
        }
    }
}

final class OnboardingViewModel: ActionableViewModel {

    @Published var currentStep: OnboardingStep = .photo
    @Published var isLoading: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""

    // Photo step
    @Published var selectedPhotoItem: PhotosPickerItem?
    @Published var photoUrl: String = ""
    @Published var photoImage: UIImage?

    // Basic info step
    @Published var firstName: String = ""
    @Published var age: String = ""
    @Published var selectedGender: Gender?

    // Van life status step
    @Published var selectedVanLifeStatus: VanLifeStatus?

    // Region step
    @Published var regions: [Region] = []
    @Published var selectedRegion: Region?

    // Activities step
    @Published var activities: [Activity] = []
    @Published var selectedActivities: Set<String> = []

    // Bio step
    @Published var bio: String = ""

    private weak var coordinator: OnboardingCoordinating?
    private var cancellables = Set<AnyCancellable>()

    var progress: Double {
        Double(currentStep.rawValue + 1) / Double(OnboardingStep.allCases.count)
    }

    var canProceed: Bool {
        switch currentStep {
        case .photo:
            return photoImage != nil || !photoUrl.isEmpty
        case .basicInfo:
            return !firstName.trimmingCharacters(in: .whitespaces).isEmpty &&
                   (Int(age) ?? 0) >= 18 &&
                   selectedGender != nil
        case .vanLifeStatus:
            return selectedVanLifeStatus != nil
        case .region:
            return selectedRegion != nil
        case .activities:
            return !selectedActivities.isEmpty && selectedActivities.count <= 5
        case .bio:
            return true // Bio is optional
        }
    }

    var isLastStep: Bool {
        currentStep == .bio
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
                // TODO: Upload to Firebase Storage and get URL
                // For now, we'll use a placeholder
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
                showError(message: "Failed to load setup data")
            }
            isLoading = false
        }
    }

    func nextStep() {
        guard canProceed else { return }

        if isLastStep {
            submitProfile()
        } else if let nextStep = OnboardingStep(rawValue: currentStep.rawValue + 1) {
            withAnimation {
                currentStep = nextStep
            }
        }
    }

    func previousStep() {
        if let prevStep = OnboardingStep(rawValue: currentStep.rawValue - 1) {
            withAnimation {
                currentStep = prevStep
            }
        }
    }

    func toggleActivity(_ activityId: String) {
        if selectedActivities.contains(activityId) {
            selectedActivities.remove(activityId)
        } else if selectedActivities.count < 5 {
            selectedActivities.insert(activityId)
        }
    }

    private func submitProfile() {
        guard let gender = selectedGender,
              let vanLifeStatus = selectedVanLifeStatus,
              let region = selectedRegion,
              let ageInt = Int(age) else {
            showError(message: "Please complete all required fields")
            return
        }

        Task { @MainActor in
            isLoading = true
            do {
                // TODO: Upload photo to Firebase Storage first
                let uploadedPhotoUrl = photoUrl.isEmpty ? "https://placeholder.com/avatar.jpg" : photoUrl

                _ = try await AuthManager.shared.submitProfile(
                    firstName: firstName.trimmingCharacters(in: .whitespaces),
                    photoUrl: uploadedPhotoUrl,
                    age: ageInt,
                    gender: gender,
                    vanLifeStatus: vanLifeStatus,
                    region: region.id,
                    activities: Array(selectedActivities),
                    bio: bio.isEmpty ? nil : bio.trimmingCharacters(in: .whitespacesAndNewlines)
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
