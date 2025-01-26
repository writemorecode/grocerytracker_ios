// ScanStep.swift
/// Represents the current step in the scanning process
enum ScanStep {
    case name     // Scanning product name
    case price    // Scanning price
    case barcode  // Scanning EAN barcode
    case complete // Scan process finished
    
    /// User-friendly instruction for each scanning step
    var instruction: String {
        switch self {
        case .name: return "Scan product name"
        case .price: return "Scan price"
        case .barcode: return "Scan barcode"
        case .complete: return "Scan complete!"
        }
    }
}


