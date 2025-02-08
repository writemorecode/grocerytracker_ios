//
//  CameraPreviewView.swift
//  GroceryTracker
//
//  Created by Gustav Karlsson on 2025-02-08.
//

import AVFoundation
import SwiftUI

class CameraPreviewView: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        guard let layer = layer as? AVCaptureVideoPreviewLayer else {
            fatalError("Expected AVCaptureVideoPreviewLayer type for layer.")
        }
        return layer
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        videoPreviewLayer.frame = self.bounds
    }
}
