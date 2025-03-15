import Foundation
import Vision
import CoreML

#if canImport(UIKit)
import UIKit
#endif

protocol MathRecognitionService {
    func recognizeMathFormula(from image: PlatformImage) async throws -> RecognizedMathFormula
    func recognizeEngineeringDiagram(from image: PlatformImage) async throws -> EngineeringDiagram?
    func classifyFormulaType(from text: String) async -> FormulaType?
}

struct RecognizedMathFormula {
    let rawText: String
    let structuredFormula: String // LaTeX or MathML representation
    let symbols: [MathSymbol]
    let confidence: Float
    let domain: MathDomain
    let detectedFormulaType: FormulaType?
}

class AdvancedMathOCR: ObservableObject, MathRecognitionService {
    private var symbolDetectionModel: VNCoreMLModel?
    private var formulaClassificationModel: VNCoreMLModel?
    private var diagramRecognitionModel: VNCoreMLModel?
    
    private let mathExpressionParser: MathExpressionParser
    
    enum OCRError: Error {
        case imageFormatError
        case recognitionFailed
        case modelLoadingFailed
        case parsingFailed
    }
    
    init() {
        // Initialize the math expression parser
        mathExpressionParser = MathExpressionParser()
        
        // Load CoreML models if available
        do {
            if let mathSymbolsModelURL = Bundle.main.url(forResource: "MathSymbolDetector", withExtension: "mlmodelc") {
                symbolDetectionModel = try VNCoreMLModel(for: MLModel(contentsOf: mathSymbolsModelURL))
            } else {
                symbolDetectionModel = nil
                print("Math symbol detection model not found, falling back to Vision text recognition")
            }
            
            if let formulaClassifierURL = Bundle.main.url(forResource: "FormulaClassifier", withExtension: "mlmodelc") {
                formulaClassificationModel = try VNCoreMLModel(for: MLModel(contentsOf: formulaClassifierURL))
            } else {
                formulaClassificationModel = nil
                print("Formula classification model not found, falling back to heuristic classification")
            }
            
            if let diagramRecognizerURL = Bundle.main.url(forResource: "EngineeringDiagramRecognizer", withExtension: "mlmodelc") {
                diagramRecognitionModel = try VNCoreMLModel(for: MLModel(contentsOf: diagramRecognizerURL))
            } else {
                diagramRecognitionModel = nil
                print("Engineering diagram recognition model not found, diagram recognition will be limited")
            }
        } catch {
            symbolDetectionModel = nil
            formulaClassificationModel = nil
            diagramRecognitionModel = nil
            print("Failed to load CoreML models: \(error.localizedDescription)")
        }
    }
    
    func recognizeMathFormula(from image: PlatformImage) async throws -> RecognizedMathFormula {
        // 1. Use Vision for basic text recognition as fallback
        let recognizedText = try await performBasicTextRecognition(image)
        
        // 2. If specialized model is available, use it for math symbol detection
        let mathSymbols = try await detectMathSymbols(from: image)
        
        // 3. Convert recognized text to structured format (LaTeX or MathML)
        let structuredFormula = mathExpressionParser.convertToStructuredFormat(text: recognizedText, symbols: mathSymbols)
        
        // 4. Classify the formula to determine its type and domain
        let formulaType = await classifyFormulaType(from: structuredFormula)
        let domain = await determineMathDomain(from: structuredFormula, formulaType: formulaType)
        
        // 5. Calculate overall confidence
        let confidence = calculateRecognitionConfidence(symbols: mathSymbols)
        
        return RecognizedMathFormula(
            rawText: recognizedText,
            structuredFormula: structuredFormula,
            symbols: mathSymbols,
            confidence: confidence,
            domain: domain,
            detectedFormulaType: formulaType
        )
    }
    
    private func performBasicTextRecognition(_ image: PlatformImage) async throws -> String {
        #if os(iOS)
        guard let cgImage = image.cgImage else {
            throw OCRError.imageFormatError
        }
        #else
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw OCRError.imageFormatError
        }
        #endif
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        return try await withCheckedThrowingContinuation { continuation in
            let textRecognitionRequest = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(throwing: OCRError.recognitionFailed)
                    return
                }
                
                let recognizedText = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }.joined(separator: " ")
                
                continuation.resume(returning: recognizedText)
            }
            
            textRecognitionRequest.recognitionLevel = .accurate
            textRecognitionRequest.usesLanguageCorrection = false // Disable for math formulas
            textRecognitionRequest.recognitionLanguages = ["en-US"]
            
            do {
                try requestHandler.perform([textRecognitionRequest])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    private func detectMathSymbols(from image: PlatformImage) async throws -> [MathSymbol] {
        // If specialized CoreML model is available, use it
        if let symbolModel = symbolDetectionModel {
            return try await detectSymbolsWithCoreML(image, model: symbolModel)
        }
        
        // Otherwise, use a heuristic approach with Vision framework
        return try await detectSymbolsHeuristically(image)
    }
    
    private func detectSymbolsWithCoreML(_ image: PlatformImage, model: VNCoreMLModel) async throws -> [MathSymbol] {
        #if os(iOS)
        guard let cgImage = image.cgImage else {
            throw OCRError.imageFormatError
        }
        #else
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw OCRError.imageFormatError
        }
        #endif
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        return try await withCheckedThrowingContinuation { continuation in
            let symbolDetectionRequest = VNCoreMLRequest(model: model) { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let results = request.results as? [VNRecognizedObjectObservation] else {
                    continuation.resume(returning: [])
                    return
                }
                
                let symbols = results
                    .filter { observation in
                        guard let topClassification = observation.labels.first,
                              let symbolTypeString = topClassification.identifier.components(separatedBy: ":").first,
                              let _ = MathSymbolType(rawValue: symbolTypeString) else {
                            return false
                        }
                        return true
                    }
                    .map { observation in
                        let topClassification = observation.labels.first!
                        let symbolTypeString = topClassification.identifier.components(separatedBy: ":").first!
                        let symbolType = MathSymbolType(rawValue: symbolTypeString)!
                        let symbolValue = topClassification.identifier.components(separatedBy: ":").last ?? ""
                        
                        return MathSymbol(
                            symbol: symbolValue,
                            type: symbolType,
                            boundingBox: observation.boundingBox,
                            confidence: topClassification.confidence
                        )
                    }
                
                continuation.resume(returning: symbols)
            }
            
            do {
                try requestHandler.perform([symbolDetectionRequest])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    private func detectSymbolsHeuristically(_ image: PlatformImage) async throws -> [MathSymbol] {
        // Implement a heuristic approach for symbol detection
        // This is just a placeholder - in a real implementation, we would:
        // 1. Use character recognition with custom settings optimized for math
        // 2. Apply post-processing to identify math symbols based on context
        // 3. Group and classify detected elements
        
        // For now, just return an empty array
        return []
    }
    
    func classifyFormulaType(from text: String) async -> FormulaType? {
        // This would use ML to classify the formula type
        // For now, use simple heuristics
        
        if text.contains("∫") { return .integral }
        if text.contains("∂") { return .partialDE }
        if text.contains("d/dx") { return .derivative }
        if text.contains("=") && text.contains("matrix") { return .matrix }
        if text.contains("=") && text.contains("sin") || text.contains("cos") { return .trigonometric }
        if text.contains("log") { return .logarithmic }
        if text.contains("e^") { return .exponential }
        
        // Default to algebraic for simple equations
        if text.contains("=") { return .algebraic }
        
        return nil
    }
    
    private func determineMathDomain(from formula: String, formulaType: FormulaType?) async -> MathDomain {
        // Based on formula and its type, determine the mathematical domain
        // This is a simplified implementation
        
        switch formulaType {
        case .integral, .derivative, .multipleIntegral, .series, .vectorCalculus:
            return .calculus
        case .matrix, .linearSystem, .eigenvalue, .vectorSpace:
            return .linearAlgebra
        case .ordinaryDE, .partialDE, .systemOfDE:
            return .differentialEquations
        case .mechanicsFormula:
            return .mechanics
        case .circuitFormula:
            return .circuitAnalysis
        case .thermodynamicsLaw:
            return .thermodynamics
        case .fluidDynamicsEquation:
            return .fluidDynamics
        default:
            // Use more advanced heuristics based on the formula text
            if formula.contains("∇") || formula.contains("curl") || formula.contains("div") {
                return .calculus
            } else if formula.contains("matrix") || formula.contains("det") {
                return .linearAlgebra
            } else if formula.contains("P") && formula.contains("V") && (formula.contains("T") || formula.contains("°")) {
                return .thermodynamics
            } else if formula.contains("F") && formula.contains("m") && formula.contains("a") {
                return .mechanics
            }
            
            return .general
        }
    }
    
    private func calculateRecognitionConfidence(symbols: [MathSymbol]) -> Float {
        // Calculate overall confidence based on individual symbol confidences
        if symbols.isEmpty {
            return 0.5 // Default confidence when using basic OCR
        }
        
        let totalConfidence = symbols.reduce(0.0) { sum, symbol in sum + symbol.confidence }
        return totalConfidence / Float(symbols.count)
    }
    
    func recognizeEngineeringDiagram(from image: PlatformImage) async throws -> EngineeringDiagram? {
        // Placeholder for engineering diagram recognition
        // Would require a specialized model for this task
        return nil
    }
}

class MathExpressionParser {
    func convertToStructuredFormat(text: String, symbols: [MathSymbol]) -> String {
        // Convert recognized text into LaTeX or MathML
        // This is a placeholder implementation
        
        // For now, just do some basic LaTeX conversion
        var latexFormula = text
        
        // Replace some common mathematical notations
        latexFormula = latexFormula.replacingOccurrences(of: "sqrt", with: "\\sqrt")
        latexFormula = latexFormula.replacingOccurrences(of: "^2", with: "^{2}")
        latexFormula = latexFormula.replacingOccurrences(of: "pi", with: "\\pi")
        latexFormula = latexFormula.replacingOccurrences(of: "theta", with: "\\theta")
        
        // Handle fractions (very basic implementation)
        if latexFormula.contains("/") {
            let components = latexFormula.components(separatedBy: "/")
            if components.count == 2 {
                latexFormula = "\\frac{\(components[0])}{\(components[1])}"
            }
        }
        
        return latexFormula
    }
} 