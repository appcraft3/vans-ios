import Foundation
import FirebaseRemoteConfig

final class RemoteConfigManager {

    static let shared = RemoteConfigManager()

    private let remoteConfig = RemoteConfig.remoteConfig()

    private init() {
        setupDefaults()
    }

    private func setupDefaults() {
        let defaults: [String: NSObject] = [
            "minimum_app_version": "1.0.0" as NSObject,
            "force_update_enabled": false as NSObject,
            "maintenance_mode": false as NSObject
        ]
        remoteConfig.setDefaults(defaults)

        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 3600 // 1 hour
        remoteConfig.configSettings = settings
    }

    func fetchConfig() async {
        do {
            let status = try await remoteConfig.fetch()
            if status == .success {
                try await remoteConfig.activate()
            }
        } catch {
            print("Error fetching remote config: \(error)")
        }
    }

    func getString(forKey key: String) -> String? {
        return remoteConfig.configValue(forKey: key).stringValue
    }

    func getBool(forKey key: String) -> Bool {
        return remoteConfig.configValue(forKey: key).boolValue
    }

    func getInt(forKey key: String) -> Int {
        return remoteConfig.configValue(forKey: key).numberValue.intValue
    }

    func getDouble(forKey key: String) -> Double {
        return remoteConfig.configValue(forKey: key).numberValue.doubleValue
    }
}
