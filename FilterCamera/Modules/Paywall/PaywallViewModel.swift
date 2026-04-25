//
//  PaywallViewModel.swift
//  FilterCamera
//
//  Created by binh on 25/04/2026.
//

import Foundation

struct Plan {
    let title: String
    let features: [String]
    let info: String
}

final class PaywallViewModel: ObservableObject {
    @Published var selectedIndex: Int = 0
    
    let plans: [Plan] = [
        Plan(
            title: "Premium",
            features: ["✅Remove Ads", "All Filters"],
            info: "5.99$/Week, cancel anytime"
        ),
        Plan(
            title: "Standard",
            features: ["❌ Remove Ads", "Limited Filters"],
            info: "Get started with ads"
        )
    ]
}
