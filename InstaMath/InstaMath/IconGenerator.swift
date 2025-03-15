import SwiftUI

struct IconGenerator: View {
    var size: CGFloat = 200
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [.blue, .purple]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Math symbols layer
            VStack(spacing: 8) {
                Text("InstaMath")
                    .font(.system(size: size * 0.24, weight: .bold))
                    .foregroundColor(.white)
                
                VStack(spacing: size * 0.06) {
                    Text("∑ √")
                        .font(.system(size: size * 0.2, weight: .bold))
                    Text("ƒ(x)")
                        .font(.system(size: size * 0.24, weight: .bold))
                    Text("π ∫")
                        .font(.system(size: size * 0.2, weight: .bold))
                }
                .foregroundColor(.white)
            }
            .shadow(radius: size * 0.01)
        }
        .frame(width: size, height: size)
    }
}

struct IconPreview: View {
    var body: some View {
        VStack(spacing: 20) {
            IconGenerator(size: 1024)
                .frame(width: 200, height: 200)
                .previewDisplayName("App Store")
            
            IconGenerator(size: 180)
                .previewDisplayName("iPhone Home")
            
            IconGenerator(size: 76)
                .previewDisplayName("iPad Home")
        }
        .padding()
    }
}

#Preview {
    IconPreview()
} 