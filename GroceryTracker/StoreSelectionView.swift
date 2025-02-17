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
    @StateObject private var viewModel = StoreSelectionViewModel()

    var body: some View {
        NavigationView {
            Group {
                if viewModel.isSearchingForStores {
                    ProgressView("Searching for nearby stores...")
                } else if viewModel.isUploadingStoreData {
                    ProgressView("Uploading store data...")
                } else if let errorMessage = viewModel.errorMessage {
                    ErrorView(
                        message: errorMessage,
                        onRetry: viewModel.loadNearbyStores)
                } else {
                    EmptyStateView(onRetry: viewModel.loadNearbyStores)
                }
            }
            .navigationTitle("Select Store")
        }
        .onAppear(perform: viewModel.loadNearbyStores)
    }

}

