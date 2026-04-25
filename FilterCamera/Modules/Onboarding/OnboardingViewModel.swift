//
//  OnboardingViewModel.swift
//  FilterCamera
//
//  Created by binh on 25/04/2026.
//

import Foundation



final class OnboardingViewModel: ObservableObject {
    
    struct OnboardingItem {
        let image: String
        let title: String
    }
    
    @Published var currentIndex: Int = 0
    
    let items: [OnboardingItem] = [
        .init(image: "onboard_image_1", title: "Welcome to Filter Camera"),
        .init(image: "onboard_image_2", title: "Get Creative Effects"),
        .init(image: "onboard_image_3", title: "Advanced Filter Effects"),
        .init(image: "onboard_image_4", title: "Add Multiple Music")
    ]

    var isLast: Bool {
        currentIndex == items.count - 1
    }

    func nextPage() {
        if currentIndex < items.count - 1 {
            currentIndex += 1
        }
    }
}
