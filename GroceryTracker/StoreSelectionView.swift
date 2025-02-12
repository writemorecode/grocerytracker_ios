//
//  StoreSelectionView.swift
//  GroceryTracker
//
//  Created by Gustav Karlsson on 2025-01-24.
//

import Foundation
import MapKit
import SwiftUI

struct StoreSelectionView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var isSearchingForStores = false
    @State private var isUploadingStoreData = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            Group {
                if isSearchingForStores {
                    ProgressView("Searching for nearby stores...")
                } else if isUploadingStoreData {
                    ProgressView("Uploading store data...")
                } else if let errorMessage {
                    ErrorView(message: errorMessage, onRetry: loadNearbyStores)
                } else if locationManager.stores.isEmpty {
                    EmptyStateView(onRetry: loadNearbyStores)
                } else {
                    StoreListView(
                        stores: locationManager.stores, onSelect: selectStore)
                }
            }
            .navigationTitle("Select Store")
        }
        .onAppear(perform: loadNearbyStores)
    }

    private func loadNearbyStores() {
        isSearchingForStores = true
        errorMessage = nil
        locationManager.searchNearbyStores { [self] result in
            DispatchQueue.main.async {
                self.isSearchingForStores = false
                switch result {
                case .success(let stores):
                    self.locationManager.stores = stores
                    if stores.isEmpty {
                        self.errorMessage = "No grocery stores found nearby"
                    }
                case .failure(let error as CLError) where error.code == .denied:
                    self.errorMessage =
                        "Location access is denied. Please enable it in settings."
                case .failure(let error):
                    print(error)
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func selectStore(_ store: Store) {
        isUploadingStoreData = true

        Task {
            do {
                let storeID = try await NetworkManager.shared.uploadStore(
                    store
                )
                await MainActor.run {
                    StoreManager.shared.setSelectedStore(
                        id: storeID, name: store.name,
                        coordinate: CLLocationCoordinate2D(
                            latitude: store.latitude, longitude: store.longitude
                        ))
                    isUploadingStoreData = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isUploadingStoreData = false
                }
            }
        }
    }
}

struct Store: Identifiable, Encodable {
    let id = UUID()
    let address: String
    let name: String
    let street_number: String
    let street_name: String
    let city: String
    let country_code: String
    let latitude: Double
    let longitude: Double
    let distance: CLLocationDistance

    private enum CodingKeys: String, CodingKey {
        case address, name, street_number, street_name, city, country_code,
            latitude, longitude, distance
    }
}
