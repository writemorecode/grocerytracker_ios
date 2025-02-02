//
//  ProductLabelParser.swift
//  GroceryTracker
//
//  Created by Gustav Karlsson on 2025-02-02.
//

import Foundation
import AVFoundation
import Vision

/// Given an array of text observations from VNRecognizeTextRequest,
/// extract the product information based on spatial criteria:
/// - The price text is the observation with the largest bounding box area.
/// - The barcode is a 13-digit (EAN-13) number found near the bottom-left.
/// - The product name is located above the barcode and to the left of the price text.
/// Returns a formatted product information string.
func extractProductInformation(from observations: [VNRecognizedTextObservation]) -> ProductData? {
    guard !observations.isEmpty else {
        return nil
    }
    guard let storeID = StoreManager.shared.currentStoreID  else { return nil }
    
    guard let (priceBbox, priceText) = extractProductPrice(
        observations: observations) else {
        print("Failed to extract price")
        return nil
    }
    guard let (barcodeBbox, barcodeText)  = extractBarcode(
        observations: observations) else { 
        print("Failed to extract barcode")
        return nil }
    guard let productNameText = extractProductName(
        observations: observations,
        priceBbox: priceBbox,
        barcodeBbox: barcodeBbox,
        priceString: priceText,
        barcodeString: barcodeText
    ) else { 
        print("Failed to extract product name")
        return nil }
    guard let price = parseNumberString(priceText) else { print("Failed to parse price to decimal value")
        return nil }
    let productData = ProductData(name: productNameText , price: price, barcode: barcodeText ,
                                  storeID: storeID)
    print("\n\n\n\n")
    return productData
}

private func extractProductPrice(observations: [VNRecognizedTextObservation]) -> (CGRect , String)? {
    guard let priceObservation = observations.max(by: { area(of: $0) < area(of: $1) }),
          let priceCandidate = priceObservation.topCandidates(1).first?.string else {
        return nil
    }
    print("Price text: \(priceCandidate)")
    return (priceObservation.boundingBox , priceCandidate)
}

func parseNumberString(_ string: String) -> Decimal? {
    guard let intValue = Decimal(string: string) else { 
        print("Failed to parse '\(string)' to decimal value")
        return nil }
    let decimal = intValue / 100
    print("Price: " , decimal)
    return decimal
}


// Helper to calculate area of a normalized bounding box.
private func area(of observation: VNRecognizedTextObservation) -> CGFloat {
    let box = observation.boundingBox
    return box.width * box.height
}

private func isCompletelyToLeft(of rect1: CGRect, comparedTo rect2: CGRect) -> Bool {
    return rect1.maxX < rect2.minX
}

private func isCompletelyAbove(of rect1: CGRect, comparedTo rect2: CGRect) -> Bool {
    return rect1.maxY < rect2.minY
}

private func extractBarcode(observations: [VNRecognizedTextObservation]) -> (CGRect , String)? {
    let ean13Pattern = #"(?<!\d)(\d{13})(?!\d)"#
    let ean13Regex = try! NSRegularExpression(pattern: ean13Pattern, options: [])
    
    for observation in observations {
        guard let candidate = observation.topCandidates(1).first else { continue }
        let candidateText = candidate.string
        let range = NSRange(location: 0, length: candidateText.utf16.count)
        if let _ = ean13Regex.firstMatch(in: candidateText, options: [], range: range) {
            return (observation.boundingBox , candidateText)
        }
    }
    return nil
}

private func extractProductName(observations: [VNRecognizedTextObservation],
                                priceBbox: CGRect, barcodeBbox: CGRect,
                                priceString: String, barcodeString: String
) ->  String? {
    let candidateObservations = observations.filter { obs in
        let bbox = obs.boundingBox
        guard let text = obs.topCandidates(1).first?.string else { return false }
        return !isCompletelyToLeft(of: bbox, comparedTo: priceBbox) &&
        !isCompletelyAbove(of: bbox, comparedTo: barcodeBbox)
        && text != priceString && text != barcodeString
    }
    
    for cand in candidateObservations {
        if let text = cand.topCandidates(1).first?.string  {
            print("Product name candidate: '\(text)'")
        }
    }
    
    let productNameText = candidateObservations.compactMap { $0.topCandidates(1).first?.string }
        .map { $0.replacingOccurrences(of: "\n", with: " ")}
        .filter { stringIsPartOfProductName(s: $0)}.joined(separator: " ")
    
    print("Product name: '\(productNameText)'")
    
    return productNameText
}

func stringIsPartOfProductName(s: String) -> Bool {
    let containsLowercaseLetter = s.contains(/[a-z]/)
    let isNumber = Int(s) != nil
    return !(containsLowercaseLetter || isNumber)
}
