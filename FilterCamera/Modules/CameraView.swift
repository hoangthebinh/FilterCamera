//
//  CameraView.swift
//  FilterCamera
//
//  Created by binh on 27/4/26.
//

import SwiftUI

struct CameraView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedDuration: Int = 15

    @StateObject private var store = StoreKitManager.shared
    @StateObject private var viewModel = CameraViewModel()

    private let durations = [15, 30, 60, 120]

    var body: some View {
        ZStack {
            CameraPreview(service: viewModel.service)
                .ignoresSafeArea(edges: .bottom)

            VStack {
                let isNotPremium = UserDefaultHelper.get(for: .isPremium, default: false) == false
                if isNotPremium {
                    BannerAdView()
                        .frame(height: 50)
                }
                HStack(alignment: .top) {
                    Spacer()

                    switchCameraButton
                }
                .padding(.top, 8)
                .padding(.trailing, 24)

                Spacer()

                if viewModel.isRecording {
                    Text("\(viewModel.remainingTime)s")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.bottom, 10)
                }

                durationSelector
                recordButton
                    .padding(.top, 20)
                    .padding(.bottom, 30)
            }
        }
        .task {
            viewModel.setup()
        }
        .alert("Camera Error",
               isPresented: Binding(
                get: { viewModel.alertMessage != nil },
                set: { isPresented in
                    if !isPresented {
                        viewModel.clearAlert()
                    }
                }
               ),
               actions: {
                   Button("OK", role: .cancel) {
                       viewModel.clearAlert()
                   }
               },
               message: {
                   Text(viewModel.alertMessage ?? "")
               })
        .onDisappear {
            viewModel.stop()
            viewModel.service.stopSession()
        }
        .onReceive(viewModel.$recordedURL.removeDuplicates()) { url in
            guard let url = url, !viewModel.isRecording else { return }
            appState.route = .result(url: url)
        }
    }
}

struct BannerAdPlaceholder: View {
    var body: some View {
        Text("Ad Banner")
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.gray.opacity(0.3))
            .foregroundColor(.white)
    }
}

private extension CameraView {

    var durationSelector: some View {
        HStack(spacing: 12) {
            ForEach(durations, id: \.self) { duration in
                Button {
                    selectedDuration = duration
                } label: {
                    Text("\(duration)s")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(selectedDuration == duration ? .black : .white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            selectedDuration == duration
                            ? Color.white
                            : Color.white.opacity(0.2)
                        )
                        .clipShape(Capsule())
                }
                .disabled(viewModel.isRecording)
            }
        }
    }

    var recordButton: some View {
        Button {
            toggleRecording()
        } label: {
            ZStack {
                Circle()
                    .stroke(Color.white, lineWidth: 4)
                    .frame(width: 80, height: 80)

                Circle()
                    .fill(viewModel.isRecording ? Color.red : Color.white)
                    .frame(width: viewModel.isRecording ? 35 : 60,
                           height: viewModel.isRecording ? 35 : 60)
                    .animation(.easeInOut, value: viewModel.isRecording)
            }
        }
        .disabled(!viewModel.isSessionReady && !viewModel.isRecording)
    }

    var switchCameraButton: some View {
        Button {
            viewModel.switchCamera()
        } label: {
            Image(systemName: "camera.rotate")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(Color.black.opacity(0.35))
                .clipShape(Circle())
        }
        .disabled(!viewModel.isSessionReady || viewModel.isRecording)
    }

    func toggleRecording() {
        if viewModel.isRecording {
            viewModel.stop()
        } else {
            viewModel.start(duration: selectedDuration)
        }
    }
}

#Preview {
    CameraView()
}
