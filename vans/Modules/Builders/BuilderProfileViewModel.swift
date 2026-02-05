import Foundation
import FirebaseFunctions

@MainActor
final class BuilderProfileViewModel: ObservableObject {
    @Published var builder: BuilderProfile
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let functions = Functions.functions()
    private weak var coordinator: BuildersCoordinating?

    init(builder: BuilderProfile, coordinator: BuildersCoordinating?) {
        self.builder = builder
        self.coordinator = coordinator
    }

    func bookSession(category: BuilderCategory? = nil) {
        coordinator?.showBookSession(builder: builder, category: category, sourceEventId: nil)
    }

    func dismiss() {
        coordinator?.dismiss()
    }
}
