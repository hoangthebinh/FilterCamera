//
//  SplashView.swift
//  FilterCamera
//
//  Created by binh on 25/04/2026.
//

import SwiftUI

struct SplashView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = SplashViewModel()
    @StateObject private var adManager = InterstitialAdManager.shared
    @State private var pendingRoute: Route?

    private let progressHorizontalPadding: CGFloat = 60
    private let progressBottomPadding: CGFloat = 50

    var body: some View {
        ZStack {
            Image("splash_image")
                .resizable()
                .scaledToFill()
                .offset(x: -50)
                .ignoresSafeArea()

            progressSection
        }
        .onAppear {
            viewModel.start()
        }
        .onReceive(viewModel.$route.compactMap { $0 }) { route in
            pendingRoute = route
            showAdIfReady()
        }
        .onReceive(adManager.$isAdReady.removeDuplicates()) { isAdReady in
            guard isAdReady else {
                return
            }

            showAdIfReady()
        }
    }

    private var progressSection: some View {
        VStack {
            Spacer()

            SplashProgressBar(progress: viewModel.progress)
                .padding(.horizontal, progressHorizontalPadding)
                .padding(.bottom, progressBottomPadding)
        }
    }

    private func showAdIfReady() {
        guard let pendingRoute, adManager.isAdReady else {
            return
        }

        adManager.showAd {
            appState.route = pendingRoute
            self.pendingRoute = nil
        }
    }
}

private struct SplashProgressBar: View {
    var progress: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.2))

                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * progress)
            }
        }
        .frame(height: 12)
    }
}

#Preview {
//    SplashView()
//        .environmentObject(AppState())
}
