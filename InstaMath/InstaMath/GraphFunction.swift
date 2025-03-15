import SwiftUI
import Foundation

struct GraphFunction: Identifiable {
    let id = UUID()
    let expression: String
    let color: Color
    let type: FunctionType
    private(set) var relatedToID: UUID?
    private(set) var simplifiedExpression: String?
    
    enum FunctionType {
        case standard
        case derivative
        case integral
    }
    
    let evaluator: (Double) -> Double?
    
    init(expression: String, color: Color = .blue, type: FunctionType = .standard, relatedToID: UUID? = nil, evaluator: @escaping (Double) -> Double?) {
        self.expression = expression
        self.color = color
        self.type = type
        self.relatedToID = relatedToID
        self.evaluator = evaluator
    }
    
    func evaluate(_ x: Double) -> Double? {
        return evaluator(x)
    }
    
    mutating func setSimplifiedExpression(_ expr: String) {
        simplifiedExpression = expr
    }
    
    func getDisplayExpression() -> String {
        return simplifiedExpression ?? expression
    }
    
    static func parse(_ expression: String, color: Color = .blue, type: FunctionType = .standard, relatedToID: UUID? = nil) -> GraphFunction? {
        let cleanExpression = cleanUpExpression(expression)
        
        // Test if the expression is valid with a sample value
        let testExpr = cleanExpression.replacingOccurrences(of: "x", with: "1")
        guard let _ = try? NSExpression(format: testExpr).expressionValue(with: nil, context: nil) as? Double else {
            return nil
        }
        
        return GraphFunction(expression: expression, color: color, type: type, relatedToID: relatedToID) { x in
            let expr = cleanExpression.replacingOccurrences(of: "x", with: "\(x)")
            
            // Handle potential errors in evaluation
            do {
                if let result = try NSExpression(format: expr).expressionValue(with: nil, context: nil) as? Double {
                    // Check if the result is valid (not NaN or Infinite)
                    if result.isFinite {
                        return result
                    }
                }
                return nil
            } catch {
                return nil
            }
        }
    }
    
    private static func cleanUpExpression(_ expression: String) -> String {
        var cleanExpression = expression
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "^", with: "**")
            .replacingOccurrences(of: "π", with: "3.14159265359")
            .replacingOccurrences(of: "pi", with: "3.14159265359")
            .replacingOccurrences(of: "e", with: "2.71828182846")
        
        // Replace common math functions
        cleanExpression = cleanExpression
            .replacingOccurrences(of: "sin", with: "sin")
            .replacingOccurrences(of: "cos", with: "cos")
            .replacingOccurrences(of: "tan", with: "tan")
            .replacingOccurrences(of: "sqrt", with: "sqrt")
            .replacingOccurrences(of: "log", with: "log")
            .replacingOccurrences(of: "ln", with: "ln")
            .replacingOccurrences(of: "abs", with: "abs")
        
        return cleanExpression
    }
} 