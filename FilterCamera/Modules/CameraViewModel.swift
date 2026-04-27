//
//  CameraViewModel.swift
//  FilterCamera
//
//  Created by binh on 27/4/26.
//

import Foundation

@MainActor
final class CameraViewModel: ObservableObject {

    let service = CameraService()

    @Published var isRecording = false
    @Published var recordedURL: URL?
    @Published var remainingTime: Int = 15
    @Published var alertMessage: String?
    @Published var isSessionReady = false

    private var countdownTask: Task<Void, Never>?

    func setup() {
        service.onFinish = { [weak self] url in
            guard let self else { return }

            self.recordedURL = url
            self.stopCountdown(resetTo: nil)
        }

        service.onRecordingStateChanged = { [weak self] isRecording in
            guard let self else { return }
            self.isRecording = isRecording
            if !isRecording {
                self.stopCountdown(resetTo: nil)
            }
        }

        service.onSetupError = { [weak self] message in
            self?.alertMessage = message
        }

        service.onLibrarySaveError = { [weak self] message in
            self?.alertMessage = message
        }

        service.onSetupCompleted = { [weak self] in
            self?.isSessionReady = true
        }

        service.setupSession()
    }

    func start(duration: Int) {
        remainingTime = duration
        service.startRecording(duration: duration)
        startCountdown(duration: duration)
    }

    func stop() {
        service.stopRecording()
        stopCountdown(resetTo: nil)
    }

    func switchCamera() {
        service.switchCamera()
    }

    func clearAlert() {
        alertMessage = nil
    }
}

private extension CameraViewModel {

    func startCountdown(duration: Int) {
        countdownTask?.cancel()
        countdownTask = Task { [weak self] in
            guard let self else { return }

            for seconds in stride(from: duration, through: 0, by: -1) {
                if Task.isCancelled { return }
                self.remainingTime = seconds
                if seconds == 0 { return }

                try? await Task.sleep(for: .seconds(1))
            }
        }
    }

    func stopCountdown(resetTo value: Int?) {
        countdownTask?.cancel()
        countdownTask = nil

        if let value {
            remainingTime = value
        }
    }
}
