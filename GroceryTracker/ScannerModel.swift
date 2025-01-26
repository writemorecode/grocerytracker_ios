// ScannerModel.swift
import Foundation
import VisionKit

/// Manages the scanning process and data
class ScannerModel: ObservableObject {
    // Published properties for view updates
    @Published var currentStep: ScanStep = .name
    @Published var currentProduct: ProductData?
    
    // Temporary storage for building product data
    private var tempName: String = ""
    private var tempPrice: Double = 0.0
    private var tempBarcode: String = ""
    
    /// Process scanned text based on current step
    /// - Parameter text: The text recognized by the scanner
    func processScannedText(_ text: String) {
        switch currentStep {
        case .name:
            tempName = text
            currentStep = .price
            updateCurrentProduct()
            
        case .price:
            if let price = extractPrice(from: text) {
                tempPrice = price
                currentStep = .barcode
                updateCurrentProduct()
            }
            
        case .barcode:
            if isValidEAN(text) {
                tempBarcode = text
                finalizeProduct()
            }
            
        case .complete:
            break
        }
    }
    
    /// Extract price value from scanned text
    /// - Parameter text: Text containing price
    /// - Returns: Decimal price if found, nil otherwise
    private func extractPrice(from text: String) -> Double? {
        // Extract digits only
        let numbers = text.filter { $0.isNumber }
        
        // Need at least 3 digits for a valid price (e.g. 100 = $1.00)
        guard numbers.count >= 3 else { return nil }
        
        // Convert string to decimal
        guard let value = Int(numbers) else { return nil }
        
        // Move decimal point two places left
        return Double(value) / 100.0
    }
    
    /// Validate EAN-13 barcode format
    /// - Parameter code: Scanned barcode string
    /// - Returns: True if valid EAN-13 format
    private func isValidEAN(_ code: String) -> Bool {
        let cleaned = code.filter { $0.isNumber }
        return cleaned.count == 13
    }
    
    /// Update current product with scanned data
    private func updateCurrentProduct() {
        currentProduct = ProductData(name: tempName, price: tempPrice, barcode: tempBarcode , storeID: StoreManager.shared.currentStoreID ?? 0)
    }
    
    /// Finalize product scanning and add to history
    private func finalizeProduct() {
        let product = ProductData(name: tempName, price: tempPrice, barcode: tempBarcode, storeID: StoreManager.shared.currentStoreID ?? 0)
        currentProduct = product
        currentStep = .complete
    }
    
    /// Reset scanner for new product
    func resetScan() {
        currentStep = .name
        tempName = ""
        tempPrice = 0.0
        tempBarcode = ""
        currentProduct = nil
    }
}
