//
//  CameraService.swift
//  FilterCamera
//
//  Created by binh on 27/4/26.
//

import AVFoundation
import CoreImage
import CoreImage.CIFilterBuiltins
import Photos

final class CameraService: NSObject {

    enum SetupError: LocalizedError {
        case cameraPermissionDenied
        case microphonePermissionDenied
        case cameraUnavailable
        case cannotAddVideoInput
        case cannotAddVideoOutput
        case writerUnavailable

        var errorDescription: String? {
            switch self {
            case .cameraPermissionDenied:
                "Camera access was denied."
            case .microphonePermissionDenied:
                "Microphone access was denied."
            case .cameraUnavailable:
                "No camera device is available."
            case .cannotAddVideoInput:
                "The camera input could not be attached to the capture session."
            case .cannotAddVideoOutput:
                "The camera output could not be attached to the capture session."
            case .writerUnavailable:
                "The recording pipeline could not be created."
            }
        }
    }

    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")

    private let videoOutput = AVCaptureVideoDataOutput()
    private let audioOutput = AVCaptureAudioDataOutput()

    private let ciContext = CIContext()
    private var currentFilter: CIFilter?

    private var writer: AVAssetWriter?
    private var videoInput: AVAssetWriterInput?
    private var audioInput: AVAssetWriterInput?
    private var adaptor: AVAssetWriterInputPixelBufferAdaptor?
    private var hasStartedWritingSession = false
    private var isSessionConfigured = false
    private var isSessionRunning = false
    private var preferredCameraPosition: AVCaptureDevice.Position = .front

    private(set) var isRecording = false
    private var startTime: CMTime?
    private var duration: Int = 15

    var onFinish: ((URL) -> Void)?
    var onPreviewBuffer: ((CMSampleBuffer) -> Void)?
    var onRecordingStateChanged: ((Bool) -> Void)?
    var onSetupError: ((String) -> Void)?
    var onLibrarySaveError: ((String) -> Void)?
    var onSetupCompleted: (() -> Void)?

    deinit {
        stopSession()
    }
}

extension CameraService {

    func setupSession() {
        Task {
            do {
                try await requestPermissions()
                configureSessionIfNeeded()
            } catch {
                notifySetupError(error)
            }
        }
    }

    func stopSession() {
        sessionQueue.async {
            self.stopRecordingIfNeeded()

            guard self.isSessionRunning else { return }

            self.session.stopRunning()
            self.isSessionRunning = false
        }
    }

    func switchCamera() {
        sessionQueue.async {
            guard self.isSessionConfigured, !self.isRecording else { return }

            self.preferredCameraPosition = self.preferredCameraPosition == .front ? .back : .front

            do {
                try self.configureSession()
            } catch {
                self.preferredCameraPosition = self.preferredCameraPosition == .front ? .back : .front
                self.notifySetupError(error)
                return
            }

            if !self.isSessionRunning {
                self.session.startRunning()
                self.isSessionRunning = true
            }
        }
    }
}

private extension CameraService {

    func requestPermissions() async throws {
        let cameraGranted = await requestAccess(for: .video)
        guard cameraGranted else {
            throw SetupError.cameraPermissionDenied
        }

        let microphoneGranted = await requestAccess(for: .audio)
        guard microphoneGranted else {
            throw SetupError.microphonePermissionDenied
        }
    }

    func requestAccess(for mediaType: AVMediaType) async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: mediaType) {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: mediaType)
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }

    func configureSessionIfNeeded() {
        sessionQueue.async {
            guard !self.isSessionConfigured else {
                if !self.isSessionRunning {
                    self.session.startRunning()
                    self.isSessionRunning = true
                }
                return
            }

            do {
                try self.configureSession()
            } catch {
                self.notifySetupError(error)
                return
            }

            self.isSessionConfigured = true
            self.session.startRunning()
            self.isSessionRunning = true

            DispatchQueue.main.async {
                self.onSetupCompleted?()
            }
        }
    }

    func configureSession() throws {
        session.beginConfiguration()
        defer { session.commitConfiguration() }

        session.sessionPreset = .high

        try configureInputs()
        try configureOutputs()
    }

    func configureInputs() throws {
        session.inputs.forEach { session.removeInput($0) }

        let requestedPosition = preferredCameraPosition
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                        for: .video,
                                                        position: requestedPosition) ??
                                AVCaptureDevice.default(for: .video) else {
            throw SetupError.cameraUnavailable
        }

        let videoInput = try AVCaptureDeviceInput(device: videoDevice)
        guard session.canAddInput(videoInput) else {
            throw SetupError.cannotAddVideoInput
        }
        session.addInput(videoInput)

        if let audioDevice = AVCaptureDevice.default(for: .audio),
           let audioInput = try? AVCaptureDeviceInput(device: audioDevice),
           session.canAddInput(audioInput) {
            session.addInput(audioInput)
        }
    }

    func configureOutputs() throws {
        session.outputs.forEach { session.removeOutput($0) }

        videoOutput.setSampleBufferDelegate(self, queue: sessionQueue)
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]

        guard session.canAddOutput(videoOutput) else {
            throw SetupError.cannotAddVideoOutput
        }
        session.addOutput(videoOutput)

        audioOutput.setSampleBufferDelegate(self, queue: sessionQueue)
        if session.canAddOutput(audioOutput) {
            session.addOutput(audioOutput)
        }
    }

    func notifySetupError(_ error: Error) {
        let message: String
        if let setupError = error as? SetupError {
            message = setupError.localizedDescription
        } else {
            message = error.localizedDescription
        }

        DispatchQueue.main.async {
            self.onSetupError?(message)
        }
    }

    func notifyLibrarySaveError(_ message: String) {
        DispatchQueue.main.async {
            self.onLibrarySaveError?(message)
        }
    }

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
}

extension CameraService {

    func startRecording(duration: Int) {
        sessionQueue.async {
            guard self.isSessionConfigured, self.isSessionRunning, !self.isRecording else { return }

            self.duration = duration
            self.startTime = nil
            self.hasStartedWritingSession = false

            self.generateRandomFilter()
            guard self.setupWriter() else {
                self.notifySetupError(SetupError.writerUnavailable)
                return
            }

            self.setRecordingState(true)
        }
    }

    func stopRecording() {
        sessionQueue.async {
            self.stopRecordingIfNeeded()
        }
    }
}

private extension CameraService {

    func stopRecordingIfNeeded() {
        guard isRecording else { return }

        setRecordingState(false)
        hasStartedWritingSession = false

        videoInput?.markAsFinished()
        audioInput?.markAsFinished()

        let currentWriter = writer
        let outputURL = currentWriter?.outputURL

        currentWriter?.finishWriting { [weak self] in
            guard let self else { return }
            self.resetWriter()

            guard let outputURL else { return }
            DispatchQueue.main.async {
                self.onFinish?(outputURL)
            }

            Task {
                await self.saveVideoToPhotoLibrary(from: outputURL)
            }
        }
    }

    func setRecordingState(_ isRecording: Bool) {
        self.isRecording = isRecording

        DispatchQueue.main.async {
            self.onRecordingStateChanged?(isRecording)
        }
    }

    @discardableResult
    func setupWriter() -> Bool {
        resetWriter()

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".mp4")

        guard let writer = try? AVAssetWriter(outputURL: url, fileType: .mp4) else {
            return false
        }

        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: 720,
            AVVideoHeightKey: 1280
        ]

        let videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        videoInput.expectsMediaDataInRealTime = true

        guard writer.canAdd(videoInput) else {
            return false
        }
        writer.add(videoInput)

        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: videoInput,
            sourcePixelBufferAttributes: nil
        )

        let audioSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVNumberOfChannelsKey: 1,
            AVSampleRateKey: 44100,
            AVEncoderBitRateKey: 64000
        ]

        let audioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
        audioInput.expectsMediaDataInRealTime = true

        if writer.canAdd(audioInput) {
            writer.add(audioInput)
        }

        guard writer.startWriting() else {
            return false
        }

        self.writer = writer
        self.videoInput = videoInput
        self.audioInput = audioInput
        self.adaptor = adaptor
        return true
    }

    func resetWriter() {
        writer = nil
        videoInput = nil
        audioInput = nil
        adaptor = nil
        startTime = nil
        hasStartedWritingSession = false
    }
}

extension CameraService {

    private func generateRandomFilter() {
        let filters: [CIFilter] = [
            CIFilter.sepiaTone(),
            CIFilter.photoEffectNoir(),
            CIFilter.colorInvert()
        ]

        currentFilter = filters.randomElement()
    }

    private func applyFilter(to image: CIImage) -> CIImage {
        guard let filter = currentFilter else { return image }
        filter.setValue(image, forKey: kCIInputImageKey)
        return filter.outputImage ?? image
    }

    private func preparedImage(from pixelBuffer: CVPixelBuffer) -> CIImage {
        let image = CIImage(cvPixelBuffer: pixelBuffer)

        // rotate portrait
        var output = image.oriented(.right)

        output = applyFilter(to: output)

        if preferredCameraPosition == .front {
            output = output
                .transformed(by: CGAffineTransform(scaleX: -1, y: 1)
                    .translatedBy(x: -output.extent.width, y: 0))
        }

        return output
    }
}

extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate,
                         AVCaptureAudioDataOutputSampleBufferDelegate {

    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        if output == videoOutput {
            processVideo(sampleBuffer: sampleBuffer)
        }

        if output == audioOutput, isRecording {
            processAudio(sampleBuffer: sampleBuffer)
        }
    }
}

private extension CameraService {

    func processVideo(sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        let processedImage = preparedImage(from: pixelBuffer)

        if let previewSampleBuffer = makePreviewSampleBuffer(from: processedImage, presentationTime: time) {
            DispatchQueue.main.async {
                self.onPreviewBuffer?(previewSampleBuffer)
            }
        }

        guard isRecording else { return }
        guard let pool = adaptor?.pixelBufferPool else { return }

        if !hasStartedWritingSession {
            guard writer?.status == .writing else { return }
            writer?.startSession(atSourceTime: time)
            startTime = time
            hasStartedWritingSession = true
        }

        guard let buffer = makePixelBuffer(from: processedImage, using: pool) else { return }

        if videoInput?.isReadyForMoreMediaData == true {
            adaptor?.append(buffer, withPresentationTime: time)
        }

        if let startTime {
            let elapsed = CMTimeGetSeconds(time - startTime)
            if elapsed >= Double(duration) {
                stopRecordingIfNeeded()
            }
        }
    }

    func processAudio(sampleBuffer: CMSampleBuffer) {
        guard hasStartedWritingSession else { return }
        guard let audioInput, audioInput.isReadyForMoreMediaData else { return }

        audioInput.append(sampleBuffer)
    }

    func makePixelBuffer(from image: CIImage, using pool: CVPixelBufferPool) -> CVPixelBuffer? {

        var pixelBuffer: CVPixelBuffer?
        CVPixelBufferPoolCreatePixelBuffer(nil, pool, &pixelBuffer)

        guard let pixelBuffer else { return nil }

        let targetWidth = CVPixelBufferGetWidth(pixelBuffer)
        let targetHeight = CVPixelBufferGetHeight(pixelBuffer)

        let imageWidth = image.extent.width
        let imageHeight = image.extent.height

        // 🔥 tính scale giữ tỉ lệ
        let scale = min(
            CGFloat(targetWidth) / imageWidth,
            CGFloat(targetHeight) / imageHeight
        )

        let scaled = image.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        // 🔥 center image (không crop)
        let x = (CGFloat(targetWidth) - scaled.extent.width) / 2
        let y = (CGFloat(targetHeight) - scaled.extent.height) / 2

        let centered = scaled.transformed(by: CGAffineTransform(translationX: x, y: y))

        ciContext.render(centered, to: pixelBuffer)

        return pixelBuffer
    }

    func makePreviewSampleBuffer(from image: CIImage, presentationTime: CMTime) -> CMSampleBuffer? {
        let width = Int(image.extent.width)
        let height = Int(image.extent.height)
        guard width > 0, height > 0 else { return nil }

        let attributes: [CFString: Any] = [
            kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey: width,
            kCVPixelBufferHeightKey: height,
            kCVPixelBufferIOSurfacePropertiesKey: [:]
        ]

        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                         width,
                                         height,
                                         kCVPixelFormatType_32BGRA,
                                         attributes as CFDictionary,
                                         &pixelBuffer)
        guard status == kCVReturnSuccess, let pixelBuffer else { return nil }

        ciContext.render(image, to: pixelBuffer)

        var formatDescription: CMFormatDescription?
        guard CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault,
                                                           imageBuffer: pixelBuffer,
                                                           formatDescriptionOut: &formatDescription) == noErr,
              let formatDescription else {
            return nil
        }

        var timing = CMSampleTimingInfo(duration: .invalid,
                                        presentationTimeStamp: presentationTime,
                                        decodeTimeStamp: .invalid)
        var sampleBuffer: CMSampleBuffer?
        guard CMSampleBufferCreateReadyWithImageBuffer(allocator: kCFAllocatorDefault,
                                                       imageBuffer: pixelBuffer,
                                                       formatDescription: formatDescription,
                                                       sampleTiming: &timing,
                                                       sampleBufferOut: &sampleBuffer) == noErr else {
            return nil
        }

        return sampleBuffer
    }
}
