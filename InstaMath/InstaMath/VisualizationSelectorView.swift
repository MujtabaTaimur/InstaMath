import SwiftUI

struct VisualizationSelectorView: View {
    let mathSolution: MathSolution
    @State private var selectedVisualizationType: Visualization.VisualizationType?
    @State private var visualization: Visualization?
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    // Visualization service
    private let visualizationService = Advanced3DVisualization()
    
    var body: some View {
        VStack {
            // Header
            Text("3D Visualization")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top)
            
            Text("Choose a visualization type for your solution")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.bottom)
            
            // Solution info card
            solutionInfoCard
                .padding(.horizontal)
            
            // Visualization type selector
            visualizationTypeSelector
                .padding()
            
            // Visualization display or loading indicator
            if isLoading {
                ProgressView("Generating visualization...")
                    .padding()
            } else if let errorMessage = errorMessage {
                errorView(message: errorMessage)
            } else if let visualization = visualization {
                VisualizationView(visualization: visualization)
                    .transition(.opacity)
            } else {
                placeholderView
            }
            
            Spacer()
        }
    }
    
    // Solution info card
    private var solutionInfoCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text(mathSolution.domain.rawValue)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(mathSolution.formulaType?.rawValue ?? "General")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Complexity badge
                Text(mathSolution.complexity.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(complexityColor(mathSolution.complexity).opacity(0.2))
                    .foregroundColor(complexityColor(mathSolution.complexity))
                    .cornerRadius(8)
            }
            
            Divider()
            
            // Related concepts
            if !mathSolution.relatedConcepts.isEmpty {
                Text("Related Concepts:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(mathSolution.relatedConcepts, id: \.self) { concept in
                            Text(concept)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    // Visualization type selector
    private var visualizationTypeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                visualizationTypeButton(
                    type: .graph3D,
                    icon: "chart.bar.3d",
                    title: "3D Graph"
                )
                
                visualizationTypeButton(
                    type: .surface,
                    icon: "square.3d.layer.3d",
                    title: "Surface"
                )
                
                visualizationTypeButton(
                    type: .vectorField,
                    icon: "arrow.up.and.down.and.arrow.left.and.right",
                    title: "Vector Field"
                )
                
                visualizationTypeButton(
                    type: .animation,
                    icon: "play.circle",
                    title: "Animation"
                )
                
                visualizationTypeButton(
                    type: .engineeringModel,
                    icon: "gear.circle",
                    title: "Engineering"
                )
                
                visualizationTypeButton(
                    type: .parametricCurve,
                    icon: "function",
                    title: "Parametric"
                )
            }
            .padding(.horizontal)
        }
    }
    
    // Visualization type button
    private func visualizationTypeButton(type: Visualization.VisualizationType, icon: String, title: String) -> some View {
        Button(action: {
            selectVisualizationType(type)
        }) {
            VStack {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(selectedVisualizationType == type ? .white : .primary)
                    .frame(width: 50, height: 50)
                    .background(selectedVisualizationType == type ? Color.blue : Color(.systemGray5))
                    .cornerRadius(12)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(selectedVisualizationType == type ? .blue : .primary)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // Placeholder view when no visualization is selected
    private var placeholderView: some View {
        VStack(spacing: 16) {
            Image(systemName: "cube.transparent")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("Select a visualization type")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Choose from the options above to visualize your mathematical solution in 3D")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: 300)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding()
    }
    
    // Error view
    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(.orange)
            
            Text("Visualization Error")
                .font(.headline)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                // Try again
                if let type = selectedVisualizationType {
                    selectVisualizationType(type)
                }
            }) {
                Text("Try Again")
                    .font(.subheadline)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: 300)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding()
    }
    
    // Helper function to select visualization type and generate visualization
    private func selectVisualizationType(_ type: Visualization.VisualizationType) {
        // If already selected, deselect
        if selectedVisualizationType == type {
            withAnimation {
                selectedVisualizationType = nil
                visualization = nil
            }
            return
        }
        
        // Select new type
        withAnimation {
            selectedVisualizationType = type
            isLoading = true
            errorMessage = nil
        }
        
        // Generate visualization in background
        DispatchQueue.global(qos: .userInitiated).async {
            // Simulate processing time
            Thread.sleep(forTimeInterval: 1.0)
            
            // Generate visualization based on type
            let generatedVisualization: Visualization?
            
            switch type {
            case .graph3D, .surface, .vectorField, .animation, .engineeringModel, .parametricCurve:
                generatedVisualization = visualizationService.createVisualization(for: mathSolution)
            }
            
            // Update UI on main thread
            DispatchQueue.main.async {
                withAnimation {
                    isLoading = false
                    
                    if let vis = generatedVisualization {
                        visualization = vis
                        errorMessage = nil
                    } else {
                        errorMessage = "Unable to generate \(typeToString(type)) visualization for this solution. Try a different type."
                    }
                }
            }
        }
    }
    
    // Helper function to convert visualization type to string
    private func typeToString(_ type: Visualization.VisualizationType) -> String {
        switch type {
        case .graph3D: return "3D Graph"
        case .surface: return "Surface"
        case .vectorField: return "Vector Field"
        case .engineeringModel: return "Engineering Model"
        case .animation: return "Animation"
        case .parametricCurve: return "Parametric Curve"
        }
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

// Preview provider
struct VisualizationSelectorView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleSolution = MathSolution(
            problem: "∫ x^2 dx = x^3/3 + C",
            result: "x^3/3 + C",
            steps: ["Identify the integral of x^2", "Apply the power rule: ∫ x^n dx = x^(n+1)/(n+1) + C", "Substitute n = 2: ∫ x^2 dx = x^3/3 + C"],
            complexity: .intermediate,
            domain: .calculus,
            formulaType: .integral,
            relatedConcepts: ["Indefinite integrals", "Power rule", "Antiderivatives"]
        )
        
        VisualizationSelectorView(mathSolution: sampleSolution)
    }
} 