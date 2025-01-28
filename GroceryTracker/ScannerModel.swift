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
        scannedName = text.trimmingCharacters(in: .whitespacesAndNewlines)
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
    
    private func extractPrice(from text: String) -> Double? {
        let numbers = text.filter { $0.isNumber }
        guard numbers.count >= 3, let value = Int(numbers) else { return nil }
        return Double(value) / 100.0
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
