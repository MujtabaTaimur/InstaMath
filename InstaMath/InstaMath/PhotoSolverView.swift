import SwiftUI
import AVFoundation
import Vision

#if canImport(UIKit)
import UIKit
#endif

#if os(iOS)
struct PhotoSolverView: View {
    @ObservedObject var viewModel: MathSolverViewModel
    @State private var showingCamera = false
    @State private var showingImagePicker = false
    @State private var showingVisualization = false
    
    var body: some View {
        VStack {
            if let image = viewModel.capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 300)
                    .cornerRadius(12)
                    .padding()
            }
            
            if viewModel.isProcessing {
                ProgressView("Processing...")
                    .progressViewStyle(CircularProgressViewStyle())
            } else if let solution = viewModel.solution {
                SolutionView(solution: solution, showVisualization: {
                    showingVisualization = true
                })
            }
            
            Spacer()
            
            HStack(spacing: 20) {
                Button(action: { showingCamera = true }) {
                    VStack {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 30))
                        Text("Take Photo")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                
                Button(action: { showingImagePicker = true }) {
                    VStack {
                        Image(systemName: "photo.fill")
                            .font(.system(size: 30))
                        Text("Choose Photo")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }
            .padding()
        }
        .navigationTitle("InstaMath")
        .sheet(isPresented: $showingCamera) {
            CameraView(image: $viewModel.capturedImage, isShown: $showingCamera)
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $viewModel.capturedImage)
        }
        .sheet(isPresented: $showingVisualization) {
            if let solution = viewModel.solution {
                NavigationView {
                    VisualizationSelectorView(mathSolution: solution)
                        .navigationTitle("3D Visualization")
                        .navigationBarItems(trailing: Button("Done") {
                            showingVisualization = false
                        })
                }
            }
        }
        .onChange(of: viewModel.capturedImage) { _ in
            if viewModel.capturedImage != nil {
                viewModel.processImage()
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: HistoryView(solutions: viewModel.solutionHistory)) {
                    Image(systemName: "clock.fill")
                }
            }
        }
    }
}
#else
struct PhotoSolverView: View {
    @ObservedObject var viewModel: MathSolverViewModel
    
    var body: some View {
        Text("Photo solving not available on this platform")
            .padding()
    }
}
#endif

struct SolutionView: View {
    let solution: MathSolution
    let showVisualization: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Problem: \(solution.problem)")
                .font(.headline)
            
            Text("Solution: \(solution.result)")
                .font(.title2)
                .bold()
            
            // Domain and complexity badges
            HStack {
                Text(solution.domain.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
                
                Text(solution.complexity.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(complexityColor(solution.complexity).opacity(0.2))
                    .foregroundColor(complexityColor(solution.complexity))
                    .cornerRadius(8)
                
                if let formulaType = solution.formulaType {
                    Text(formulaType.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.purple.opacity(0.2))
                        .foregroundColor(.purple)
                        .cornerRadius(8)
                }
                
                Spacer()
            }
            
            Text("Steps:")
                .font(.headline)
            
            ForEach(solution.steps.indices, id: \.self) { index in
                Text("\(index + 1). \(solution.steps[index])")
                    .padding(.leading)
            }
            
            // 3D Visualization button
            Button(action: showVisualization) {
                HStack {
                    Image(systemName: "cube.transparent")
                        .font(.system(size: 20))
                    Text("View 3D Visualization")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 5)
        .padding()
    }
    
    // Helper function to get color for complexity
    private func complexityColor(_ complexity: ProblemComplexity) -> Color {
        switch complexity {
        case .basic: return .green
        case .intermediate: return .blue
        case .advanced: return .purple
        case .research: return .red
        }
    }
}

#Preview {
    NavigationView {
        PhotoSolverView(viewModel: MathSolverViewModel())
    }
} 