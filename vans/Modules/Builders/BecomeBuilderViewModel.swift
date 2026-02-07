import Foundation
import FirebaseFunctions

@MainActor
final class BecomeBuilderViewModel: ObservableObject {
    @Published var selectedCategories: Set<BuilderCategory> = []
    @Published var bio: String = ""
    @Published var availability: String = ""

    @Published var isLoading = false
    @Published var isSubmitting = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var isAlreadyBuilder = false

    private let functions = Functions.functions()
    private weak var coordinator: BuildersCoordinating?

    init(coordinator: BuildersCoordinating?) {
        self.coordinator = coordinator
    }

    var canSubmit: Bool {
        !selectedCategories.isEmpty &&
        bio.count >= 20 &&
        !isSubmitting
    }

    var bioCharacterCount: String {
        "\(bio.count)/20 min"
    }

    func checkIfAlreadyBuilder() async {
        isLoading = true

        do {
            let result = try await functions.httpsCallable("getMyBuilderProfile").call([:])

            guard let data = result.data as? [String: Any],
                  let success = data["success"] as? Bool,
                  success else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to check status"])
            }

            isAlreadyBuilder = data["isBuilder"] as? Bool ?? false
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func toggleCategory(_ category: BuilderCategory) {
        if selectedCategories.contains(category) {
            selectedCategories.remove(category)
        } else {
            selectedCategories.insert(category)
        }
    }

    func submitApplication() async {
        guard canSubmit else { return }

        isSubmitting = true
        errorMessage = nil

        do {
            let params: [String: Any] = [
                "categories": selectedCategories.map { $0.rawValue },
                "bio": bio,
                "availability": availability.isEmpty ? "Contact for availability" : availability
            ]

            let result = try await functions.httpsCallable("becomeBuilder").call(params)

            guard let data = result.data as? [String: Any],
                  let success = data["success"] as? Bool,
                  success else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to submit application"])
            }

            successMessage = data["message"] as? String ?? "You are now a Trusted Builder!"
            isAlreadyBuilder = true

        } catch {
            errorMessage = error.localizedDescription
        }

        isSubmitting = false
    }

    func dismiss() {
        coordinator?.dismiss()
    }
}
