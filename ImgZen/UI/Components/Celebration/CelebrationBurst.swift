import SwiftUI

/// A burst of colourful hearts and sparkles rising from the bottom of its frame,
/// played each time `trigger` changes — the thank-you after a purchase. Ignores
/// touches. With Reduce Motion, a single heart fades in and out instead.
struct CelebrationBurst: View {
    let trigger: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var bursts: [Burst] = []

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(bursts) { burst in
                    ForEach(burst.particles) { particle in
                        ParticleView(particle: particle, area: proxy.size)
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onChange(of: trigger) {
            let burst = Burst(particles: reduceMotion ? [.calm] : (0..<30).map { _ in .random() })
            bursts.append(burst)
            Task {
                try? await Task.sleep(for: .seconds(3))
                bursts.removeAll { $0.id == burst.id }
            }
        }
    }
}

private struct Burst: Identifiable {
    let id = UUID()
    let particles: [Particle]
}

#if DEBUG
#Preview {
    struct Demo: View {
        @State private var count = 0
        var body: some View {
            Button { count += 1 } label: { Text(verbatim: "Celebrate") }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay { CelebrationBurst(trigger: count) }
        }
    }
    return Demo()
}
#endif
