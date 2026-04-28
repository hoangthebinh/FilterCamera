//
//  ResultViewModel.swift
//  FilterCamera
//
//  Created by binh on 28/4/26.
//

import AVFoundation
import CoreImage
import CoreImage.CIFilterBuiltins
import Photos

enum SaveState {
    case idle
    case success
    case error(String)
}

@MainActor
final class ResultViewModel: ObservableObject {
    @Published var saveState: SaveState = .idle
    @Published var showAlert: Bool = false
    
    func saveVideoToPhotoLibrary(from url: URL) async {
        let authorizationStatus = await requestPhotoLibraryAccess()
        guard authorizationStatus == .authorized || authorizationStatus == .limited else {
            notifyLibrarySaveError("Photo library access was denied.")
            return
        }

        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            }
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            }) { success, error in
                DispatchQueue.main.async { [weak self] in
                    guard let self = self, success else { return }
                    self.showAlert = true
                    self.saveState = .success
                }
            }
        } catch {
            notifyLibrarySaveError("Failed to save video to Photo Library.")
        }
    }

    func requestPhotoLibraryAccess() async -> PHAuthorizationStatus {
        let currentStatus = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        switch currentStatus {
        case .notDetermined:
            return await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        default:
            return currentStatus
        }
    }
    
    func notifyLibrarySaveError(_ message: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.showAlert = true
            self.saveState = .error(message)
        }
    }
}
