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
                
                if !cameraManager.detectedText.isEmpty {
                    Text(cameraManager.detectedText)
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding()
                        .transition(.opacity)
                        .animation(.easeInOut, value: cameraManager.detectedText)
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
