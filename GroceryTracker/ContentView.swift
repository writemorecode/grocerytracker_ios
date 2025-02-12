import AVFoundation
import SwiftUI
import Vision

struct ContentView: View {
    @StateObject var viewModel = ScannerViewModel()

    var body: some View {
        VStack(spacing: 20) {
            // Camera preview view
            CameraView(viewModel: viewModel)
                .frame(height: 400)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray, lineWidth: 1)
                )
                .padding()

            // Buttons to trigger scanning steps
            HStack(spacing: 20) {
                Button("Scan Shelf Label") {
                    // Trigger text recognition on the next frame.
                    viewModel.scanningMode = .name
                }
                .buttonStyle(.borderedProminent)

                Button("Scan Price") {
                    // Trigger text recognition on the next frame.
                    viewModel.scanningMode = .price
                }
                .buttonStyle(.borderedProminent)

                Button("Scan Barcode") {
                    // Trigger barcode detection on the next frame.
                    viewModel.scanningMode = .barcode
                }
                .buttonStyle(.borderedProminent)
            }

            // Display the scanning results
            VStack(alignment: .leading, spacing: 10) {
                if let productName = viewModel.productName {
                    Text("Product Name: \(productName)")
                }
                if let price = viewModel.price {
                    Text("Price: \(price)")
                }
                if let barcode = viewModel.barcode {
                    Text("Barcode: \(barcode)")
                }
                if let errorMessage = viewModel.errorMessage {
                    Text("Error: \(errorMessage)")
                        .foregroundColor(.red)
                }
            }
            .padding()

            Spacer()
        }
        .sheet(isPresented: $viewModel.showRecentPrices) {
            if let recentPrices = viewModel.recentPrices {
                RecentPricesView(prices: recentPrices)
            }
        }
    }
}
