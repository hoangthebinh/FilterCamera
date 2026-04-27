//
//  InterstitialAdManager.swift
//  FilterCamera
//
//  Created by binh on 26/4/26.
//

import Foundation
import GoogleMobileAds
import UIKit

enum InterstitialAdLoadState: Equatable {
    case idle
    case loading
    case ready
    case failed
}

final class InterstitialAdManager: NSObject, ObservableObject, FullScreenContentDelegate {
    static let shared = InterstitialAdManager()
    
    private var interstitial: InterstitialAd?
    @Published private(set) var isAdReady = false
    @Published private(set) var loadState: InterstitialAdLoadState = .idle
    private var isLoading = false
    private let interstitialAdTestId = "ca-app-pub-3940256099942544/4411468910"
    private var onDismiss: (() -> Void)?
    
    
    // MARK: - Load Ads
    func loadAd() {
        guard !isLoading, interstitial == nil else { return }
        isLoading = true
        loadState = .loading
        
        InterstitialAd.load(with: interstitialAdTestId,
                            request: Request()) { [weak self] ad, error in
            self?.isLoading = false
            
            if let error = error {
                self?.isAdReady = false
                self?.loadState = .failed
                print("Load Interstitial error:", error.localizedDescription)
                return
            }
            
            ad?.fullScreenContentDelegate = self
            self?.interstitial = ad
            self?.isAdReady = ad != nil
            self?.loadState = ad == nil ? .failed : .ready
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
        loadState = .idle
        interstitial.present(from: rootVC)
    }
    
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        interstitial = nil
        isAdReady = false
        loadState = .idle
        
        let dismissHandler = onDismiss
        onDismiss = nil
        dismissHandler?()
        
        loadAd()
    }
    
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("Present Interstitial error:", error.localizedDescription)
        interstitial = nil
        isAdReady = false
        loadState = .failed
        
        let dismissHandler = onDismiss
        onDismiss = nil
        dismissHandler?()
        
        loadAd()
    }
}
