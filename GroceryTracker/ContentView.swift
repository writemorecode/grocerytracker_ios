import Foundation
import SwiftUI
import AVFoundation
import Vision

struct ContentView: View {
    @StateObject private var cameraManager = CameraManager()
    @State private var isShowingPermissionAlert = false
    
    var body: some View {
        ZStack {
            CameraPreview(session: cameraManager.session, cameraManager: cameraManager)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                Spacer()
                
                if let product = cameraManager.parsedProduct {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name: \(product.name)")
                        let priceString = product.price.formatted()
                        let currencySymbol = Locale.current.currencySymbol ?? ""
                        Text("Price: \(priceString) \(currencySymbol)")
                        Text("Barcode: \(product.barcode)")
                    }
                    .padding()
                    .background(Color.black)
                    .cornerRadius(8)
                    .padding(.horizontal)
                }

                Button(action: {
                    cameraManager.captureText()
                }) {
                    Text("Capture Text")
                        .foregroundColor(.white)
                        .padding()
                        .frame(width: 200)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.bottom, 30)
            }
        }
        .onAppear {
            checkCameraPermission()
        }
        .alert("Camera Permission Required", isPresented: $isShowingPermissionAlert) {
            Button("Go to Settings", role: .none) {
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This app needs camera access to detect text. Please grant permission in Settings.")
        }
    }
    
    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            break
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if !granted {
                    isShowingPermissionAlert = true
                }
            }
        default:
            isShowingPermissionAlert = true
        }
    }
}
