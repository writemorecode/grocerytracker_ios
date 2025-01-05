//
//  ContentView.swift
//  GroceryTracker
//
//  Created by Gustav Karlsson on 2024-12-25.
//

import SwiftUI
import VisionKit

struct ContentView: View {
    @State private var scannedText = ""
    @State private var showingScanner = false
    @State private var isDeviceSupported: Bool = false
    
    var body: some View {
        NavigationView {
            VStack {
                if !scannedText.isEmpty {
                    ScrollView {
                        Text(scannedText)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                
                if isDeviceSupported {
                    Button(action: { showingScanner = true }) {
                        Label("Scan Text", systemImage: "text.viewfinder")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding()
                } else {
                    Text("Live Text not supported on this device")
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .navigationTitle("Live Text Scanner")
            .sheet(isPresented: $showingScanner) {
                ScannerView(scannedText: $scannedText)
            }
            .onAppear {
                isDeviceSupported = DataScannerViewController.isSupported
            }
        }
    }
}
