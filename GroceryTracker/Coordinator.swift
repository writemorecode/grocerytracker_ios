//
//  Coordinator.swift
//  GroceryTracker
//
//  Created by Gustav Karlsson on 2025-02-08.
//

import AVFoundation
import SwiftUI
import Vision

class Coordinator: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    var viewModel: ScannerViewModel
    var session: AVCaptureSession?
    /// Flag to avoid processing multiple frames simultaneously.
    var isProcessing = false

    init(viewModel: ScannerViewModel) {
        self.viewModel = viewModel
        super.init()
    }

    func setupCamera(in view: CameraPreviewView) {
        session = AVCaptureSession()
        session?.sessionPreset = .photo

        guard let captureDevice = AVCaptureDevice.default(for: .video),
            let input = try? AVCaptureDeviceInput(device: captureDevice),
            session?.canAddInput(input) == true
        else { return }
        session?.addInput(input)

        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String:
                kCVPixelFormatType_32BGRA
        ]
        videoOutput.setSampleBufferDelegate(
            self, queue: DispatchQueue(label: "videoQueue"))
        if session?.canAddOutput(videoOutput) == true {
            session?.addOutput(videoOutput)
        }

        // Link the session to the preview view
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill

        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.session?.startRunning()
        }
    }

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        // Only process if a scanning mode is set and not already processing.
        guard viewModel.scanningMode != .none, !isProcessing else { return }
        isProcessing = true

        switch viewModel.scanningMode {
        case .name:
            processProductName(from: sampleBuffer)
        case .price:
            processPrice(from: sampleBuffer)
        case .barcode:
            processBarcode(from: sampleBuffer)
        case .none:
            isProcessing = false
        }
    }
}

extension Coordinator {
    private func processTextRecognition(
        from sampleBuffer: CMSampleBuffer,
        completion: @escaping (String) -> Void
    ) {
        let request = VNRecognizeTextRequest { [weak self] request, error in
            guard let self = self else { return }

            if let error = error {
                self.handleTextRecognitionError(error)
                return
            }

            guard
                let observations = request.results
                    as? [VNRecognizedTextObservation]
            else {
                DispatchQueue.main.async {
                    self.viewModel.errorMessage = "No text recognized"
                    self.viewModel.scanningMode = .none
                    self.isProcessing = false
                }
                return
            }

            let recognizedText = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }

            let text = recognizedText.joined(separator: " ")
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "\n", with: "")
            completion(text)

            self.isProcessing = false
        }

        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["sv-SE"]

        do {
            try VNImageRequestHandler(
                cmSampleBuffer: sampleBuffer, orientation: .up
            ).perform([
                request
            ])
        } catch {
            handleTextRecognitionError(error)
        }
    }

    private func processProductName(from sampleBuffer: CMSampleBuffer) {
        processTextRecognition(from: sampleBuffer) { [weak self] text in
            guard let self = self else { return }
            let productName = self.extractProductName(from: text)
            DispatchQueue.main.async {
                self.viewModel.productName = productName
                self.viewModel.scanningMode = .none
            }
        }
    }

    private func processPrice(from sampleBuffer: CMSampleBuffer) {
        processTextRecognition(from: sampleBuffer) { [weak self] text in
            guard let self = self else { return }
            if let price = self.extractPrice(from: text) {
                DispatchQueue.main.async {
                    self.viewModel.price = price
                    self.viewModel.scanningMode = .none
                }
            } else {
                DispatchQueue.main.async {
                    self.viewModel.errorMessage = "No price found"
                    self.viewModel.scanningMode = .none
                }
            }
        }
    }

    private func handleTextRecognitionError(_ error: Error) {
        DispatchQueue.main.async {
            self.viewModel.errorMessage = "Error: \(error.localizedDescription)"
            self.viewModel.scanningMode = .none
        }
        self.isProcessing = false
    }

    private func extractProductName(from text: String) -> String {
        let pattern = /([A-Ö, ]+(?:\d+[GP])?[A-Ö, ]+)/
        if let match = text.firstMatch(of: pattern) {
            let name = String(text[match.range])
            return name
        }
        return ""
    }

    private func extractPrice(from text: String) -> Decimal? {
        let p = /([€$]?\\s?\\d+[.,]?\\d{1,2})/
        if let match = text.firstMatch(of: p) {
            let text = String(text[match.range])
            if let price = Decimal(string: text) {
                return price / 100
            }
        }
        return nil
    }

    private func processBarcode(from sampleBuffer: CMSampleBuffer) {
        let request = VNDetectBarcodesRequest { request, error in
            if let error = error {
                self.handleTextRecognitionError(error)
                return
            }

            if let results = request.results {
                for result in results {
                    if let barcodeObservation = result as? VNBarcodeObservation,
                        barcodeObservation.symbology == .ean13,
                        let payload = barcodeObservation.payloadStringValue
                    {
                        DispatchQueue.main.async {
                            self.viewModel.barcode = payload
                            self.viewModel.scanningMode = .none
                        }
                        self.isProcessing = false
                        return
                    }
                }
            }

            DispatchQueue.main.async {
                self.viewModel.errorMessage = "No EAN-13 barcode found"
                self.viewModel.scanningMode = .none
            }
            self.isProcessing = false
        }

        let handler = VNImageRequestHandler(
            cmSampleBuffer: sampleBuffer,
            orientation: .up,
            options: [:])
        do {
            try handler.perform([request])
        } catch {
            handleTextRecognitionError(error)
        }
    }
}
