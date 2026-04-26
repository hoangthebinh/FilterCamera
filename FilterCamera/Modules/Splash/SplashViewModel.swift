//
//  SplashViewModel.swift
//  FilterCamera
//
//  Created by binh on 25/04/2026.
//

import Foundation
import Combine
import QuartzCore

final class SplashViewModel: ObservableObject {

    @Published var progress: Double = 0
    @Published var route: Route?

    private let duration: Double = 3.0
    private var hasStarted = false
    private var startTime: Date?
    private var displayLink: CADisplayLink?

    func start() {
        guard !hasStarted else {
            return
        }

        hasStarted = true
        startTime = Date()

        displayLink = CADisplayLink(target: self, selector: #selector(update))
        displayLink?.add(to: .main, forMode: .common)
    }

    @objc private func update() {
        guard let startTime else { return }

        let elapsed = Date().timeIntervalSince(startTime)
        progress = min(elapsed / duration, 1.0)
        
        if progress >= 1 {
            displayLink?.invalidate()
            displayLink = nil

            handleFinishedLoading()
        }
    }
    
    private func handleFinishedLoading() {
        let isPremium = UserDefaultHelper.get(for: .isPremium, default: false)
        if isPremium {
            route = .camera
        } else {
            let isOnboarded = UserDefaultHelper.get(for: .isOnboarded, default: false)
            route = isOnboarded ? .paywall : .onboarding
        }
    }
}
