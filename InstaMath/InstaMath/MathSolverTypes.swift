import Foundation

// Basic math solution structure
struct MathSolution: Identifiable {
    let id = UUID()
    let problem: String
    let result: String
    let steps: [String]
    let timestamp: Date
    let complexity: ProblemComplexity
    let domain: MathDomain
    let formulaType: FormulaType?
    let relatedConcepts: [String]
    
    init(problem: String, result: String, steps: [String], 
         complexity: ProblemComplexity = .basic,
         domain: MathDomain = .general,
         formulaType: FormulaType? = nil,
         relatedConcepts: [String] = []) {
        self.problem = problem
        self.result = result
        self.steps = steps
        self.timestamp = Date()
        self.complexity = complexity
        self.domain = domain
        self.formulaType = formulaType
        self.relatedConcepts = relatedConcepts
    }
}

// Enhanced types for engineering and advanced math
enum ProblemComplexity: String, Codable, CaseIterable {
    case basic
    case intermediate
    case advanced
    case research
}

enum MathDomain: String, Codable, CaseIterable {
    case general
    case algebra
    case calculus
    case linearAlgebra
    case differentialEquations
    case statistics
    case discreteMath
    case mechanics
    case thermodynamics
    case fluidDynamics
    case circuitAnalysis
    case signalProcessing
}

enum FormulaType: String, Codable, CaseIterable {
    // General Mathematics
    case algebraic
    case trigonometric
    case exponential
    case logarithmic
    
    // Calculus
    case derivative
    case integral
    case multipleIntegral
    case series
    case vectorCalculus
    
    // Linear Algebra
    case matrix
    case linearSystem
    case eigenvalue
    case vectorSpace
    
    // Differential Equations
    case ordinaryDE
    case partialDE
    case systemOfDE
    
    // Engineering specific
    case mechanicsFormula
    case circuitFormula
    case thermodynamicsLaw
    case fluidDynamicsEquation
    case controlSystem
    case structuralAnalysis
}

// Mathematical notation types for OCR
struct MathSymbol: Identifiable {
    let id = UUID()
    let symbol: String
    let type: MathSymbolType
    let boundingBox: CGRect
    let confidence: Float
}

enum MathSymbolType: String, Codable {
    case digit
    case operator_basic // +, -, *, /
    case operator_advanced // ∂, ∫, ∑, ∇, etc.
    case variable
    case bracket
    case function // sin, cos, log, etc.
    case matrix
    case fraction
    case exponent
    case subScript
    case root
    case equality
    case inequality
    case specialConstant // π, e, i, etc.
    case unit // m, kg, s, etc.
}

// Engineering diagram recognition
struct EngineeringDiagram: Identifiable {
    let id = UUID()
    let type: DiagramType
    let components: [DiagramComponent]
    let boundingBox: CGRect
}

enum DiagramType: String, Codable {
    case circuit
    case freebody
    case flowchart
    case structuralDiagram
    case statespaceDiagram
    case controlSystem
}

struct DiagramComponent: Identifiable {
    let id = UUID()
    let type: ComponentType
    let label: String?
    let value: String?
    let boundingBox: CGRect
    let connections: [UUID] // IDs of connected components
}

enum ComponentType: String, Codable {
    // General
    case node
    case line
    case arrow
    case text
    
    // Circuit specific
    case resistor
    case capacitor
    case inductor
    case voltage_source
    case current_source
    case transistor
    case diode
    case ground
    
    // Mechanical
    case force
    case moment
    case support
    case joint
    case beam
    
    // Control systems
    case block
    case summing_junction
    case transfer_function
} 