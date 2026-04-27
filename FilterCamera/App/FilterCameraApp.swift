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
            await StoreKitManager.shared.updatePremiumStatus()

            guard !StoreKitManager.shared.isPremium else { return }

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
