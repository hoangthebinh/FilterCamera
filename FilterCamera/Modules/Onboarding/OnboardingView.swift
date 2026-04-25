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

    var body: some View {
        ZStack {
            TabView(selection: $viewModel.currentIndex) {
                ForEach(0..<viewModel.items.count, id: \.self) { index in
                    ZStack {

                        Image(viewModel.items[index].image)
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

                            Text(viewModel.items[index].title)
                                .foregroundColor(.white)
                                .fontWeight(.bold)
                                .font(.title)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                                .padding(.bottom, 160)
                        }
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()

            VStack {
                Spacer()

                VStack(spacing: 24) {

                    HStack(spacing: 8) {
                        ForEach(0..<viewModel.items.count, id: \.self) { index in
                            Circle()
                                .fill(index == viewModel.currentIndex ? Color.white : Color.gray)
                                .frame(width: 8, height: 8)
                        }
                    }

                    Button(action: {
                        if viewModel.isLast {
                            UserDefaultHelper.save(value: true, key: .isOnboarded)
                            appState.route = .paywall
                        } else {
                            viewModel.nextPage()
                        }
                    }) {
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
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .animation(.easeInOut, value: viewModel.currentIndex)
    }
}
#Preview {
    OnboardingView()
}
