//
//  BannerAdView.swift
//  FilterCamera
//
//  Created by binh on 26/4/26.
//

import SwiftUI
import GoogleMobileAds

struct BannerAdView: UIViewRepresentable {
    private let bannerAdTestId = "ca-app-pub-3940256099942544/2934735716"
    
    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: AdSizeBanner)
        banner.adUnitID = bannerAdTestId
        banner.rootViewController = UIApplication.shared.topViewController()
        banner.load(Request())
        return banner
    }

    func updateUIView(_ uiView: BannerView, context: Context) {}
}
