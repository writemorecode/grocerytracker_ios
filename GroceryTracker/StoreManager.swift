//
//  StoreManager.swift
//  GroceryTracker
//
//  Created by Gustav Karlsson on 2025-01-24.
//

import Foundation


// StoreManager.swift
class StoreManager: ObservableObject {
    static let shared = StoreManager()
    @Published var currentStoreID: Int?
    @Published var currentStoreName: String?
    
    func setSelectedStore(id: Int, name: String) {
        currentStoreID = id
        currentStoreName = name
    }
}
