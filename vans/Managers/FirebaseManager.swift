import Foundation
import FirebaseCore
import FirebaseFunctions

final class FirebaseManager {

    static let shared = FirebaseManager()

    private lazy var functions = Functions.functions()

    private init() {}

    func configure() {
        FirebaseApp.configure()
    }

    // MARK: - Cloud Functions

    func callFunction<T: Decodable>(name: String, data: [String: Any]? = nil) async throws -> T {
        let callable = functions.httpsCallable(name)
        let result = try await callable.call(data)

        let resultData = result.data

        let jsonData = try JSONSerialization.data(withJSONObject: resultData)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(T.self, from: jsonData)
    }

    func callFunctionVoid(name: String, data: [String: Any]? = nil) async throws {
        let callable = functions.httpsCallable(name)
        _ = try await callable.call(data)
    }
}
