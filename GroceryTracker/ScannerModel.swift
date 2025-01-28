import Foundation
import VisionKit

class ScannerModel: ObservableObject {
    @Published var currentStep: ScanStep = .name
    @Published var currentProduct: ProductData?
    
    private var scannedName: String?
    private var scannedPrice: Double?
    private var scannedBarcode: String?
    
    func processScannedText(_ text: String) {
        switch currentStep {
        case .name:
            handleNameScan(text)
        case .price:
            handlePriceScan(text)
        case .barcode:
            handleBarcodeScan(text)
        case .complete:
            break
        }
    }
    
    private func handleNameScan(_ text: String) {
        scannedName = extractProductName(from: text)
        currentStep = .price
        updateCurrentProduct()
    }
    
    private func handlePriceScan(_ text: String) {
        guard let price = extractPrice(from: text) else { return }
        scannedPrice = price
        currentStep = .barcode
        updateCurrentProduct()
    }
    
    private func handleBarcodeScan(_ text: String) {
        guard isValidEAN(text) else { return }
        scannedBarcode = text
        finalizeProduct()
    }
    
    private func extractProductName(from text: String) -> String {
        // Matches any number of consecutive space-separated uppercase-only words
        let re = /\b[A-Z]+\b(?:\s+[A-Z]+)+\b/
        if let match = text.firstMatch(of: re) {
            return String(text[match.range])
        } else { return text }
    }
    
    private func extractPrice(from text: String) -> Double? {
        let re = /\d+[\.\,]\d{1,2}/
        guard let match = text.firstMatch(of: re) else { return nil }
        var matchString = String(text[match.range])
        if let price = Double(matchString) { return price }
        matchString.replace(".", with: ",")
        return Double(matchString)
    }
    
    private func isValidEAN(_ code: String) -> Bool {
        code.filter { $0.isNumber }.count == 13
    }
    
    private func updateCurrentProduct() {
        currentProduct = ProductData(
            name: scannedName ?? "",
            price: scannedPrice ?? 0,
            barcode: scannedBarcode ?? "",
            storeID: StoreManager.shared.currentStoreID ?? 0
        )
    }
    
    private func finalizeProduct() {
        guard let name = scannedName,
              let price = scannedPrice,
              let barcode = scannedBarcode,
              let storeID = StoreManager.shared.currentStoreID
        else {
            resetScan()
            return
        }
        
        currentProduct = ProductData(
            name: name,
            price: price,
            barcode: barcode,
            storeID: storeID
        )
        currentStep = .complete
    }
    
    func resetScan() {
        currentStep = .name
        scannedName = nil
        scannedPrice = nil
        scannedBarcode = nil
        currentProduct = nil
    }
}
