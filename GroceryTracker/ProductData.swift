// ProductData.swift
import Foundation

/// Represents a scanned product with its essential details
struct ProductData:  Codable {
    var name: String    // Product name from label
    var price: Double   // Price in decimal format
    var barcode: String // EAN-13 barcode
    var storeID: Int
}

