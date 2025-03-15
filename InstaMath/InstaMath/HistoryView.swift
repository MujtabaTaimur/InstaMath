import SwiftUI

struct HistoryView: View {
    let solutions: [MathSolution]
    @State private var selectedSolution: MathSolution?
    @State private var showingVisualization = false
    
    var body: some View {
        List(solutions) { solution in
            Button(action: {
                selectedSolution = solution
            }) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(solution.problem)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(solution.result)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        // Domain badge
                        Text(solution.domain.rawValue)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                        
                        // Complexity badge
                        Text(solution.complexity.rawValue)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(complexityColor(solution.complexity).opacity(0.2))
                            .foregroundColor(complexityColor(solution.complexity))
                            .cornerRadius(4)
                        
                        if let formulaType = solution.formulaType {
                            // Formula type badge
                            Text(formulaType.rawValue)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.purple.opacity(0.2))
                                .foregroundColor(.purple)
                                .cornerRadius(4)
                        }
                        
                        Spacer()
                        
                        // Date
                        Text(formattedDate(solution.timestamp))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Related concepts
                    if !solution.relatedConcepts.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 4) {
                                ForEach(solution.relatedConcepts.prefix(3), id: \.self) { concept in
                                    Text(concept)
                                        .font(.caption2)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.gray.opacity(0.1))
                                        .cornerRadius(4)
                                }
                                
                                if solution.relatedConcepts.count > 3 {
                                    Text("+\(solution.relatedConcepts.count - 3) more")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .navigationTitle("Solution History")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedSolution) { solution in
            NavigationView {
                SolutionDetailView(solution: solution, showVisualization: {
                    // Dismiss the detail view and show visualization
                    selectedSolution = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        selectedSolution = solution
                        showingVisualization = true
                    }
                })
                .navigationTitle("Solution Detail")
                .navigationBarItems(trailing: Button("Done") {
                    selectedSolution = nil
                })
            }
        }
        .sheet(isPresented: $showingVisualization) {
            if let solution = selectedSolution {
                NavigationView {
                    VisualizationSelectorView(mathSolution: solution)
                        .navigationTitle("3D Visualization")
                        .navigationBarItems(trailing: Button("Done") {
                            showingVisualization = false
                        })
                }
            }
        }
    }
    
    // Helper function to format date
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
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

// Detailed view for a solution
struct SolutionDetailView: View {
    let solution: MathSolution
    let showVisualization: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Problem and solution
                Group {
                    Text("Problem:")
                        .font(.headline)
                    
                    Text(solution.problem)
                        .font(.title3)
                        .padding(.horizontal)
                    
                    Text("Solution:")
                        .font(.headline)
                    
                    Text(solution.result)
                        .font(.title2)
                        .bold()
                        .padding(.horizontal)
                }
                
                Divider()
                
                // Metadata section
                Group {
                    Text("Details:")
                        .font(.headline)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            metadataRow(label: "Domain:", value: solution.domain.rawValue)
                            metadataRow(label: "Complexity:", value: solution.complexity.rawValue)
                            if let formulaType = solution.formulaType {
                                metadataRow(label: "Formula Type:", value: formulaType.rawValue)
                            }
                            metadataRow(label: "Date:", value: formattedDate(solution.timestamp))
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                }
                
                Divider()
                
                // Related concepts
                if !solution.relatedConcepts.isEmpty {
                    Text("Related Concepts:")
                        .font(.headline)
                    
                    HistoryFlowLayout(spacing: 8) {
                        ForEach(solution.relatedConcepts, id: \.self) { concept in
                            Text(concept)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                }
                
                Divider()
                
                // Steps
                Text("Solution Steps:")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(solution.steps.indices, id: \.self) { index in
                        HStack(alignment: .top) {
                            Text("\(index + 1).")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .frame(width: 25, alignment: .leading)
                            
                            Text(solution.steps[index])
                                .font(.subheadline)
                        }
                    }
                }
                .padding(.horizontal)
                
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
                .padding(.top, 16)
                .padding(.horizontal)
            }
            .padding()
        }
    }
    
    // Helper view for metadata rows
    private func metadataRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline)
        }
    }
    
    // Helper function to format date
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// Helper view for flowing layout of tags
struct HistoryFlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        
        var width: CGFloat = 0
        var height: CGFloat = 0
        var lineWidth: CGFloat = 0
        var lineHeight: CGFloat = 0
        
        for size in sizes {
            if lineWidth + size.width > proposal.width ?? .infinity {
                width = max(width, lineWidth)
                height += lineHeight + spacing
                lineWidth = size.width
                lineHeight = size.height
            } else {
                lineWidth += size.width + spacing
                lineHeight = max(lineHeight, size.height)
            }
        }
        
        width = max(width, lineWidth)
        height += lineHeight
        
        return CGSize(width: width, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        
        var x = bounds.minX
        var y = bounds.minY
        var lineHeight: CGFloat = 0
        
        for (index, subview) in subviews.enumerated() {
            let size = sizes[index]
            
            if x + size.width > bounds.maxX {
                x = bounds.minX
                y += lineHeight + spacing
                lineHeight = 0
            }
            
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}

#Preview {
    NavigationView {
        HistoryView(solutions: [
            MathSolution(
                problem: "∫ x^2 dx",
                result: "x^3/3 + C",
                steps: [
                    "Identify the integral of x^2",
                    "Apply the power rule: ∫ x^n dx = x^(n+1)/(n+1) + C",
                    "Substitute n = 2: ∫ x^2 dx = x^3/3 + C"
                ],
                complexity: .intermediate,
                domain: .calculus,
                formulaType: .integral,
                relatedConcepts: ["Indefinite integrals", "Power rule", "Antiderivatives"]
            ),
            MathSolution(
                problem: "3x - 2 = 7",
                result: "x = 3",
                steps: ["Add 2 to both sides: 3x = 9", "Divide both sides by 3: x = 3"],
                complexity: .basic,
                domain: .algebra,
                formulaType: .algebraic,
                relatedConcepts: ["Linear equations", "Equation solving"]
            )
        ])
    }
} 