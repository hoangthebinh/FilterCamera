//
//  PurchaseViewModel.swift
//  FilterCamera
//
//  Created by binh on 26/4/26.
//

import Foundation
import StoreKit

@MainActor
final class PurchaseViewModel: ObservableObject {

    @Published var products: [Product] = []
    @Published var selectedProduct: Product?
    @Published var isLoading = false

    private let store = StoreKitManager.shared
    
    func load() async {
        await store.loadProducts()

        products = store.products.sorted { $0.price < $1.price }

        selectedProduct = products.last
    }

    func purchase() async -> Bool {
        guard let product = selectedProduct else { return false }

        isLoading = true
        let success = await store.purchase(product)
        isLoading = false

        return success
    }

    func restore() async -> Bool {
        isLoading = true
        let success = await store.restore()
        isLoading = false

        return success
    }
}
