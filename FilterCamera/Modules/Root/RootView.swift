//
//  RootView.swift
//  FilterCamera
//
//  Created by binh on 25/04/2026.
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        switch appState.route {
        case .splash:
            SplashView()
        case .onboarding:
            OnboardingView()
        case .paywall:
            PaywallView()
        case .camera:
            CameraView()
        case .result(let url):
            ResultView(url: url)
        case .purchase:
            PurchaseView()
        }
    }
}
