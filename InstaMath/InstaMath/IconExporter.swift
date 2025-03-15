import SwiftUI

struct IconSize {
    let size: CGFloat
    let idiom: String
    let scale: Int
    
    var pointSize: CGFloat { size * CGFloat(scale) }
    var filename: String { "\(Int(size))x\(Int(size))@\(scale)x.png" }
}

struct IconExporter {
    static let sizes: [IconSize] = [
        IconSize(size: 60, idiom: "iphone", scale: 2),
        IconSize(size: 60, idiom: "iphone", scale: 3),
        IconSize(size: 76, idiom: "ipad", scale: 1),
        IconSize(size: 76, idiom: "ipad", scale: 2),
        IconSize(size: 83.5, idiom: "ipad", scale: 2),
        IconSize(size: 1024, idiom: "ios-marketing", scale: 1)
    ]
}

#Preview {
    VStack {
        Text("Icon Sizes:")
            .font(.headline)
        ForEach(IconExporter.sizes, id: \.filename) { size in
            Text("\(size.filename) - \(Int(size.pointSize))x\(Int(size.pointSize))")
                .font(.caption)
        }
        IconGenerator()
            .frame(width: 120, height: 120)
    }
    .padding()
} 