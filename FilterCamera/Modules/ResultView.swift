//
//  ResultView.swift
//  FilterCamera
//
//  Created by binh on 28/4/26.
//

import SwiftUI
import AVKit

struct ResultView: View {

    let url: URL
    @EnvironmentObject var appState: AppState
    @State private var player: AVPlayer
    @State private var isSaving = false
    @StateObject private var viewModel = ResultViewModel()

    init(url: URL) {
        self.url = url
        _player = State(initialValue: AVPlayer(url: url))
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack {
                
                Spacer()

                VideoPlayer(player: player)
                    .aspectRatio(9/16, contentMode: .fill)

                Spacer()

                // 🔥 BUTTONS
                HStack(spacing: 20) {

                    // Save Button
                    Button(action: saveVideo) {
                        Text(isSaving ? "Saving..." : "Save")
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                    }
                    .disabled(isSaving)

                    // Record Again
                    Button(action: {
                        appState.route = .camera
                    }) {
                        Text("Record Again")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.indigo)
                            .cornerRadius(12)
                    }
                }
                .padding()
            }
            
            VStack {
                let isNotPremium = UserDefaultHelper.get(for: .isPremium, default: false) == false
                if isNotPremium {
                    BannerAdView()
                        .frame(height: 100)
                }
                Spacer()
            }
        }
        .onAppear {
            addLoop()
            player.play()
        }
        .onDisappear {
            player.pause()
            NotificationCenter.default.removeObserver(self)
        }
        .alert("Notification", isPresented: $viewModel.showAlert) {
            Button("OK", role: .cancel) {
                isSaving = false
                appState.route = .camera
            }
        } message: {
            switch viewModel.saveState {
            case .success:
                Text("Video saved successfully 🎉")
            case .error(let message):
                Text(message)
            default:
                Text("")
            }
        }
    }
}

extension ResultView {
    private func addLoop() {
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { _ in
            player.seek(to: .zero)
            player.play()
        }
    }
    
    private func saveVideo() {
        isSaving = true
        Task {
            await viewModel.saveVideoToPhotoLibrary(from: url)
        }
    }
}
