import Foundation
import RevenueCat

enum PaywallPlan: String {
    case monthly
    case yearly
}

@MainActor
final class PaywallViewModel: ObservableObject {

    @Published var selectedPlan: PaywallPlan = .yearly
    @Published var isPurchasing = false
    @Published var isRestoring = false
    @Published var errorMessage: String?
    @Published var didPurchase = false

    @Published private(set) var monthlyPackage: Package?
    @Published private(set) var yearlyPackage: Package?

    var onDismiss: (() -> Void)?

    // MARK: - Computed

    var monthlyPrice: String {
        monthlyPackage?.localizedPriceString ?? "$—"
    }

    var yearlyPrice: String {
        yearlyPackage?.localizedPriceString ?? "$—"
    }

    var yearlyMonthlyEquivalent: String {
        guard let yearly = yearlyPackage?.storeProduct.price as? NSDecimalNumber else { return "" }
        let monthly = yearly.doubleValue / 12.0
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = yearlyPackage?.storeProduct.priceFormatter?.locale ?? .current
        return formatter.string(from: NSNumber(value: monthly)) ?? ""
    }

    var discountPercentage: Int {
        guard let monthlyPrice = monthlyPackage?.storeProduct.price as? NSDecimalNumber,
              let yearlyPrice = yearlyPackage?.storeProduct.price as? NSDecimalNumber else { return 0 }
        let monthlyAnnual = monthlyPrice.doubleValue * 12.0
        guard monthlyAnnual > 0 else { return 0 }
        let discount = (1.0 - yearlyPrice.doubleValue / monthlyAnnual) * 100.0
        return Int(ceil(discount))
    }

    // MARK: - Load

    func loadOfferings() async {
        await PurchaseManager.shared.loadOfferings()

        guard let current = PurchaseManager.shared.offerings?.current else { return }

        monthlyPackage = current.package(identifier: "$rc_monthly")
            ?? current.availablePackages.first(where: { $0.packageType == .monthly })

        yearlyPackage = current.package(identifier: "$rc_annual")
            ?? current.availablePackages.first(where: { $0.packageType == .annual })
    }

    // MARK: - Purchase

    func purchase() async {
        let package: Package?
        switch selectedPlan {
        case .monthly: package = monthlyPackage
        case .yearly: package = yearlyPackage
        }

        guard let pkg = package else {
            errorMessage = "Plan not available. Please try again."
            return
        }

        isPurchasing = true
        errorMessage = nil

        do {
            _ = try await PurchaseManager.shared.purchase(pkg)
            didPurchase = true
        } catch let error as RevenueCat.ErrorCode {
            if error != .purchaseCancelledError {
                errorMessage = error.localizedDescription
            }
        } catch {
            if (error as NSError).code != 2 { // user cancelled
                errorMessage = error.localizedDescription
            }
        }

        isPurchasing = false
    }

    // MARK: - Restore

    func restore() async {
        isRestoring = true
        errorMessage = nil

        do {
            let info = try await PurchaseManager.shared.restorePurchases()
            if info.entitlements["VanGo Pro"]?.isActive == true {
                didPurchase = true
            } else {
                errorMessage = "No active subscription found."
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isRestoring = false
    }
}
