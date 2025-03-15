import SwiftUI

#if os(iOS)
import UIKit

struct ScientificCalculatorView: View {
    @State private var display = "0"
    @State private var currentNumber = "0"
    @State private var previousNumber = "0"
    @State private var operation: Operation?
    @State private var newNumber = true
    @State private var showingMemory = false
    @State private var memory: Double = 0
    @State private var inDegrees = true
    @State private var showingHistory = false
    @State private var calculationHistory: [(expression: String, result: String)] = []
    
    private enum Operation: String {
        case add = "+"
        case subtract = "-"
        case multiply = "×"
        case divide = "÷"
        case power = "^"
        case percent = "%"
    }
    
    private let buttons: [[CalculatorButton]] = [
        [.memory("MC"), .memory("MR"), .memory("M+"), .memory("M-")],
        [.function("sin"), .function("cos"), .function("tan"), .operation("^")],
        [.function("log"), .constant("π"), .constant("e"), .operation("%")],
        [.clear("AC"), .function("±"), .operation("÷"), .operation("×")],
        [.digit("7"), .digit("8"), .digit("9"), .operation("-")],
        [.digit("4"), .digit("5"), .digit("6"), .operation("+")],
        [.digit("1"), .digit("2"), .digit("3"), .equals],
        [.digit("0"), .digit("."), .function("√"), .function("1/x")]
    ]
    
    var body: some View {
        VStack(spacing: 12) {
            // Display
            VStack {
                Text(display)
                    .font(.system(size: 40, weight: .light))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 2)
                
                if let operation = operation {
                    Text("\(previousNumber) \(operation.rawValue)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .padding()
            
            // Mode Toggle
            Toggle("Degrees", isOn: $inDegrees)
                .padding(.horizontal)
            
            // Buttons Grid
            ForEach(buttons, id: \.self) { row in
                HStack(spacing: 12) {
                    ForEach(row, id: \.id) { button in
                        CalculatorButtonView(button: button) {
                            self.buttonPressed(button)
                        }
                    }
                }
            }
        }
        .navigationTitle("Scientific Calculator")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingHistory = true }) {
                    Image(systemName: "clock.arrow.circlepath")
                }
            }
        }
        .sheet(isPresented: $showingHistory) {
            CalculatorHistoryView(history: calculationHistory)
        }
    }
    
    private func buttonPressed(_ button: CalculatorButton) {
        switch button {
        case .digit(let number):
            if newNumber {
                currentNumber = number
                newNumber = false
            } else {
                currentNumber += number
            }
            display = currentNumber
            
        case .operation(let op):
            if let operation = Operation(rawValue: op) {
                if let current = Double(currentNumber) {
                    if let previous = Double(previousNumber) {
                        let result = calculate(previous, current)
                        display = formatNumber(result)
                        previousNumber = display
                    } else {
                        previousNumber = currentNumber
                    }
                }
                self.operation = operation
                newNumber = true
            }
            
        case .equals:
            if let current = Double(currentNumber),
               let previous = Double(previousNumber),
               let operation = operation {
                let result = calculate(previous, current)
                let expression = "\(previousNumber) \(operation.rawValue) \(currentNumber)"
                calculationHistory.insert((expression, formatNumber(result)), at: 0)
                display = formatNumber(result)
                currentNumber = display
                previousNumber = "0"
                self.operation = nil
                newNumber = true
            }
            
        case .clear:
            display = "0"
            currentNumber = "0"
            previousNumber = "0"
            operation = nil
            newNumber = true
            
        case .function(let function):
            if let current = Double(currentNumber) {
                let result: Double
                switch function {
                case "sin":
                    result = inDegrees ? sin(current * .pi / 180) : sin(current)
                case "cos":
                    result = inDegrees ? cos(current * .pi / 180) : cos(current)
                case "tan":
                    result = inDegrees ? tan(current * .pi / 180) : tan(current)
                case "log":
                    result = log10(current)
                case "±":
                    result = -current
                case "√":
                    result = sqrt(current)
                case "1/x":
                    result = 1 / current
                default:
                    result = current
                }
                display = formatNumber(result)
                currentNumber = display
                newNumber = true
            }
            
        case .constant(let constant):
            switch constant {
            case "π":
                currentNumber = "3.141592653589793"
            case "e":
                currentNumber = "2.718281828459045"
            default:
                break
            }
            display = currentNumber
            newNumber = true
            
        case .memory(let operation):
            if let current = Double(currentNumber) {
                switch operation {
                case "MC":
                    memory = 0
                case "MR":
                    display = formatNumber(memory)
                    currentNumber = display
                    newNumber = true
                case "M+":
                    memory += current
                case "M-":
                    memory -= current
                default:
                    break
                }
            }
        }
    }
    
    private func calculate(_ a: Double, _ b: Double) -> Double {
        guard let operation = operation else { return b }
        
        switch operation {
        case .add:
            return a + b
        case .subtract:
            return a - b
        case .multiply:
            return a * b
        case .divide:
            return a / b
        case .power:
            return pow(a, b)
        case .percent:
            return a * b / 100
        }
    }
    
    private func formatNumber(_ number: Double) -> String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 8
        return formatter.string(from: NSNumber(value: number)) ?? "Error"
    }
}

enum CalculatorButton: Hashable {
    case digit(String)
    case operation(String)
    case function(String)
    case constant(String)
    case memory(String)
    case clear(String)
    case equals
    
    var id: String {
        switch self {
        case .digit(let value),
             .operation(let value),
             .function(let value),
             .constant(let value),
             .memory(let value),
             .clear(let value):
            return value
        case .equals:
            return "="
        }
    }
}

struct CalculatorButtonView: View {
    let button: CalculatorButton
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(button.id)
                .font(.system(size: 24, weight: .medium))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .foregroundColor(.white)
                .background(buttonColor)
                .cornerRadius(12)
        }
    }
    
    private var buttonColor: Color {
        switch button {
        case .digit:
            return Color(.systemGray4)
        case .operation:
            return .blue
        case .function:
            return Color(.systemGray2)
        case .constant:
            return Color(.systemGray)
        case .memory:
            return Color(.systemGray3)
        case .clear:
            return .red
        case .equals:
            return .green
        }
    }
}

struct CalculatorHistoryView: View {
    let history: [(expression: String, result: String)]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List(history, id: \.expression) { item in
                VStack(alignment: .trailing) {
                    Text(item.expression)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(item.result)
                        .font(.headline)
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        ScientificCalculatorView()
    }
}

#else
struct ScientificCalculatorView: View {
    var body: some View {
        Text("Scientific calculator not available on this platform")
            .padding()
    }
}
#endif 