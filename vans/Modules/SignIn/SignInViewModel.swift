import Foundation
import UIKit

final class SignInViewModel: ActionableViewModel {

    @Published var isLoading: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""

    private weak var coordinator: SignInCoordinating?

    init(coordinator: SignInCoordinating?) {
        self.coordinator = coordinator
    }

    // MARK: - Sign In Methods

    func signInWithGoogle() {
        guard let viewController = getTopViewController() else { return }

        isLoading = true

        Task { @MainActor in
            do {
                let user = try await SignInManager.shared.signInWithGoogle(presenting: viewController)
                coordinator?.finishSignIn(user: user)
            } catch {
                handleError(error)
            }
            isLoading = false
        }
    }

    func signInWithApple() {
        guard let viewController = getTopViewController() else { return }

        isLoading = true

        Task { @MainActor in
            do {
                let user = try await SignInManager.shared.signInWithApple(presenting: viewController)
                coordinator?.finishSignIn(user: user)
            } catch {
                handleError(error)
            }
            isLoading = false
        }
    }

    func signInAnonymously() {
        isLoading = true

        Task { @MainActor in
            do {
                let user = try await AuthManager.shared.createSession()
                coordinator?.finishSignIn(user: user)
            } catch {
                handleError(error)
            }
            isLoading = false
        }
    }

    // MARK: - Helpers

    private func handleError(_ error: Error) {
        // Ignore cancellation errors
        if (error as NSError).code == 1001 || // Google Sign-In cancelled
           (error as NSError).domain == "com.apple.AuthenticationServices.AuthorizationError" {
            return
        }

        errorMessage = error.localizedDescription
        showError = true
    }

    private func getTopViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            return nil
        }

        var topController = rootViewController
        while let presentedViewController = topController.presentedViewController {
            topController = presentedViewController
        }

        return topController
    }
}
