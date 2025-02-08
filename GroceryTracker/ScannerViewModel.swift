//
//  ScannerViewModel.swift
//  GroceryTracker
//
//  Created by Gustav Karlsson on 2025-02-08.
//

import Foundation

class ScannerViewModel: ObservableObject {
    enum ScanningMode {
        case none, name, price, barcode
    }

    @Published var errorMessage: String? = nil
    @Published var productName: String? = nil
    @Published var price: String? = nil
    @Published var barcode: String? = nil
    @Published var scanningMode: ScanningMode = .none
}
