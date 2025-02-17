//
//  StoreSelectionViewModel.swift
//  GroceryTracker
//
//  Created by Gustav Karlsson on 2025-02-17.
//

import Foundation
import MapKit
import SwiftUI

class StoreSelectionViewModel: ObservableObject {
    @Published var isSearchingForStores = false
    @Published var isUploadingStoreData = false
    @Published var errorMessage: String?
    @Published var stores: [Store] = []

    private let locationManager = LocationManager()

    func loadNearbyStores() {
        isSearchingForStores = true
        errorMessage = nil
        locationManager.searchNearbyStores { [weak self] result in
            DispatchQueue.main.async {
                self?.isSearchingForStores = false
                switch result {
                case .success(let stores):
                    self?.stores = stores
                    if let nearestStore = stores.min(by: {
                        $0.distance < $1.distance
                    }) {
                        self?.selectStore(nearestStore)
                    } else {
                        self?.errorMessage = "No nearby stores found."
                    }
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func selectStore(_ store: Store) {
        guard !isUploadingStoreData else { return }
        isUploadingStoreData = true

        Task {
            do {
                let storeID = try await NetworkManager.shared.uploadStore(store)
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
