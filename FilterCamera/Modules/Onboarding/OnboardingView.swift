//
//  OnboardingView.swift
//  FilterCamera
//
//  Created by binh on 25/04/2026.
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = OnboardingViewModel()

    private let horizontalPadding: CGFloat = 24
    private let bottomPadding: CGFloat = 40
    private let titleBottomPadding: CGFloat = 160
    private let pageIndicatorSpacing: CGFloat = 8

    var body: some View {
        ZStack {
            onboardingPages
            footerSection
        }
        .animation(.easeInOut, value: viewModel.currentIndex)
    }

    private var onboardingPages: some View {
        TabView(selection: $viewModel.currentIndex) {
            ForEach(Array(viewModel.items.enumerated()), id: \.offset) { index, item in
                pageView(for: item)
                    .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .ignoresSafeArea()
    }

    private var footerSection: some View {
        VStack {
            Spacer()

            VStack(spacing: 24) {
                pageIndicator
                continueButton
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.bottom, bottomPadding)
        }
    }

    private var pageIndicator: some View {
        HStack(spacing: pageIndicatorSpacing) {
            ForEach(0..<viewModel.items.count, id: \.self) { index in
                Circle()
                    .fill(index == viewModel.currentIndex ? Color.white : Color.gray)
                    .frame(width: 8, height: 8)
            }
        }
    }

    private var continueButton: some View {
        Button(action: handleContinueTapped) {
            Text(viewModel.isLast ? "Get Started" : "Continue")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.indigo)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white)
                .cornerRadius(36)
        }
    }

    private func pageView(for item: OnboardingViewModel.OnboardingItem) -> some View {
        ZStack {
            Image(item.image)
                .resizable()
                .scaledToFill()
                .offset(x: -30)
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    Color.black.opacity(1),
                    Color.black.opacity(0.5),
                    Color.clear
                ],
                startPoint: .bottom,
                endPoint: .top
            )
            .ignoresSafeArea()

            VStack {
                Spacer()

                Text(item.title)
                    .foregroundColor(.white)
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, horizontalPadding)
                    .padding(.bottom, titleBottomPadding)
            }
        }
    }

    private func handleContinueTapped() {
        if viewModel.isLast {
            UserDefaultHelper.save(value: true, key: .isOnboarded)
            appState.route = .paywall
            return
        }

        viewModel.nextPage()
    }
}

#Preview {
    OnboardingView()
}
