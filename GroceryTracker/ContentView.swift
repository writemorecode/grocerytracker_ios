import SwiftUI
import AVFoundation
import Vision

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    let cameraManager: CameraManager
    
    class VideoPreviewView: UIView {
        override class var layerClass: AnyClass {
            AVCaptureVideoPreviewLayer.self
        }
        
        var previewLayer: AVCaptureVideoPreviewLayer {
            layer as! AVCaptureVideoPreviewLayer
        }
        
    }
    
    func makeUIView(context: Context) -> VideoPreviewView {
        let view = VideoPreviewView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        view.backgroundColor = .black
        cameraManager.previewView = view
        return view
    }
    
    func updateUIView(_ uiView: VideoPreviewView, context: Context) {
        uiView.previewLayer.frame = uiView.bounds
    }
}

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
