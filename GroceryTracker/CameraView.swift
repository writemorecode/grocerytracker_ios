//
//  CameraView.swift
//  GroceryTracker
//
//  Created by Gustav Karlsson on 2025-02-08.
//

import Foundation
import SwiftUI

struct CameraView: UIViewRepresentable {
    @ObservedObject var viewModel: ScannerViewModel

    func makeUIView(context: Context) -> UIView {
        let previewView = CameraPreviewView(frame: .zero)
        context.coordinator.setupCamera(in: previewView)
        return previewView
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }
}
