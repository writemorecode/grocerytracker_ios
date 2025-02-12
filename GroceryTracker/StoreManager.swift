//
//  StoreManager.swift
//  GroceryTracker
//
//  Created by Gustav Karlsson on 2025-01-24.
//

import Foundation
import MapKit

// StoreManager.swift
class StoreManager: ObservableObject {
    static let shared = StoreManager()
    @Published var currentStoreID: Int?
    @Published var currentStoreName: String?
    @Published var currentStoreCoordinate: CLLocationCoordinate2D?

    func setSelectedStore(
        id: Int, name: String, coordinate: CLLocationCoordinate2D
    ) {
        currentStoreID = id
        currentStoreName = name
        currentStoreCoordinate = coordinate
    }
}
