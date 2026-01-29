import Foundation
import UIKit

final class ForceUpdateManager {

    static let shared = ForceUpdateManager()

    private init() {}

    var needsForceUpdate: Bool {
        guard RemoteConfigManager.shared.getBool(forKey: "force_update_enabled"),
              let minimumVersion = RemoteConfigManager.shared.getString(forKey: "minimum_app_version") else {
            return false
        }

        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
        return compareVersions(currentVersion, minimumVersion) < 0
    }

    func openAppStore() {
        guard let appStoreURL = URL(string: "https://apps.apple.com/app/id\(Setup.appStoreId)") else { return }
        if UIApplication.shared.canOpenURL(appStoreURL) {
            UIApplication.shared.open(appStoreURL)
        }
    }

    private func compareVersions(_ version1: String, _ version2: String) -> Int {
        let v1 = version1.split(separator: ".").compactMap { Int($0) }
        let v2 = version2.split(separator: ".").compactMap { Int($0) }
        let maxLength = max(v1.count, v2.count)

        for i in 0..<maxLength {
            let val1 = i < v1.count ? v1[i] : 0
            let val2 = i < v2.count ? v2[i] : 0
            if val1 < val2 { return -1 }
            else if val1 > val2 { return 1 }
        }
        return 0
    }
}
