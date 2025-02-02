//
//  CameraManager.swift
//  GroceryTracker
//
//  Created by Gustav Karlsson on 2025-02-02.
//

import AVFoundation
import Vision

class CameraManager: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    @Published var parsedProduct: ProductData? = nil
    let session = AVCaptureSession()
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private var shouldCaptureText = false
    weak var previewView: CameraPreview.VideoPreviewView?
    
    override init() {
        super.init()
        setupCamera()
    }
    
    func captureText() {
        shouldCaptureText = true
    }
    
    private func setupCamera() {
        session.sessionPreset = .high
        
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                        for: .video,
                                                        position: .back),
              let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            return
        }
        
        guard session.canAddInput(videoDeviceInput) else { return }
        session.addInput(videoDeviceInput)
        
        videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "VideoDataOutput"))
        guard session.canAddOutput(videoDataOutput) else { return }
        session.addOutput(videoDataOutput)
        
        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.session.startRunning()
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard shouldCaptureText,
              let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
              let previewView = previewView else {
            return
        }
        
        shouldCaptureText = false
        
        let request = VNRecognizeTextRequest { [weak self] request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation],
                  !observations.isEmpty else { return }
            
            let productInfo = extractProductInformation(from: observations)
            
            DispatchQueue.main.async {
                self?.parsedProduct = productInfo
            }
        }
        
        request.recognitionLevel = .accurate
        
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
            .perform([request])
    }
}
