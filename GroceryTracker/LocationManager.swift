//
//  LocationManager.swift
//  GroceryTracker
//
//  Created by Gustav Karlsson on 2025-01-24.
//

import Foundation
import MapKit
import SwiftUI

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var stores: [StoreWithDistanceItem] = []
    private let locationManager = CLLocationManager()
    private var searchCompletion: ((Result<[StoreWithDistanceItem], Error>) -> Void)?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    }
    
    func searchNearbyStores(completion: @escaping (Result<[StoreWithDistanceItem], Error>) -> Void) {
        searchCompletion = completion
        let status = locationManager.authorizationStatus
        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        case .denied, .restricted:
            completion(.failure(CLError(.denied)))
        @unknown default:
            completion(.failure(CLError(.locationUnknown)))
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            searchCompletion?(.failure(CLError(.locationUnknown)))
            return
        }
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "grocery store"
        request.region = MKCoordinateRegion(
            center: location.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        
        let search = MKLocalSearch(request: request)
        search.start { [weak self] response, error in
            if let error = error {
                self?.searchCompletion?(.failure(error))
                return
            }
            
            let stores = response?.mapItems.compactMap { item -> StoreWithDistanceItem? in
                guard let name = item.name else { return nil }
                if !storeNameIsValid(name: name) { return nil }
                let storeLocation = CLLocation(latitude: item.placemark.coordinate.latitude,
                                               longitude: item.placemark.coordinate.longitude)
                let optional_string_to_integer = {(optional : String?) -> Int in
                    guard let inner = optional, let number = Int(inner) else { return 0 }
                    return number
                };
                return StoreWithDistanceItem(
                    address: addressString(mapItem: item),
                    name: name,
                    street_number: optional_string_to_integer(item.placemark.subThoroughfare),
                    street_name: item.placemark.thoroughfare ?? "",
                    city: item.placemark.locality ?? "",
                    country_code: item.placemark.countryCode ?? "",
                    coordinate: item.placemark.coordinate,
                    distance: location.distance(from: storeLocation)
                )
            }.sorted {
                $0.distance < $1.distance
            }
            ?? []
            
            self?.stores = stores;
            self?.searchCompletion?(.success(stores))
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        searchCompletion?(.failure(error))
    }
}

// Supporting Views
struct ErrorView: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
            Text(message)
                .multilineTextAlignment(.center)
            Button("Try Again", action: onRetry)
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

struct EmptyStateView: View {
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "map")
                .font(.largeTitle)
            Text("No nearby grocery stores found")
            Button("Search Again", action: onRetry)
                .buttonStyle(.bordered)
        }
        .foregroundColor(.secondary)
    }
}

struct StoreListView: View {
    let stores: [StoreWithDistanceItem]
    let onSelect: (StoreWithDistanceItem) -> Void
    
    var body: some View {
        List(stores) { store in
            Button(action: { onSelect(store) }) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(store.name)
                        .font(.headline)
                    Text(store.address)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(MKDistanceFormatter().string(fromDistance: store.distance))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

func addressString(mapItem: MKMapItem) -> String {
    let placemark = mapItem.placemark
    
    // Create an array to store the address components
    var addressComponents: [String] = []
    
    // Add street number and name if available
    if let streetNumber = placemark.thoroughfare, let streetName = placemark.subThoroughfare {
        addressComponents.append("\(streetNumber) \(streetName)")
    } else if let streetName = placemark.thoroughfare {
        addressComponents.append(streetName)
    }
    
    // Add locality (city) if available
    if let locality = placemark.locality {
        addressComponents.append(locality)
    }
    
    // Join the address components with commas
    return addressComponents.joined(separator: ", ")
}

func storeNameIsValid(name: String) -> Bool {
    return name.lowercased().contains(/^(ica|hemköp|konsum|willys|lidl)/)
}
