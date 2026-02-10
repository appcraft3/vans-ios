import Foundation
import RevenueCat

@MainActor
final class PurchaseManager: NSObject, ObservableObject {

    static let shared = PurchaseManager()

    @Published private(set) var isPro = false
    @Published private(set) var offerings: Offerings?
    @Published private(set) var customerInfo: CustomerInfo?

    private static let apiKey = "test_YLWzunJDVPlhjKIrutuNrTVJvrC"
    private static let entitlementID = "VanGo Pro"

    private override init() {
        super.init()
    }

    // MARK: - Configure

    func configure() {
        Purchases.logLevel = .warn
        Purchases.configure(withAPIKey: Self.apiKey)
        Purchases.shared.delegate = self

        Task {
            await checkProStatus()
            await loadOfferings()
        }
    }

    // MARK: - User Identity

    func login(userId: String) async {
        do {
            let (info, _) = try await Purchases.shared.logIn(userId)
            customerInfo = info
            isPro = info.entitlements[Self.entitlementID]?.isActive == true
        } catch {
            print("RevenueCat login error: \(error)")
        }
    }

    func logout() async {
        do {
            let info = try await Purchases.shared.logOut()
            customerInfo = info
            isPro = false
        } catch {
            print("RevenueCat logout error: \(error)")
        }
    }

    // MARK: - Offerings

    func loadOfferings() async {
        do {
            offerings = try await Purchases.shared.offerings()
        } catch {
            print("Failed to load offerings: \(error)")
        }
    }

    // MARK: - Purchase

    func purchase(_ package: Package) async throws -> CustomerInfo {
        let result = try await Purchases.shared.purchase(package: package)
        let info = result.customerInfo
        customerInfo = info
        isPro = info.entitlements[Self.entitlementID]?.isActive == true
        return info
    }

    // MARK: - Restore

    func restorePurchases() async throws -> CustomerInfo {
        let info = try await Purchases.shared.restorePurchases()
        customerInfo = info
        isPro = info.entitlements[Self.entitlementID]?.isActive == true
        return info
    }

    // MARK: - Entitlement Check

    func checkProStatus() async {
        do {
            let info = try await Purchases.shared.customerInfo()
            customerInfo = info
            isPro = info.entitlements[Self.entitlementID]?.isActive == true
        } catch {
            print("Failed to check pro status: \(error)")
        }
    }
}

// MARK: - PurchasesDelegate

extension PurchaseManager: PurchasesDelegate {
    nonisolated func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            self.customerInfo = customerInfo
            self.isPro = customerInfo.entitlements[Self.entitlementID]?.isActive == true
        }
    }
}
