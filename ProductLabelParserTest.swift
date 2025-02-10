//
//  ProductLabelParserTest.swift
//  GroceryTrackerTests
//
//  Created by Gustav Karlsson on 2025-02-10.
//

import Testing
import Foundation

struct ProductLabelParserTest {

    @Test func testExtractPrice() async throws {
        let input = "2590"
        let expected = Decimal(string: "25.90")!
        let got = extractPrice(from: input)
        #expect(got ==  expected)
    }

    @Test func testExtractProductName() async throws {
        let input = """
        FRANSKROST ARVIDNORDQUIST, 500G
        EXTRA MÖRKROST, HELA BÖNOR
        CERTIFIED
        Ord pris/st: 79:90
        """
        let expected = "FRANSKROST ARVIDNORDQUIST, 500G EXTRA MÖRKROST, HELA BÖNOR CERTIFIED"
        let got = extractProductName(from: input)
        #expect(got ==  expected)
    }
}
