import SwiftUI

/// One particle of a celebration burst, rising and fading out across `area`.
struct ParticleView: View {
    let particle: Particle
    let area: CGSize

    @State private var isFlying = false
    @State private var isFaded = false

    var body: some View {
        Image(systemName: particle.symbol)
            .font(.system(size: particle.size, weight: .bold))
            .foregroundStyle(particle.color.gradient)
            .scaleEffect(isFlying ? 1 : 0.2)
            .rotationEffect(.degrees(isFlying ? particle.rotation : 0))
            .opacity(isFaded ? 0 : 1)
            .position(
                x: area.width * particle.startX + (isFlying ? particle.drift : 0),
                y: area.height * (isFlying ? 1 - particle.rise : 0.95)
            )
            .onAppear {
                withAnimation(.easeOut(duration: particle.duration).delay(particle.delay)) {
                    isFlying = true
                }
                // Stay visible for most of the flight, then fade out at the top.
                withAnimation(.easeIn(duration: particle.duration * 0.4).delay(particle.delay + particle.duration * 0.6)) {
                    isFaded = true
                }
            }
    }
}

#if DEBUG
#Preview {
    ParticleView(particle: .calm, area: CGSize(width: 300, height: 400))
        .frame(width: 300, height: 400)
}
#endif
