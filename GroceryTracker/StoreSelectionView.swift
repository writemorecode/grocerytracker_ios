//
//  StoreSelectionView.swift
//  GroceryTracker
//
//  Created by Gustav Karlsson on 2025-01-24.
//

import Foundation
import SwiftUI
import MapKit

struct StoreSelectionView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showAlert = false
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Searching for nearby stores...")
                } else if let errorMessage {
                    ErrorView(message: errorMessage, onRetry: loadNearbyStores)
                } else if locationManager.stores.isEmpty {
                    EmptyStateView(onRetry: loadNearbyStores)
                } else {
                    StoreListView(stores: locationManager.stores, onSelect: selectStore)
                }
                
            }
            .navigationTitle("Select Store")
            .alert("Store Selection Error", isPresented: $showAlert) {
                Button("OK") { }
            } message: {
                Text(errorMessage ?? "Unknown error occurred")
            }
        }
        .onAppear(perform: loadNearbyStores)
    }
    
    private func loadNearbyStores() {
        isLoading = true
        errorMessage = nil
        locationManager.searchNearbyStores { [self] result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let stores):
                    self.locationManager.stores = stores;
                    if stores.isEmpty {
                        self.errorMessage = "No grocery stores found nearby"
                    }
                case .failure(let error as CLError) where error.code == .denied:
                    self.errorMessage = "Location access is denied. Please enable it in settings."
                    self.showAlert = true
                case .failure(let error):
                    print(error)
                    self.errorMessage = error.localizedDescription
                    self.showAlert = true
                }
            }
        }
    }
    
    private func selectStore(_ store: StoreWithDistanceItem) {
        isLoading = true
        
        Task {
            do {
                let storeRecord = StoreRecord(item: store)
                let storeID = try await NetworkManager.shared.uploadStore(
                    storeRecord
                )
                
                await MainActor.run {
                    StoreManager.shared.setSelectedStore(id: storeID, name: store.name)
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showAlert = true
                    isLoading = false
                }
            }
        }
    }
}

struct StoreWithDistanceItem: Identifiable {
    let id = UUID()
    let address: String
    let name: String
    let street_number: Int
    let street_name: String
    let city: String
    let country_code: String
    let coordinate: CLLocationCoordinate2D
    let distance: CLLocationDistance
}

struct StoreRecord : Encodable {
    let name: String
    let street_number: Int
    let street_name: String
    let city: String
    let country_code: String
    let latitude: Double
    let longitude: Double
    
    init(item: StoreWithDistanceItem) {
        self.name = item.name
        self.street_name = item.street_name
        self.street_number = item.street_number
        self.city = item.city
        self.country_code = item.country_code
        self.latitude = item.coordinate.latitude
        self.longitude = item.coordinate.longitude
    }
}
