import SwiftUI
import Darwin

class GraphingViewModel: ObservableObject {
    @Published var functions: [GraphFunction] = []
    @Published var currentAnalysis: String?
    
    // View properties
    @Published var minX: Double = -10
    @Published var maxX: Double = 10
    @Published var minY: Double = -10
    @Published var maxY: Double = 10
    @Published var gridSpacing: Double = 1
    
    private var panOffset: CGPoint = .zero
    private let defaultZoomFactor: Double = 1.2
    
    // Mathematical constants
    let colors: [Color] = [.blue, .red, .green, .purple, .orange, .pink, .teal]
    
    // MARK: - View Transformation
    
    func toScreenX(_ x: Double, width: CGFloat) -> CGFloat {
        let range = maxX - minX
        return CGFloat((x - minX) / range) * width
    }
    
    func toScreenY(_ y: Double, height: CGFloat) -> CGFloat {
        let range = maxY - minY
        return height - CGFloat((y - minY) / range) * height
    }
    
    func fromScreenX(_ screenX: CGFloat, width: CGFloat) -> Double {
        let range = maxX - minX
        return minX + Double(screenX / width) * range
    }
    
    func fromScreenY(_ screenY: CGFloat, height: CGFloat) -> Double {
        let range = maxY - minY
        return maxY - Double(screenY / height) * range
    }
    
    func zoomIn(factor: Double = 0) {
        let zoomFactor = factor > 0 ? factor : defaultZoomFactor
        
        let centerX = (maxX + minX) / 2
        let centerY = (maxY + minY) / 2
        let newRangeX = (maxX - minX) / zoomFactor
        let newRangeY = (maxY - minY) / zoomFactor
        
        minX = centerX - newRangeX / 2
        maxX = centerX + newRangeX / 2
        minY = centerY - newRangeY / 2
        maxY = centerY + newRangeY / 2
        
        updateGridSpacing()
    }
    
    func zoomOut(factor: Double = 0) {
        let zoomFactor = factor > 0 ? factor : defaultZoomFactor
        
        let centerX = (maxX + minX) / 2
        let centerY = (maxY + minY) / 2
        let newRangeX = (maxX - minX) * zoomFactor
        let newRangeY = (maxY - minY) * zoomFactor
        
        minX = centerX - newRangeX / 2
        maxX = centerX + newRangeX / 2
        minY = centerY - newRangeY / 2
        maxY = centerY + newRangeY / 2
        
        updateGridSpacing()
    }
    
    func resetView() {
        minX = -10
        maxX = 10
        minY = -10
        maxY = 10
        gridSpacing = 1
        panOffset = .zero
        currentAnalysis = nil
    }
    
    func pan(dx: CGFloat, dy: CGFloat) {
        let rangeX = maxX - minX
        let rangeY = maxY - minY
        
        // Calculate delta based on screen movement and current range
        let deltaX = Double(dx) * rangeX / 300
        let deltaY = Double(dy) * rangeY / 300
        
        minX -= deltaX
        maxX -= deltaX
        minY += deltaY
        maxY += deltaY
    }
    
    private func updateGridSpacing() {
        let range = maxX - minX
        // Calculate an appropriate grid spacing based on the range
        // This ensures that grid lines are not too dense or too sparse
        let magnitude = floor(log10(range / 10))
        
        let adjustedMagnitude = pow(10, magnitude)
        
        if range / adjustedMagnitude < 5 {
            gridSpacing = adjustedMagnitude / 2
        } else if range / adjustedMagnitude > 20 {
            gridSpacing = adjustedMagnitude * 2
        } else {
            gridSpacing = adjustedMagnitude
        }
    }
    
    // MARK: - Function Management
    
    func addFunction(_ expression: String) {
        let color = colors[functions.count % colors.count]
        if let function = GraphFunction.parse(expression, color: color) {
            functions.append(function)
            withAnimation {
                currentAnalysis = "Added function: \(expression)"
            }
        }
    }
    
    func removeFunction(_ function: GraphFunction) {
        functions.removeAll { $0.id == function.id }
        
        // Also remove any related functions (derivatives, integrals)
        let relatedFunctions = functions.filter { $0.relatedToID == function.id }
        for relatedFunction in relatedFunctions {
            functions.removeAll { $0.id == relatedFunction.id }
        }
    }
    
    // MARK: - Mathematical Analysis
    
    func findDerivative(of function: GraphFunction) {
        // Numerical derivative using central difference
        let h = 0.0001
        let derivativeExpr = "(\(function.expression.replacingOccurrences(of: "x", with: "(x+\(h))")) - \(function.expression.replacingOccurrences(of: "x", with: "(x-\(h))")))/(2*\(h))"
        
        // Clean up and simplify the expression if possible
        let cleanDerivExpr = "d/dx[\(function.expression)]"
        
        if let derivative = GraphFunction.parse(derivativeExpr, color: .orange, type: .derivative, relatedToID: function.id) {
            derivative.simplifiedExpression = cleanDerivExpr
            
            // Remove existing derivatives of this function
            functions.removeAll { $0.type == .derivative && $0.relatedToID == function.id }
            
            functions.append(derivative)
            withAnimation {
                currentAnalysis = "Derivative of \(function.expression)\n\nNumerical approximation using central difference method."
            }
        }
    }
    
    func findIntegral(of function: GraphFunction) {
        // For integral visualization, we'll use a simple numerical integration
        // We'll create a new function that approximates the integral
        
        // Start with a simple expression (this would be more sophisticated in a real app)
        let integralExpr = "∫\(function.expression)dx"
        
        // Create a custom evaluator that performs numerical integration
        let integral = GraphFunction(
            expression: integralExpr,
            color: .green,
            type: .integral,
            relatedToID: function.id
        ) { x in
            // Simple trapezoidal integration from a starting point (e.g., 0) to x
            let start = 0.0
            let steps = 100
            let dx = (x - start) / Double(steps)
            var sum = 0.0
            
            // Skip integration if dx is too small
            if abs(dx) < 1e-10 {
                return 0
            }
            
            // Use trapezoidal rule
            if let firstValue = function.evaluate(start), let lastValue = function.evaluate(x) {
                sum = (firstValue + lastValue) / 2.0
                
                for i in 1..<steps {
                    let xi = start + Double(i) * dx
                    if let yi = function.evaluate(xi) {
                        sum += yi
                    }
                }
                
                return sum * dx
            }
            
            return nil
        }
        
        // Remove existing integrals of this function
        functions.removeAll { $0.type == .integral && $0.relatedToID == function.id }
        
        functions.append(integral)
        withAnimation {
            currentAnalysis = "Integral of \(function.expression)\n\nNumerical approximation using the trapezoidal rule."
        }
    }
    
    func findRoots(of function: GraphFunction) {
        // Find x-intercepts using a numerical approach
        var roots: [Double] = []
        let step = (maxX - minX) / 1000
        var lastY: Double?
        
        // Use a simple numerical approach to find sign changes
        for x in stride(from: minX, through: maxX, by: step) {
            if let y = function.evaluate(x) {
                if let previousY = lastY {
                    // Check for sign change
                    if (previousY * y <= 0) && (abs(previousY) < 1e6) && (abs(y) < 1e6) {
                        // Refine the root using bisection method
                        if let refinedRoot = findRootBisection(function: function, a: x - step, b: x, tolerance: 1e-6) {
                            // Only add if it's a new root (not too close to existing ones)
                            if !roots.contains(where: { abs($0 - refinedRoot) < 1e-3 }) {
                                roots.append(refinedRoot)
                            }
                        }
                    }
                }
                lastY = y
            } else {
                lastY = nil
            }
        }
        
        // Generate the analysis text
        if roots.isEmpty {
            currentAnalysis = "No roots found for \(function.expression) in the visible range."
        } else {
            let formattedRoots = roots.map { String(format: "x = %.4f", $0) }.joined(separator: "\n")
            currentAnalysis = "Roots of \(function.expression):\n\n\(formattedRoots)"
        }
    }
    
    private func findRootBisection(function: GraphFunction, a: Double, b: Double, tolerance: Double) -> Double? {
        guard let fa = function.evaluate(a), let fb = function.evaluate(b) else { return nil }
        
        // Ensure that f(a) and f(b) have different signs
        if fa * fb > 0 { return nil }
        
        var left = a
        var right = b
        var iterations = 0
        let maxIterations = 50
        
        while iterations < maxIterations && (right - left) > tolerance {
            let mid = (left + right) / 2
            
            guard let fmid = function.evaluate(mid) else { return nil }
            
            if abs(fmid) < tolerance {
                return mid
            }
            
            if let fleft = function.evaluate(left), fmid * fleft < 0 {
                right = mid
            } else {
                left = mid
            }
            
            iterations += 1
        }
        
        return (left + right) / 2
    }
    
    func findInflectionPoints(of function: GraphFunction) {
        // For inflection points, we need to find points where the second derivative changes sign
        // First, create a function representing the second derivative
        
        // Use central difference for first derivative
        let h1 = 0.001
        let firstDerivativeExpr = "(\(function.expression.replacingOccurrences(of: "x", with: "(x+\(h1))")) - \(function.expression.replacingOccurrences(of: "x", with: "(x-\(h1))")))/(2*\(h1))"
        
        // Now compute second derivative
        let h2 = 0.01
        let secondDerivativeExpr = "(\(firstDerivativeExpr.replacingOccurrences(of: "x", with: "(x+\(h2))")) - \(firstDerivativeExpr.replacingOccurrences(of: "x", with: "(x-\(h2))")))/(2*\(h2))"
        
        // Create a temporary GraphFunction for the second derivative to find zeros
        if let secondDerivative = GraphFunction.parse(secondDerivativeExpr, color: .clear) {
            var inflectionPoints: [Double] = []
            let step = (maxX - minX) / 500
            var lastY: Double?
            
            // Search for sign changes in the second derivative
            for x in stride(from: minX, through: maxX, by: step) {
                if let y = secondDerivative.evaluate(x) {
                    if let previousY = lastY {
                        // Check for sign change
                        if (previousY * y <= 0) && (abs(previousY) < 1e6) && (abs(y) < 1e6) {
                            // Refine using bisection
                            if let refinedPoint = findRootBisection(function: secondDerivative, a: x - step, b: x, tolerance: 1e-6) {
                                // Only add if it's a new point
                                if !inflectionPoints.contains(where: { abs($0 - refinedPoint) < 1e-3 }) {
                                    inflectionPoints.append(refinedPoint)
                                }
                            }
                        }
                    }
                    lastY = y
                } else {
                    lastY = nil
                }
            }
            
            // Generate analysis text
            if inflectionPoints.isEmpty {
                currentAnalysis = "No inflection points found for \(function.expression) in the visible range."
            } else {
                var analysisText = "Inflection points of \(function.expression):\n\n"
                
                for point in inflectionPoints {
                    if let y = function.evaluate(point) {
                        analysisText += "x = \(String(format: "%.4f", point)), y = \(String(format: "%.4f", y))\n"
                    }
                }
                
                analysisText += "\nAt these points, the function changes from concave up to concave down (or vice versa)."
                currentAnalysis = analysisText
            }
        } else {
            currentAnalysis = "Could not calculate inflection points for this function."
        }
    }
}

// Extension to handle the case where GraphFunction needs related ID
extension GraphFunction {
    var relatedToID: UUID?
    var simplifiedExpression: String?
    
    init(expression: String, color: Color = .blue, type: FunctionType = .standard, relatedToID: UUID? = nil, evaluator: @escaping (Double) -> Double?) {
        self.expression = expression
        self.color = color
        self.type = type
        self.evaluator = evaluator
        self.relatedToID = relatedToID
    }
} 