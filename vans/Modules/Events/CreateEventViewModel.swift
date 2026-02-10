import Foundation
import FirebaseFunctions
import MapKit
import PhotosUI
import SwiftUI

@MainActor
final class CreateEventViewModel: ObservableObject {
    @Published var title = ""
    @Published var description = ""
    @Published var activityType = "hiking"
    @Published var selectedLocation: LocationResult?
    @Published var date = Date().addingTimeInterval(3600) // 1 hour from now
    @Published var endDate = Date().addingTimeInterval(7200) // 2 hours from now
    @Published var maxAttendees = 20
    @Published var allowCheckIn = true // If false, only interest marking is available

    @Published var selectedPhotos: [PhotosPickerItem] = []
    @Published var selectedImages: [UIImage] = []
    @Published var uploadProgress: String?

    @Published var isLoading = false
    @Published var errorMessage: String?

    private let functions = Functions.functions()

    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !activityType.isEmpty &&
        selectedLocation != nil &&
        date > Date() &&
        endDate > date
    }

    func loadImages() async {
        var images: [UIImage] = []
        for item in selectedPhotos {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                images.append(image)
            }
        }
        selectedImages = images
    }

    func removeImage(at index: Int) {
        guard index < selectedImages.count else { return }
        selectedImages.remove(at: index)
        if index < selectedPhotos.count {
            selectedPhotos.remove(at: index)
        }
    }

    private func compressImage(_ image: UIImage, maxSize: CGFloat = 1200) -> Data? {
        let size = image.size
        let ratio = min(maxSize / size.width, maxSize / size.height, 1.0)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)

        UIGraphicsBeginImageContextWithOptions(newSize, true, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return resized?.jpegData(compressionQuality: 0.7)
    }

    private func uploadPhotos() async throws -> [String] {
        guard !selectedImages.isEmpty else { return [] }

        uploadProgress = "Uploading photos..."

        var base64Images: [String] = []
        for image in selectedImages {
            guard let data = compressImage(image) else { continue }
            base64Images.append(data.base64EncodedString())
        }

        let result = try await functions.httpsCallable("uploadEventPhotos").call([
            "images": base64Images
        ])

        guard let data = result.data as? [String: Any],
              let success = data["success"] as? Bool,
              success,
              let photos = data["photos"] as? [String] else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to upload photos"])
        }

        uploadProgress = nil
        return photos
    }

    func createEvent() async -> Bool {
        guard isValid, let location = selectedLocation else { return false }

        isLoading = true
        errorMessage = nil

        do {
            // Upload photos first if any
            var photoUrls: [String] = []
            if !selectedImages.isEmpty {
                uploadProgress = "Uploading photos..."
                photoUrls = try await uploadPhotos()
            }

            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime]

            uploadProgress = "Creating event..."

            var params: [String: Any] = [
                "title": title.trimmingCharacters(in: .whitespaces),
                "description": description.trimmingCharacters(in: .whitespaces),
                "activityType": activityType,
                "region": location.region,
                "country": location.country,
                "approximateArea": location.name,
                "latitude": location.coordinate.latitude,
                "longitude": location.coordinate.longitude,
                "date": formatter.string(from: date),
                "endDate": formatter.string(from: endDate),
                "maxAttendees": maxAttendees,
                "allowCheckIn": allowCheckIn
            ]

            if !photoUrls.isEmpty {
                params["photos"] = photoUrls
            }

            let result = try await functions.httpsCallable("createEvent").call(params)

            guard let data = result.data as? [String: Any],
                  let success = data["success"] as? Bool,
                  success else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create event"])
            }

            uploadProgress = nil
            isLoading = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            uploadProgress = nil
            isLoading = false
            return false
        }
    }
}
