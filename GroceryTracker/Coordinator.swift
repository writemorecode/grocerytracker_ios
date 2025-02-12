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
            if let productName = extractProductName(from: text) {
                DispatchQueue.main.async {
                    self.viewModel.productName = productName
                    self.viewModel.scanningMode = .none
                    self.viewModel.errorMessage = nil
                    do {
                        try self.maybeUploadScannedProduct()
                    } catch {
                        self.viewModel.errorMessage =
                            "Error: \(error.localizedDescription)"
                    }
                }
            }
        }
    }

    private func processPrice(from sampleBuffer: CMSampleBuffer) {
        processTextRecognition(from: sampleBuffer) { [weak self] text in
            guard let self = self else { return }
            if let price = extractPrice(from: text) {
                DispatchQueue.main.async {
                    self.viewModel.price = price
                    self.viewModel.scanningMode = .none
                    self.viewModel.errorMessage = nil
                    self.viewModel.errorMessage = nil
                    do {
                        try self.maybeUploadScannedProduct()
                    } catch {
                        self.viewModel.errorMessage =
                            "Error: \(error.localizedDescription)"
                    }
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
                            self.viewModel.errorMessage = nil
                            do {
                                try self.maybeUploadScannedProduct()
                            } catch {
                                self.viewModel.errorMessage =
                                    "Error: \(error.localizedDescription)"
                            }
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

    private func maybeUploadScannedProduct() throws {
        guard let name = viewModel.productName,
            let barcode = viewModel.barcode,
            let price = viewModel.price,
            let storeID = StoreManager.shared.currentStoreID,
            let coordinate = StoreManager.shared.currentStoreCoordinate
        else {
            return
        }
        let product = ProductData(
            name: name, price: price, barcode: barcode, storeID: storeID,
            latitude: coordinate.latitude, longitude: coordinate.longitude
        )
        Task {
            do {
                let response = try await NetworkManager.shared.uploadProduct(product)
                DispatchQueue.main.async {
                    self.viewModel.recentPrices = response.prices
                    self.viewModel.showRecentPrices = true
                }
            } catch {
                DispatchQueue.main.async {
                    self.viewModel.errorMessage =
                        "Error: \(error.localizedDescription)"
                }
            }
        }
    }
}
