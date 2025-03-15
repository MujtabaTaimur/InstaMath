import SwiftUI
import Vision
import Foundation

#if canImport(UIKit)
import UIKit
typealias PlatformImage = UIImage
#else
import AppKit
typealias PlatformImage = NSImage
#endif

@MainActor
class MathSolverViewModel: ObservableObject {
    @Published var capturedImage: PlatformImage?
    @Published var solution: MathSolution?
    @Published var isProcessing = false
    @Published var solutionHistory: [MathSolution] = []
    
    private var textRecognitionRequest: VNRecognizeTextRequest?
    private var advancedMathOCR: AdvancedMathOCR?
    
    init() {
        setupVision()
        advancedMathOCR = AdvancedMathOCR()
    }
    
    private func setupVision() {
        textRecognitionRequest = VNRecognizeTextRequest { [weak self] request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation],
                  error == nil else {
                return
            }
            
            let recognizedStrings = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }
            
            Task { @MainActor in
                self?.processMathProblem(from: recognizedStrings.joined(separator: " "))
            }
        }
        
        textRecognitionRequest?.recognitionLevel = .accurate
        textRecognitionRequest?.usesLanguageCorrection = true
    }
    
    func processImage() {
        guard let image = capturedImage else { return }
        
        #if os(iOS)
        guard let cgImage = image.cgImage else { return }
        #else
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return }
        #endif
        
        isProcessing = true
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        Task {
            do {
                try requestHandler.perform([textRecognitionRequest].compactMap { $0 })
                
                // Also try to recognize advanced math formulas using our custom OCR
                if let advancedMathOCR = advancedMathOCR {
                    let _ = try? await advancedMathOCR.recognizeMathFormula(from: image)
                }
            } catch {
                print("Failed to perform OCR: \(error)")
                await MainActor.run {
                    self.isProcessing = false
                }
            }
        }
    }
    
    func clearImage() {
        capturedImage = nil
        solution = nil
    }
    
    private func processMathProblem(from text: String) {
        // Clean and parse the text to extract mathematical expression
        let problem = cleanMathExpression(text)
        
        // Analyze the problem to determine domain, complexity, and formula type
        let (domain, complexity, formulaType) = analyzeProblem(problem)
        
        // Solve the mathematical expression
        let (result, steps) = solveMathProblem(problem, domain: domain)
        
        // Determine related concepts based on the problem
        let relatedConcepts = determineRelatedConcepts(problem: problem, domain: domain, formulaType: formulaType)
        
        // Create solution object with enhanced properties
        let solution = MathSolution(
            problem: problem,
            result: result,
            steps: steps,
            complexity: complexity,
            domain: domain,
            formulaType: formulaType,
            relatedConcepts: relatedConcepts
        )
        
        // Update UI
        self.solution = solution
        self.solutionHistory.insert(solution, at: 0)
        self.isProcessing = false
    }
    
    private func cleanMathExpression(_ text: String) -> String {
        // Improved cleaning to preserve more mathematical symbols
        var cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Replace common OCR errors in mathematical symbols
        cleaned = cleaned.replacingOccurrences(of: "×", with: "*")
        cleaned = cleaned.replacingOccurrences(of: "÷", with: "/")
        
        // Preserve more mathematical symbols for advanced problems
        return cleaned
    }
    
    private func analyzeProblem(_ problem: String) -> (MathDomain, ProblemComplexity, FormulaType?) {
        // Determine the domain of the problem
        let domain: MathDomain
        let complexity: ProblemComplexity
        let formulaType: FormulaType?
        
        // Check for calculus indicators
        if problem.contains("∫") || problem.contains("dx") || problem.contains("dy") {
            domain = .calculus
            formulaType = .integral
            complexity = .intermediate
        }
        // Check for derivatives
        else if problem.contains("d/dx") || problem.contains("d/dy") || problem.contains("'") {
            domain = .calculus
            formulaType = .derivative
            complexity = .intermediate
        }
        // Check for linear algebra
        else if problem.contains("matrix") || problem.contains("[") && problem.contains("]") {
            domain = .linearAlgebra
            formulaType = .matrix
            complexity = .intermediate
        }
        // Check for differential equations
        else if problem.contains("d²y/dx²") || problem.contains("d^2y/dx^2") {
            domain = .differentialEquations
            formulaType = .ordinaryDE
            complexity = .advanced
        }
        // Check for trigonometry
        else if problem.contains("sin") || problem.contains("cos") || problem.contains("tan") {
            domain = .algebra
            formulaType = .trigonometric
            complexity = .intermediate
        }
        // Check for logarithms
        else if problem.contains("log") || problem.contains("ln") {
            domain = .algebra
            formulaType = .logarithmic
            complexity = .intermediate
        }
        // Check for exponentials
        else if problem.contains("e^") || problem.contains("exp") {
            domain = .algebra
            formulaType = .exponential
            complexity = .intermediate
        }
        // Default to basic algebra
        else {
            domain = .algebra
            formulaType = .algebraic
            complexity = .basic
        }
        
        // Adjust complexity based on problem length and symbols
        let symbolCount = problem.filter { "+-*/^()=[]{}".contains($0) }.count
        if symbolCount > 10 {
            return (domain, .advanced, formulaType)
        } else if symbolCount > 5 {
            return (domain, .intermediate, formulaType)
        }
        
        return (domain, complexity, formulaType)
    }
    
    private func determineRelatedConcepts(problem: String, domain: MathDomain, formulaType: FormulaType?) -> [String] {
        var concepts: [String] = []
        
        // Add domain-specific concepts
        switch domain {
        case .algebra:
            concepts.append("Algebraic manipulation")
            if problem.contains("=") {
                concepts.append("Equation solving")
            }
            if problem.contains("x") && problem.contains("y") {
                concepts.append("Multiple variables")
            }
            
        case .calculus:
            if formulaType == .integral {
                concepts.append("Integration")
                if problem.contains("dx dx") || problem.contains("dy dx") {
                    concepts.append("Multiple integrals")
                }
            } else if formulaType == .derivative {
                concepts.append("Differentiation")
                if problem.contains("d²") || problem.contains("d^2") {
                    concepts.append("Higher-order derivatives")
                }
            }
            
        case .linearAlgebra:
            concepts.append("Matrices")
            if problem.contains("det") {
                concepts.append("Determinants")
            }
            if problem.contains("eigen") {
                concepts.append("Eigenvalues")
                concepts.append("Eigenvectors")
            }
            
        case .differentialEquations:
            concepts.append("Differential equations")
            if problem.contains("d²y/dx²") {
                concepts.append("Second-order ODEs")
            }
            
        default:
            break
        }
        
        // Add formula-specific concepts
        if let formulaType = formulaType {
            switch formulaType {
            case .trigonometric:
                concepts.append("Trigonometric functions")
                if problem.contains("sin") && problem.contains("cos") {
                    concepts.append("Trigonometric identities")
                }
                
            case .logarithmic:
                concepts.append("Logarithms")
                if problem.contains("ln") {
                    concepts.append("Natural logarithm")
                }
                
            case .exponential:
                concepts.append("Exponential functions")
                
            default:
                break
            }
        }
        
        return concepts
    }
    
    private func solveMathProblem(_ problem: String, domain: MathDomain) -> (String, [String]) {
        var steps: [String] = []
        
        // Basic expression evaluation
        // This is a simplified version - you would want to implement a more robust
        // mathematical expression parser and solver in a production app
        
        let components = problem.components(separatedBy: "=")
        let expression = components[0].trimmingCharacters(in: .whitespaces)
        
        // Add parsing step
        steps.append("Parsed expression: \(expression)")
        
        // For more complex domains, we would use specialized solvers
        if domain != .algebra && domain != .general {
            // Simulate a more complex solution for advanced domains
            steps.append("Analyzing \(domain.rawValue) problem")
            
            // Add domain-specific steps
            switch domain {
            case .calculus:
                steps.append("Applying calculus techniques")
                if problem.contains("∫") {
                    steps.append("Identifying integration method")
                    steps.append("Applying integration rules")
                } else if problem.contains("d/dx") {
                    steps.append("Applying differentiation rules")
                }
                
            case .linearAlgebra:
                steps.append("Parsing matrix structure")
                steps.append("Applying linear algebra operations")
                
            case .differentialEquations:
                steps.append("Classifying differential equation")
                steps.append("Applying solution method")
                
            default:
                break
            }
            
            // Return a simulated result for advanced problems
            return ("Solution: See detailed steps", steps)
        }
        
        // For basic algebra, evaluate the expression
        let result: Double
        
        do {
            let expr = NSExpression(format: expression)
            if let value = expr.expressionValue(with: nil, context: nil) as? Double {
                result = value
                steps.append("Evaluated expression")
            } else {
                return ("Error: Invalid expression", ["Could not evaluate the expression"])
            }
        } catch {
            return ("Error: Invalid expression", ["Could not evaluate the expression"])
        }
        
        // Format the result
        let formattedResult = String(format: "%.2f", result)
        steps.append("Final result: \(formattedResult)")
        
        return (formattedResult, steps)
    }
}

// Preview helper
extension MathSolverViewModel {
    static var preview: MathSolverViewModel {
        let vm = MathSolverViewModel()
        vm.solution = MathSolution(
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
        )
        return vm
    }
} 
