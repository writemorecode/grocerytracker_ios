//
//  ProductLabelParser.swift
//  GroceryTracker
//
//  Created by Gustav Karlsson on 2025-02-10.
//

import Foundation

func extractProductName(from text: String) -> String? {
    let pattern = /(\b[A-ZÅÄÖ,\n ]+\b|\d+[GP])+/
    if let match = text.firstMatch(of: pattern) {
        let name = String(text[match.range])
        return name.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: " ")
    }
    return nil
}

func extractPrice(from text: String) -> Decimal? {
    let p = /([€$]?\s?\d+[.,]?\d{1,2})/
    if let match = text.firstMatch(of: p) {
        let price_string = String(text[match.range])
        if let price = Decimal(string: price_string) {
            if price_string.contains(/[,.]/) {
                return price
            }
            return price / 100
        }
    }
    return nil
}
