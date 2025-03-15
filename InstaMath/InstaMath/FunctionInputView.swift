import SwiftUI

struct FunctionInputView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: GraphingViewModel
    @State private var expression = ""
    @State private var showingHelp = false
    @State private var errorMessage: String?
    @State private var selectedCategory = 0
    @FocusState private var expressionFieldIsFocused: Bool
    
    private let functionCategories = [
        "Basic": ["x", "x^2", "x^3", "1/x", "sqrt(x)", "|x|"],
        "Trigonometric": ["sin(x)", "cos(x)", "tan(x)", "asin(x)", "acos(x)", "atan(x)"],
        "Exponential": ["e^x", "log(x)", "ln(x)", "2^x", "x*log(x)"],
        "Combined": ["sin(x)/x", "x^2*cos(x)", "e^(-x^2)", "sin(x^2)", "sqrt(1-x^2)"]
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Expression input card
                VStack(alignment: .leading, spacing: 12) {
                    Text("Enter Function")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack {
                        Text("f(x) =")
                            .font(.system(.body, design: .serif))
                            .foregroundColor(.secondary)
                        
                        TextField("sin(x) + x^2", text: $expression)
                            .font(.system(.body, design: .serif))
                            .padding(10)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .focused($expressionFieldIsFocused)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .keyboardType(.asciiCapable)
                            .submitLabel(.done)
                            .onSubmit {
                                addFunction()
                            }
                    }
                    
                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.top, 4)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 1)
                .padding([.horizontal, .top])
                
                // Function templates
                VStack(alignment: .leading, spacing: 12) {
                    Text("Common Functions")
                        .font(.headline)
                        .padding(.bottom, 4)
                    
                    // Category picker
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(0..<Array(functionCategories.keys).sorted().count, id: \.self) { index in
                            Text(Array(functionCategories.keys).sorted()[index])
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.bottom, 8)
                    
                    // Function buttons
                    let category = Array(functionCategories.keys).sorted()[selectedCategory]
                    functionButtonsGrid(for: category)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 1)
                .padding(.horizontal)
                
                // Operators panel
                VStack(alignment: .leading, spacing: 12) {
                    Text("Operators & Symbols")
                        .font(.headline)
                        .padding(.bottom, 4)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(["+", "-", "*", "/", "(", ")", "^", ".", "π", "e"], id: \.self) { op in
                            Button(action: {
                                insertText(op)
                                // Keep keyboard focus after inserting
                                expressionFieldIsFocused = true
                            }) {
                                Text(op)
                                    .font(.system(.title3, design: .serif))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 44)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.primary)
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 1)
                .padding(.horizontal)
                
                Spacer()
                
                // Help button
                Button(action: { showingHelp = true }) {
                    HStack {
                        Image(systemName: "questionmark.circle")
                        Text("Function Guide")
                    }
                    .padding()
                    .foregroundColor(.blue)
                }
            }
            .padding(.vertical)
            .navigationTitle("Add Function")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addFunction()
                    }
                    .disabled(expression.isEmpty)
                    .foregroundColor(expression.isEmpty ? .gray : .blue)
                }
                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Spacer()
                        Button("Done") {
                            expressionFieldIsFocused = false
                        }
                    }
                }
            }
            .sheet(isPresented: $showingHelp) {
                FunctionHelpView()
            }
            .onAppear {
                // Focus the text field when the view appears
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    expressionFieldIsFocused = true
                }
            }
        }
    }
    
    private func functionButtonsGrid(for category: String) -> some View {
        let functions = functionCategories[category] ?? []
        
        return LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            ForEach(functions, id: \.self) { func_expr in
                Button(action: {
                    expression = func_expr
                }) {
                    Text(func_expr)
                        .font(.system(.body, design: .serif))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray6))
                        .foregroundColor(.primary)
                        .cornerRadius(8)
                }
            }
        }
    }
    
    private func insertText(_ text: String) {
        // Insert at cursor position
        if let selectedRange = NSRange(expression.startIndex..<expression.endIndex, in: expression) as? NSRange {
            let newText = (expression as NSString).replacingCharacters(in: selectedRange, with: text)
            expression = newText
        } else {
            expression += text
        }
    }
    
    private func addFunction() {
        // Try to parse the function
        if let _ = GraphFunction.parse(expression) {
            viewModel.addFunction(expression)
            expressionFieldIsFocused = false
            dismiss()
        } else {
            errorMessage = "Invalid expression. Check the syntax and try again."
            
            // Analyze the expression to provide more helpful error messages
            if expression.contains("**") {
                errorMessage = "Use '^' for exponents, not '**'. Example: x^2"
            } else if expression.contains(")(") {
                errorMessage = "Missing operator between parentheses. Example: (x+1)*(x-1)"
            } else if !isBalancedParentheses(expression) {
                errorMessage = "Unbalanced parentheses. Check your expression."
            }
            
            // Gently shake the text field to indicate error
            withAnimation(.spring()) {
                expressionFieldIsFocused = true
            }
        }
    }
    
    private func isBalancedParentheses(_ expression: String) -> Bool {
        var count = 0
        for char in expression {
            if char == "(" {
                count += 1
            } else if char == ")" {
                count -= 1
                if count < 0 {
                    return false
                }
            }
        }
        return count == 0
    }
}

struct FunctionHelpView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Basic syntax
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Basic Syntax")
                            .font(.headline)
                            .padding(.bottom, 4)
                        
                        helpItem(symbol: "+", description: "Addition: x + 2")
                        helpItem(symbol: "-", description: "Subtraction: x - 1")
                        helpItem(symbol: "*", description: "Multiplication: 2 * x")
                        helpItem(symbol: "/", description: "Division: x / 3")
                        helpItem(symbol: "^", description: "Exponentiation: x^2")
                        helpItem(symbol: "()", description: "Grouping: (x + 1)^2")
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Function syntax
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Function Syntax")
                            .font(.headline)
                            .padding(.bottom, 4)
                        
                        helpItem(symbol: "sin(x)", description: "Sine function")
                        helpItem(symbol: "cos(x)", description: "Cosine function")
                        helpItem(symbol: "tan(x)", description: "Tangent function")
                        helpItem(symbol: "sqrt(x)", description: "Square root: √x")
                        helpItem(symbol: "log(x)", description: "Logarithm (base 10)")
                        helpItem(symbol: "ln(x)", description: "Natural logarithm (base e)")
                        helpItem(symbol: "abs(x)", description: "Absolute value: |x|")
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Constants
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Constants")
                            .font(.headline)
                            .padding(.bottom, 4)
                        
                        helpItem(symbol: "π", description: "Pi: 3.14159...")
                        helpItem(symbol: "e", description: "Euler's number: 2.71828...")
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Examples
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Examples")
                            .font(.headline)
                            .padding(.bottom, 4)
                        
                        helpItem(symbol: "x^2 + 2*x + 1", description: "Quadratic function")
                        helpItem(symbol: "sin(x)", description: "Sine wave")
                        helpItem(symbol: "sin(x^2)", description: "Oscillating with increasing frequency")
                        helpItem(symbol: "1/x", description: "Reciprocal function (hyperbola)")
                        helpItem(symbol: "e^(-x^2)", description: "Gaussian bell curve")
                        helpItem(symbol: "sqrt(1-x^2)", description: "Upper half of a circle")
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Function Guide")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func helpItem(symbol: String, description: String) -> some View {
        HStack(alignment: .top) {
            Text(symbol)
                .font(.system(.body, design: .serif))
                .fontWeight(.medium)
                .frame(width: 100, alignment: .leading)
            
            Text(description)
                .font(.body)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}

#Preview {
    FunctionInputView(viewModel: GraphingViewModel())
} 