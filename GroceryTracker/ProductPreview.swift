import SwiftUI

// ProductPreview.swift
/// Preview card for currently scanned product
struct ProductPreview: View {
    let product: ProductData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Name: \(product.name)")
            
            let priceString = String(format: "%.2f", product.price)
            let currencySymbol = Locale.current.currencySymbol ?? ""
            Text("Price: \(priceString) \(currencySymbol)")
            
            Text("Barcode: \(product.barcode)")
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}

