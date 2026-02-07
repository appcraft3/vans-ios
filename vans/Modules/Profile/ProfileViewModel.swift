import Foundation
import Combine
import PhotosUI
import SwiftUI

struct ConnectionsResponse: Codable {
    let success: Bool
    let connections: [DiscoveryUser]?
    let total: Int
}

struct UploadPhotoResponse: Codable {
    let success: Bool
    let photoUrl: String
}

final class ProfileViewModel: ActionableViewModel {
    @Published var user: UserData?
    @Published var isLoading: Bool = false
    @Published var connectionsCount: Int = 0

    // Photo editing
    @Published var selectedPhotoItem: PhotosPickerItem?
    @Published var isUploadingPhoto: Bool = false
    @Published var photoUploadError: String?

    // Builder
    @Published var isBuilder: Bool = false
    @Published var builderSessions: Int = 0
    @Published var builderRating: Int = 100

    private weak var coordinator: ProfileCoordinating?
    private var cancellables = Set<AnyCancellable>()

    var isAdmin: Bool {
        user?.role == .admin
    }

    init(coordinator: ProfileCoordinating?) {
        self.coordinator = coordinator
        setupUserObserver()
        setupPhotoObserver()
    }

    private func setupUserObserver() {
        UserManager.shared.$currentUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                self?.user = user
            }
            .store(in: &cancellables)
    }

    private func setupPhotoObserver() {
        $selectedPhotoItem
            .compactMap { $0 }
            .sink { [weak self] item in
                Task {
                    await self?.uploadPhoto(from: item)
                }
            }
            .store(in: &cancellables)
    }

    @MainActor
    private func uploadPhoto(from item: PhotosPickerItem) async {
        isUploadingPhoto = true
        photoUploadError = nil

        do {
            // Load image data
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to load image"])
            }

            // Compress and resize image
            let resizedImage = resizeImage(image, maxSize: 500)
            guard let compressedData = resizedImage.jpegData(compressionQuality: 0.7) else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"])
            }

            // Convert to base64 and upload via backend
            let base64String = compressedData.base64EncodedString()

            let response: UploadPhotoResponse = try await FirebaseManager.shared.callFunction(
                name: "uploadProfilePhoto",
                data: ["imageData": base64String]
            )

            // Update profile with new photo URL
            _ = try await AuthManager.shared.updateProfile(photoUrl: response.photoUrl)

            // Clear selection
            selectedPhotoItem = nil

        } catch {
            photoUploadError = error.localizedDescription
        }

        isUploadingPhoto = false
    }

    private func resizeImage(_ image: UIImage, maxSize: CGFloat) -> UIImage {
        let size = image.size
        let ratio = min(maxSize / size.width, maxSize / size.height)

        if ratio >= 1 { return image }

        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    func loadUser() {
        user = UserManager.shared.currentUser ?? AuthManager.shared.currentUser
        loadConnectionsCount()
        loadBuilderStatus()
    }

    private func loadBuilderStatus() {
        Task { @MainActor in
            do {
                let response: MyBuilderProfileResponse = try await FirebaseManager.shared.callFunction(
                    name: "getMyBuilderProfile",
                    data: [:]
                )
                self.isBuilder = response.isBuilder
                if let builder = response.builder {
                    self.builderSessions = builder.completedSessions
                    self.builderRating = builder.rating
                }
            } catch {
                print("Failed to load builder status: \(error)")
            }
        }
    }

    func openBecomeBuilder() {
        coordinator?.showBecomeBuilder()
    }

    private func loadConnectionsCount() {
        Task { @MainActor in
            do {
                let response: ConnectionsResponse = try await FirebaseManager.shared.callFunction(
                    name: "getConnections",
                    data: ["limit": 1]
                )
                self.connectionsCount = response.total
            } catch {
                print("Failed to load connections count: \(error)")
            }
        }
    }

    func signOut() {
        Task { @MainActor in
            do {
                try await AuthManager.shared.signOut()
                UserManager.shared.clearUser()
                NotificationCenter.default.post(name: .userDidSignOut, object: nil)
            } catch {
                print("Sign out error: \(error)")
            }
        }
    }

    func openWaitlistReview() {
        coordinator?.showWaitlistReview()
    }
}

extension Notification.Name {
    static let userDidSignOut = Notification.Name("userDidSignOut")
}
