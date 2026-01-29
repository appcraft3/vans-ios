import Foundation
import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import AuthenticationServices
import CryptoKit

final class SignInManager: NSObject {

    static let shared = SignInManager()

    private var currentNonce: String?
    private var appleSignInContinuation: CheckedContinuation<AuthCredential, Error>?

    private override init() {
        super.init()
    }

    // MARK: - Google Sign In

    func signInWithGoogle(presenting viewController: UIViewController) async throws -> UserData {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw SignInError.missingClientID
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: viewController)

        guard let idToken = result.user.idToken?.tokenString else {
            throw SignInError.missingToken
        }

        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: result.user.accessToken.tokenString
        )

        return try await signInWithCredential(credential)
    }

    // MARK: - Apple Sign In

    func signInWithApple(presenting viewController: UIViewController) async throws -> UserData {
        let nonce = randomNonceString()
        currentNonce = nonce

        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)

        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self

        let credential = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<AuthCredential, Error>) in
            self.appleSignInContinuation = continuation
            authorizationController.performRequests()
        }

        return try await signInWithCredential(credential)
    }

    // MARK: - Common Sign In

    private func signInWithCredential(_ credential: AuthCredential) async throws -> UserData {
        let authResult = try await Auth.auth().signIn(with: credential)
        let firebaseUser = authResult.user

        // Check if user exists in Firestore, if not create
        let response: GetUserResponse = try await createOrGetUser(
            userId: firebaseUser.uid,
            email: firebaseUser.email,
            displayName: firebaseUser.displayName
        )

        return response.user
    }

    private func createOrGetUser(userId: String, email: String?, displayName: String?) async throws -> GetUserResponse {
        let data: [String: Any] = [
            "email": email ?? "",
            "displayName": displayName ?? ""
        ]

        return try await FirebaseManager.shared.callFunction(name: "createOrGetUser", data: data)
    }

    // MARK: - Nonce Helpers

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }

        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }

        return String(nonce)
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()

        return hashString
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension SignInManager: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let nonce = currentNonce,
              let appleIDToken = appleIDCredential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            appleSignInContinuation?.resume(throwing: SignInError.missingToken)
            appleSignInContinuation = nil
            return
        }

        let credential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: nonce,
            fullName: appleIDCredential.fullName
        )

        appleSignInContinuation?.resume(returning: credential)
        appleSignInContinuation = nil
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        appleSignInContinuation?.resume(throwing: error)
        appleSignInContinuation = nil
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension SignInManager: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            fatalError("No window found")
        }
        return window
    }
}

// MARK: - SignInError

enum SignInError: Error, LocalizedError {
    case missingClientID
    case missingToken
    case cancelled
    case unknown

    var errorDescription: String? {
        switch self {
        case .missingClientID:
            return "Missing Google client ID"
        case .missingToken:
            return "Failed to get authentication token"
        case .cancelled:
            return "Sign in was cancelled"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}
