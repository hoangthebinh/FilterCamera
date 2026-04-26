//
//  FilterCameraApp.swift
//  FilterCamera
//
//  Created by binh on 25/04/2026.
//

import SwiftUI
import GoogleMobileAds

@main
struct FilterCameraApp: App {

    @StateObject private var appState = AppState()

    init() {
        Task {
            _ = await StoreKitManager.shared.updatePremiumStatus()
        }
        let isPremium = UserDefaultHelper.get(for: .isPremium, default: false)
        guard !isPremium else { return }
        Task {
            _ = await MobileAds.shared.start()
            InterstitialAdManager.shared.loadAd()
        }
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
        }
    }
}
