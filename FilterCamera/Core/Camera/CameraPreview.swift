//
//  CameraPreview.swift
//  FilterCamera
//
//  Created by binh on 27/4/26.
//

import AVFoundation
import SwiftUI
import UIKit

struct CameraPreview: UIViewRepresentable {

    let service: CameraService

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        service.onPreviewBuffer = { [weak view] sampleBuffer in
            view?.enqueue(sampleBuffer)
        }
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        uiView.sampleBufferDisplayLayer.frame = uiView.bounds
    }
}

final class PreviewView: UIView {

    override class var layerClass: AnyClass {
        AVSampleBufferDisplayLayer.self
    }

    var sampleBufferDisplayLayer: AVSampleBufferDisplayLayer {
        layer as! AVSampleBufferDisplayLayer
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        sampleBufferDisplayLayer.videoGravity = .resizeAspectFill
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func enqueue(_ sampleBuffer: CMSampleBuffer) {
        if sampleBufferDisplayLayer.status == .failed {
            sampleBufferDisplayLayer.flush()
        }

        sampleBufferDisplayLayer.enqueue(sampleBuffer)
    }
}
