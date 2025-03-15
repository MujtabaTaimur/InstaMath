import SwiftUI
import Charts

#if os(iOS)
import UIKit

struct GraphingCalculatorView: View {
    @ObservedObject var viewModel: GraphingViewModel
    @State private var showingFunctionInput = false
    @State private var selectedFunction: GraphFunction?
    @State private var isDragging = false
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 16) {
                    // Graph View with adaptive height
                    GraphView(viewModel: viewModel)
                        .frame(height: min(geometry.size.height * 0.6, 400))
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(radius: 2)
                        .padding(.horizontal)
                    
                    // Function controls
                    HStack {
                        Button(action: { viewModel.zoomIn() }) {
                            Image(systemName: "plus.magnifyingglass")
                                .padding(8)
                                .background(Color.blue.opacity(0.1))
                                .clipShape(Circle())
                        }
                        
                        Button(action: { viewModel.zoomOut() }) {
                            Image(systemName: "minus.magnifyingglass")
                                .padding(8)
                                .background(Color.blue.opacity(0.1))
                                .clipShape(Circle())
                        }
                        
                        Button(action: { viewModel.resetView() }) {
                            Image(systemName: "arrow.counterclockwise")
                                .padding(8)
                                .background(Color.blue.opacity(0.1))
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                        
                        // Domain & range labels
                        Text("X: [\(String(format: "%.1f", viewModel.minX)), \(String(format: "%.1f", viewModel.maxX))]")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("Y: [\(String(format: "%.1f", viewModel.minY)), \(String(format: "%.1f", viewModel.maxY))]")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    
                    // Function List - Adaptive height based on content
                    VStack {
                        HStack {
                            Text("Functions")
                                .font(.headline)
                            Spacer()
                            Button(action: { showingFunctionInput = true }) {
                                Label("Add", systemImage: "plus.circle.fill")
                            }
                            .foregroundColor(.blue)
                        }
                        .padding(.horizontal)
                        
                        if viewModel.functions.isEmpty {
                            emptyFunctionsPlaceholder
                        } else {
                            functionsList
                        }
                    }
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 1)
                    .padding(.horizontal)
                    
                    // Analysis Tools
                    if let selected = selectedFunction {
                        FunctionAnalysisView(function: selected, viewModel: viewModel)
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(radius: 1)
                            .padding(.horizontal)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                            .animation(.easeInOut, value: selectedFunction?.id)
                    }
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("Graphing Calculator")
        .sheet(isPresented: $showingFunctionInput) {
            FunctionInputView(viewModel: viewModel)
        }
    }
    
    // Empty state placeholder
    private var emptyFunctionsPlaceholder: some View {
        VStack(spacing: 16) {
            Image(systemName: "function")
                .font(.system(size: 40))
                .foregroundColor(.secondary.opacity(0.5))
            
            Text("No functions added yet")
                .foregroundColor(.secondary)
            
            Button(action: { showingFunctionInput = true }) {
                Text("Add Your First Function")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
        }
        .frame(height: 180)
        .frame(maxWidth: .infinity)
        .padding()
    }
    
    // Functions list view
    private var functionsList: some View {
        List {
            ForEach(viewModel.functions) { function in
                FunctionRow(function: function, isSelected: selectedFunction?.id == function.id)
                    .contentShape(Rectangle()) // Improves tap area
                    .onTapGesture {
                        withAnimation {
                            if selectedFunction?.id == function.id {
                                selectedFunction = nil
                            } else {
                                selectedFunction = function
                            }
                        }
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            withAnimation {
                                viewModel.removeFunction(function)
                                if selectedFunction?.id == function.id {
                                    selectedFunction = nil
                                }
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        }
        .frame(minHeight: 100, maxHeight: 200)
        .listStyle(PlainListStyle())
    }
}

struct GraphView: View {
    @ObservedObject var viewModel: GraphingViewModel
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var dragOffset: CGSize = .zero
    @State private var lastDragOffset: CGSize = .zero
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.white
                
                // Grid lines
                gridLines(in: geometry)
                
                // Axes
                axes(in: geometry)
                
                // Function plots
                functionPlots(in: geometry)
                
                // Axis labels
                axisLabels(in: geometry)
            }
            .clipped()
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let translation = CGSize(
                            width: value.translation.width + lastDragOffset.width,
                            height: value.translation.height + lastDragOffset.height
                        )
                        dragOffset = translation
                        viewModel.pan(
                            dx: value.translation.width - lastDragOffset.width,
                            dy: value.translation.height - lastDragOffset.height
                        )
                        lastDragOffset = translation
                    }
                    .onEnded { _ in
                        lastDragOffset = dragOffset
                    }
            )
            .gesture(
                MagnificationGesture()
                    .onChanged { value in
                        let newScale = value * lastScale
                        scale = newScale
                        let zoomFactor = lastScale / newScale
                        
                        if zoomFactor > 1 {
                            viewModel.zoomOut(factor: Double(zoomFactor))
                        } else {
                            viewModel.zoomIn(factor: Double(1/zoomFactor))
                        }
                        
                        lastScale = newScale
                    }
                    .onEnded { _ in
                        lastScale = 1.0
                    }
            )
            .onTapGesture(count: 2) {
                withAnimation(.spring()) {
                    viewModel.resetView()
                    scale = 1.0
                    lastScale = 1.0
                    dragOffset = .zero
                    lastDragOffset = .zero
                }
            }
        }
    }
    
    private func gridLines(in geometry: GeometryProxy) -> some View {
        Canvas { context, size in
            // Calculate spacing for grid lines
            let xAxisSpacing = viewModel.gridSpacing
            let yAxisSpacing = viewModel.gridSpacing
            
            // Draw vertical grid lines
            for x in stride(from: viewModel.minX, through: viewModel.maxX, by: xAxisSpacing) {
                if abs(x) < 0.001 { continue } // Skip the axis line
                
                let screenX = viewModel.toScreenX(x, width: size.width)
                
                var path = Path()
                path.move(to: CGPoint(x: screenX, y: 0))
                path.addLine(to: CGPoint(x: screenX, y: size.height))
                
                context.stroke(path, with: .color(Color.gray.opacity(0.2)), lineWidth: 0.5)
            }
            
            // Draw horizontal grid lines
            for y in stride(from: viewModel.minY, through: viewModel.maxY, by: yAxisSpacing) {
                if abs(y) < 0.001 { continue } // Skip the axis line
                
                let screenY = viewModel.toScreenY(y, height: size.height)
                
                var path = Path()
                path.move(to: CGPoint(x: 0, y: screenY))
                path.addLine(to: CGPoint(x: size.width, y: screenY))
                
                context.stroke(path, with: .color(Color.gray.opacity(0.2)), lineWidth: 0.5)
            }
        }
    }
    
    private func axes(in geometry: GeometryProxy) -> some View {
        Canvas { context, size in
            let zeroX = viewModel.toScreenX(0, width: size.width)
            let zeroY = viewModel.toScreenY(0, height: size.height)
            
            // X-axis
            var xAxisPath = Path()
            xAxisPath.move(to: CGPoint(x: 0, y: zeroY))
            xAxisPath.addLine(to: CGPoint(x: size.width, y: zeroY))
            context.stroke(xAxisPath, with: .color(Color.black), lineWidth: 1.5)
            
            // Y-axis
            var yAxisPath = Path()
            yAxisPath.move(to: CGPoint(x: zeroX, y: 0))
            yAxisPath.addLine(to: CGPoint(x: zeroX, y: size.height))
            context.stroke(yAxisPath, with: .color(Color.black), lineWidth: 1.5)
        }
    }
    
    private func functionPlots(in geometry: GeometryProxy) -> some View {
        ZStack {
            ForEach(viewModel.functions) { function in
                FunctionPath(function: function, viewModel: viewModel, size: geometry.size)
                    .stroke(function.color, lineWidth: 2.5)
            }
        }
    }
    
    private func axisLabels(in geometry: GeometryProxy) -> some View {
        ZStack {
            // X-axis labels
            ForEach(stride(from: viewModel.minX, through: viewModel.maxX, by: viewModel.gridSpacing), id: \.self) { x in
                if abs(x) > 0.001 { // Avoid labeling near zero
                    let screenX = viewModel.toScreenX(x, width: geometry.size.width)
                    let screenY = viewModel.toScreenY(0, height: geometry.size.height)
                    
                    Text("\(Int(x))")
                        .font(.system(size: 8))
                        .foregroundColor(.secondary)
                        .position(x: screenX, y: screenY + 12)
                }
            }
            
            // Y-axis labels
            ForEach(stride(from: viewModel.minY, through: viewModel.maxY, by: viewModel.gridSpacing), id: \.self) { y in
                if abs(y) > 0.001 { // Avoid labeling near zero
                    let screenX = viewModel.toScreenX(0, width: geometry.size.width)
                    let screenY = viewModel.toScreenY(y, height: geometry.size.height)
                    
                    Text("\(Int(y))")
                        .font(.system(size: 8))
                        .foregroundColor(.secondary)
                        .position(x: screenX - 12, y: screenY)
                }
            }
        }
    }
}

struct FunctionPath: Shape {
    let function: GraphFunction
    let viewModel: GraphingViewModel
    let size: CGSize
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        var firstPoint = true
        var lastPoint: CGPoint?
        let maxGap: CGFloat = 100 // Maximum allowed gap to detect discontinuities
        
        // Adaptive sampling based on domain size
        let domainSize = viewModel.maxX - viewModel.minX
        let sampleCount = 500 // Higher sample count for smoother curves
        let step = domainSize / Double(sampleCount)
        
        for x in stride(from: viewModel.minX, through: viewModel.maxX, by: step) {
            if let y = function.evaluate(x) {
                // Skip values outside the visible y-range with some margin
                if y < viewModel.minY - 10 || y > viewModel.maxY + 10 {
                    lastPoint = nil
                    firstPoint = true
                    continue
                }
                
                let screenX = viewModel.toScreenX(x, width: size.width)
                let screenY = viewModel.toScreenY(y, height: size.height)
                let currentPoint = CGPoint(x: screenX, y: screenY)
                
                if firstPoint {
                    path.move(to: currentPoint)
                    firstPoint = false
                } else if let last = lastPoint {
                    // Check for discontinuities
                    let distance = hypot(currentPoint.x - last.x, currentPoint.y - last.y)
                    if distance < maxGap {
                        path.addLine(to: currentPoint)
                    } else {
                        // Found a discontinuity, start a new subpath
                        path.move(to: currentPoint)
                    }
                }
                
                lastPoint = currentPoint
            } else {
                // Function is undefined at this point, reset for new subpath
                lastPoint = nil
                firstPoint = true
            }
        }
        
        return path
    }
}

struct FunctionRow: View {
    let function: GraphFunction
    let isSelected: Bool
    
    var body: some View {
        HStack {
            Circle()
                .fill(function.color)
                .frame(width: 12, height: 12)
            Text(function.expression)
                .lineLimit(1)
            Spacer()
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 8)
        .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        .cornerRadius(8)
    }
}

struct FunctionAnalysisView: View {
    let function: GraphFunction
    let viewModel: GraphingViewModel
     
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Analysis: \(function.expression)")
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.bottom, 4)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    Button(action: { viewModel.findDerivative(of: function) }) {
                        Label("Derivative", systemImage: "function")
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button(action: { viewModel.findIntegral(of: function) }) {
                        Label("Integral", systemImage: "sum")
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button(action: { viewModel.findRoots(of: function) }) {
                        Label("Roots", systemImage: "x.circle")
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button(action: { viewModel.findInflectionPoints(of: function) }) {
                        Label("Inflection", systemImage: "arrow.up.and.down")
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.horizontal, 4)
            }
            
            if let analysis = viewModel.currentAnalysis {
                Text(analysis)
                    .font(.body)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding()
    }
}

#Preview {
    NavigationView {
        GraphingCalculatorView(viewModel: GraphingViewModel())
    }
}

#else
struct GraphingCalculatorView: View {
    @ObservedObject var viewModel: GraphingViewModel
    
    var body: some View {
        Text("Graphing calculator not available on this platform")
            .padding()
    }
}
#endif 