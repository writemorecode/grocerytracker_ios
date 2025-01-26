// ScannerView.swift
import SwiftUI
import VisionKit

struct ScannerView: UIViewControllerRepresentable {
    @ObservedObject var scannerModel: ScannerModel
    
    func makeUIViewController(context: Context) -> DataScannerViewController {
        // Initialize with both text and barcode recognition
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.text(), .barcode(symbologies: [.ean13])],
            qualityLevel: .accurate,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: true,
            isPinchToZoomEnabled: true
        )
        
        scanner.delegate = context.coordinator
        try? scanner.startScanning()
        return scanner
    }
    
    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        // No need to recreate the scanner
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        var parent: ScannerView
        
        init(_ parent: ScannerView) {
            self.parent = parent
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            // Only process the type we're currently looking for
            switch parent.scannerModel.currentStep {
            case .name, .price:
                if case .text(let text) = item {
                    parent.scannerModel.processScannedText(text.transcript)
                }
            case .barcode:
                if case .barcode(let barcode) = item,
                   let value = barcode.payloadStringValue {
                    parent.scannerModel.processScannedText(value)
                }
            case .complete:
                break
            }
        }
    }
}
