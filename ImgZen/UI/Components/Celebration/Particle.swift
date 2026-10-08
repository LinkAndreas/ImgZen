import SwiftUI

/// A heart or sparkle in a celebration burst, and how it flies.
struct Particle: Identifiable {
    let id = UUID()
    let symbol: String
    let color: Color
    /// Horizontal start, as a fraction of the width.
    let startX: CGFloat
    /// Sideways drift in points.
    let drift: CGFloat
    /// How high it rises, as a fraction of the height.
    let rise: CGFloat
    let size: CGFloat
    let rotation: Double
    let delay: Double
    let duration: Double

    static func random() -> Particle {
        Particle(
            symbol: Int.random(in: 0..<4) == 0 ? "sparkle" : "heart.fill",
            color: [.pink, .red, .orange, .yellow, .purple, .mint].randomElement()!,
            startX: .random(in: 0.15...0.85),
            drift: .random(in: -90...90),
            rise: .random(in: 0.45...0.9),
            size: .random(in: 14...32),
            rotation: .random(in: -45...45),
            delay: .random(in: 0...0.35),
            duration: .random(in: 1.4...2.2)
        )
    }

    static var calm: Particle {
        Particle(symbol: "heart.fill", color: .pink, startX: 0.5, drift: 0, rise: 0.45, size: 56, rotation: 0, delay: 0, duration: 1.4)
    }
}
