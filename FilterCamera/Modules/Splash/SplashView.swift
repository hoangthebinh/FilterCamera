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
    
    var body: some View {
        ZStack {

            Image("splash_image")
                .resizable()
                .scaledToFill()
                .offset(x: -50)
                .ignoresSafeArea()

            VStack {
                Spacer()

                VStack(spacing: 12) {

                    CustomProgressBar(progress: viewModel.progress)
                }
                .padding(.horizontal, 60)
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            viewModel.start()
        }
        .onReceive(viewModel.$route.compactMap { $0 }) { route in
            appState.route = route
        }
    }
}

struct CustomProgressBar: View {

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
                    .animation(.easeInOut(duration: 0.02), value: progress)
            }
        }
        .frame(height: 12)
    }
}


