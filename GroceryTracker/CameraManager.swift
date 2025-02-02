//
//  CameraManager.swift
//  GroceryTracker
//
//  Created by Gustav Karlsson on 2025-02-02.
//

import AVFoundation
import Vision

class CameraManager: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    @Published var detectedText: String = ""
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
    
    /// Given an array of text observations from VNRecognizeTextRequest,
    /// extract the product information based on spatial criteria:
    /// - The price text is the observation with the largest bounding box area.
    /// - The barcode is a 13-digit (EAN-13) number found near the bottom-left.
    /// - The product name is located above the barcode and to the left of the price text.
    /// Returns a formatted product information string.
    func extractProductInformation(from observations: [VNRecognizedTextObservation]) -> String {
        guard !observations.isEmpty else {
            return "No product information found."
        }
        
        // Helper to calculate area of a normalized bounding box.
        func area(of observation: VNRecognizedTextObservation) -> CGFloat {
            let box = observation.boundingBox
            return box.width * box.height
        }
        
        func isCompletelyToLeft(of rect1: CGRect, comparedTo rect2: CGRect) -> Bool {
            return rect1.maxX < rect2.minX
        }
        func isCompletelyAbove(of rect1: CGRect, comparedTo rect2: CGRect) -> Bool {
            return rect1.maxY < rect2.minY
        }
        
        // 1. Find the price text: the observation with the largest bounding box.
        guard let priceObservation = observations.max(by: { area(of: $0) < area(of: $1) }),
              let priceCandidate = priceObservation.topCandidates(1).first else {
            return "Price not found."
        }
        let priceText = priceCandidate.string
        
        // 2. Find the barcode: a 13-digit number (EAN-13) located in the bottom-left.
        // Define a regex pattern for exactly 13 digits.
        let ean13Pattern = #"(?<!\d)(\d{13})(?!\d)"#
        let ean13Regex = try! NSRegularExpression(pattern: ean13Pattern, options: [])
        
        var barcodeText: String = "N/A"
        var barcodeObservation: VNRecognizedTextObservation?
        for observation in observations {
            guard let candidate = observation.topCandidates(1).first else { continue }
            let candidateText = candidate.string
            let range = NSRange(location: 0, length: candidateText.utf16.count)
            // Look for a match with our EAN-13 regex.
            if let _ = ean13Regex.firstMatch(in: candidateText, options: [], range: range) {
                barcodeText = candidateText
                barcodeObservation = observation
                break
            }
        }
        
        // 3. Find the product name: the text located above the barcode and to the left of the price.
        var productNameText: String = "N/A"
        if let barcodeObs = barcodeObservation {
            // In normalized coordinates, boundingBox.maxY is the top, and maxX is the right.
            
            // Filter observations that are strictly above the barcode and to the left of the price.
            let candidateObservations = observations.filter { obs in
                let bbox = obs.boundingBox
                guard let text = obs.topCandidates(1).first?.string else { return false }
                return !isCompletelyToLeft(of: bbox, comparedTo: priceObservation.boundingBox) &&
                !isCompletelyAbove(of: bbox, comparedTo: barcodeObs.boundingBox)
                && text != priceText && text != barcodeText
            }
            
            func stringIsPartOfProductName(s: String) -> Bool {
                s.allSatisfy { $0.isUppercase || $0 == " " || $0 == "," || $0.isNumber  }
            }
            
            productNameText = candidateObservations.compactMap { $0.topCandidates(1).first?.string }
                .map { $0.replacingOccurrences(of: "\n", with: " ")}
                .filter { stringIsPartOfProductName(s: $0)}.joined(separator: " ")
        }
        
        // Combine the information into a formatted string.
        let productInfo = """
        Product Name: '\(productNameText)'
        Price: \(priceText)
        Barcode: \(barcodeText)
        """
        
        return productInfo
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
            
            let productInfo = self?.extractProductInformation(from: observations)
            
            DispatchQueue.main.async {
                self?.detectedText = productInfo ?? "No product info found"
            }
        }
        
        request.recognitionLevel = .accurate
        
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
            .perform([request])
    }
}
