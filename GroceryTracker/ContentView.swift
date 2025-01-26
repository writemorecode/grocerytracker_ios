// ContentView.swift
import SwiftUI
import VisionKit

/// Main view of the application
struct ContentView: View {
    // StateObject ensures the model persists across view updates
    @StateObject private var scannerModel = ScannerModel()
    @State private var isUploading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationStack {
            VStack {
                // Display current scanning instruction
                Text(scannerModel.currentStep.instruction)
                    .font(.headline)
                    .padding()
                
                // Show preview of currently scanned product
                if let product = scannerModel.currentProduct {
                    ProductPreview(product: product)
                }
                
                // Live Text scanner view if supported by device
                if DataScannerViewController.isSupported {
                    ScannerView(scannerModel: scannerModel)
                        .frame(maxHeight: 400)
                } else {
                    Text("Live Text not supported")
                        .foregroundColor(.red)
                }
                
                // Reset button appears after scan completion
                if scannerModel.currentStep == .complete {
                    Button(action: uploadProduct) {
                        HStack {
                            if isUploading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            }
                            Text("Upload Product Data")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(isUploading)
                    .padding()
                    
                }
            }
            
        }
        .navigationTitle("Product Scanner")
    }
    
    private func uploadProduct() {
        guard let product = scannerModel.currentProduct else { return }
        
        isUploading = true
        
        Task {
            do {
                try await NetworkManager.shared.uploadProduct(product)
                await MainActor.run {
                    alertMessage = "Successfully uploaded product data"
                    showAlert = true
                    isUploading = false
                }
            } catch NetworkError.httpError(let code) {
                await MainActor.run {
                    alertMessage = "Upload failed with status code: \(code)"
                    showAlert = true
                    isUploading = false
                }
            } catch {
                await MainActor.run {
                    alertMessage = "Upload failed: \(error.localizedDescription)"
                    showAlert = true
                    isUploading = false
                }
            }
        }
    }
}


