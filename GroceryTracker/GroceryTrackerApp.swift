import SwiftUI

@main
struct GroceryTrackerApp: App {
    @StateObject private var storeManager = StoreManager.shared

    var body: some Scene {
        WindowGroup {
            if storeManager.currentStoreID != nil {
                ContentView()
            } else {
                StoreSelectionView()
            }
        }
        .environmentObject(storeManager)
    }
}
