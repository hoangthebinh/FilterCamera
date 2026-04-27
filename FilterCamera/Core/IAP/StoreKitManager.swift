//
//  StoreKitManager.swift
//  FilterCamera
//
//  Created by binh on 26/4/26.
//

import StoreKit

enum ProductType: String {
    case weekly
    case monthly
    case yearly

    init?(productID: String) {
        if productID.contains("weekly") {
            self = .weekly
        } else if productID.contains("monthly") {
            self = .monthly
        } else if productID.contains("yearly") {
            self = .yearly
        } else {
            return nil
        }
    }
}

@MainActor
final class StoreKitManager: ObservableObject {

    static let shared = StoreKitManager()

    // MARK: - Public State
    @Published private(set) var products: [Product] = []
    @Published private(set) var isPremium: Bool = false
    @Published private(set) var expirationDate: Date?
    @Published private(set) var currentPlan: ProductType?

    // MARK: - Config
    private let productIDs: [String] = [
        "filtercamera.premium.weekly",
        "filtercamera.premium.monthly",
        "filtercamera.premium.yearly"
    ]

    // MARK: - Init
    init() {
        listenForTransactions()
    }

    // MARK: - Load products
    func loadProducts() async {
        do {
            let fetched = try await Product.products(for: productIDs)

            // sort theo giá tăng dần (week → month → year thường sẽ đúng)
            self.products = fetched.sorted { $0.price < $1.price }
        } catch {
            print("❌ Load products error:", error)
        }
    }

    // MARK: - Helpers
    func product(for id: String) -> Product? {
        products.first { $0.id == id }
    }

    // MARK: - Purchase
    func purchase(_ product: Product) async -> Bool {
        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()

                await updatePremiumStatus()
                return true

            case .userCancelled:
                return false

            case .pending:
                return false

            default:
                return false
            }

        } catch {
            print("❌ Purchase error:", error)
            return false
        }
    }

    // MARK: - Restore
    func restore() async -> Bool {
        do {
            try await AppStore.sync()
            await updatePremiumStatus()
            return isPremium
        } catch {
            print("❌ Restore error:", error)
            await updatePremiumStatus()
            return isPremium
        }
    }

    // MARK: - Core: Check entitlement + plan + expiry
    func updatePremiumStatus() async {

        var active = false
        var latestExpiry: Date?
        var activePlan: ProductType?

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }

            if let expiry = transaction.expirationDate {

                // subscription
                if expiry > Date() {
                    active = true

                    if let current = latestExpiry {
                        if expiry > current {
                            latestExpiry = expiry
                            activePlan = ProductType(productID: transaction.productID)
                        }
                    } else {
                        latestExpiry = expiry
                        activePlan = ProductType(productID: transaction.productID)
                    }
                }

            } else {
                // non-consumable (lifetime)
                active = true
                activePlan = ProductType(productID: transaction.productID)
            }
        }

        self.isPremium = active
        self.expirationDate = latestExpiry
        self.currentPlan = activePlan

        UserDefaultHelper.save(value: active, key: .isPremium)

        print("✅ Premium:", active)
        print("📦 Plan:", activePlan?.rawValue ?? "none")
        print("⏳ Exp:", latestExpiry?.formatted() ?? "none")
    }

    // MARK: - Listen realtime updates (renew, cancel, refund...)
    private func listenForTransactions() {
        Task {
            for await result in Transaction.updates {
                guard case .verified(let transaction) = result else { continue }

                await updatePremiumStatus()
                await transaction.finish()
            }
        }
    }

    // MARK: - Verify
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw NSError(domain: "StoreKit", code: 0)
        case .verified(let safe):
            return safe
        }
    }
}
