import Foundation

enum APIError: Error, LocalizedError {
    case noData
    case decodeFailed
    case networkError(Error)
    case serverError(String)
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .noData:
            return "No data received from server"
        case .decodeFailed:
            return "Failed to decode response"
        case .networkError(let error):
            return error.localizedDescription
        case .serverError(let message):
            return message
        case .unauthorized:
            return "Unauthorized access"
        }
    }
}
