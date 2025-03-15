//
//  ContentView.swift
//  InstaMath
//
//  Created by Mujtaba  on 14/03/2025.
//

import SwiftUI
import AVFoundation
import Vision

struct ContentView: View {
    @StateObject private var mathSolverViewModel = MathSolverViewModel()
    @StateObject private var graphViewModel = GraphingViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationView {
                PhotoSolverView(viewModel: mathSolverViewModel)
            }
            .tabItem {
                Label("Photo Solver", systemImage: "camera.fill")
            }
            .tag(0)
            
            NavigationView {
                GraphingCalculatorView(viewModel: graphViewModel)
            }
            .tabItem {
                Label("Graphing", systemImage: "function")
            }
            .tag(1)
            
            NavigationView {
                ScientificCalculatorView()
            }
            .tabItem {
                Label("Scientific", systemImage: "square.grid.3x3.fill")
            }
            .tag(2)
            
            NavigationView {
                HistoryView(solutions: mathSolverViewModel.solutions)
            }
            .tabItem {
                Label("History", systemImage: "clock.arrow.circlepath")
            }
            .tag(3)
        }
        .accentColor(.blue)
        .onChange(of: selectedTab) { newTab in
            // Reset certain UI states when switching tabs
            if newTab == 1 {
                // When switching to graphing tab, ensure we're showing a clean interface
                graphViewModel.currentAnalysis = nil
            }
        }
        .onAppear {
            // Set default tab bar appearance
            UITabBar.appearance().backgroundColor = UIColor.systemBackground
            
            // Request camera permissions in advance if we're going to use the photo solver
            AVCaptureDevice.requestAccess(for: .video) { _ in }
        }
    }
}

#Preview {
    ContentView()
}
