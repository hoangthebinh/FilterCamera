//
//  InterstitialAdManager.swift
//  FilterCamera
//
//  Created by binh on 26/4/26.
//

import Foundation
import GoogleMobileAds
import UIKit

final class InterstitialAdManager: NSObject, ObservableObject, FullScreenContentDelegate {
    static let shared = InterstitialAdManager()
    
    private var interstitial: InterstitialAd?
    @Published private(set) var isAdReady = false
    private var isLoading = false
    private var onDismiss: (() -> Void)?
    
    // MARK: - Load Ads
    func loadAd() {
        guard !isLoading, interstitial == nil else { return }
        isLoading = true
        
        InterstitialAd.load(
            with: "ca-app-pub-3940256099942544/4411468910",
            request: Request()
        ) { [weak self] ad, error in
            self?.isLoading = false
            
            if let error = error {
                self?.isAdReady = false
                print("Load Interstitial error:", error.localizedDescription)
                return
            }
            
            ad?.fullScreenContentDelegate = self
            self?.interstitial = ad
            self?.isAdReady = ad != nil
            print("Interstitial loaded")
        }
    }
    
    // MARK: - Show Ads
    func showAd(onDismiss: (() -> Void)? = nil) {
        guard let rootVC = UIApplication.shared.topViewController(),
              let interstitial = interstitial else {
            print("Ad not ready")
            onDismiss?()
            return
        }
        
        self.onDismiss = onDismiss
        isAdReady = false
        interstitial.present(from: rootVC)
    }
    
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        interstitial = nil
        isAdReady = false
        
        let dismissHandler = onDismiss
        onDismiss = nil
        dismissHandler?()
        
        loadAd()
    }
    
    func ad(
        _ ad: FullScreenPresentingAd,
        didFailToPresentFullScreenContentWithError error: Error
    ) {
        print("Present Interstitial error:", error.localizedDescription)
        interstitial = nil
        isAdReady = false
        
        let dismissHandler = onDismiss
        onDismiss = nil
        dismissHandler?()
        
        loadAd()
    }
}
