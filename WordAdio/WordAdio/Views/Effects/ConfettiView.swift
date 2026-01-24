import SwiftUI

/// Animated confetti particles for celebrations
struct ConfettiView: View {
    let trigger: Bool
    
    @State private var particles: [ConfettiParticle] = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    ConfettiPiece(particle: particle, screenHeight: geometry.size.height)
                }
            }
            .onChange(of: trigger) { _, newValue in
                if newValue {
                    createParticles(in: geometry.size)
                }
            }
        }
        .allowsHitTesting(false)
    }
    
    private func createParticles(in size: CGSize) {
        particles = (0..<50).map { _ in
            ConfettiParticle(
                x: CGFloat.random(in: 0...size.width),
                color: ConfettiColors.random,
                size: CGFloat.random(in: 8...14),
                rotation: Double.random(in: 0...360),
                delay: Double.random(in: 0...0.5)
            )
        }
    }
}

// MARK: - Confetti Colors

private enum ConfettiColors {
    static let all: [Color] = [.red, .blue, .green, .yellow, .orange, .purple, .pink]
    
    static var random: Color {
        all.randomElement()!
    }
}

// MARK: - Confetti Particle Model

struct ConfettiParticle: Identifiable {
    let id = UUID()
    let x: CGFloat
    let color: Color
    let size: CGFloat
    let rotation: Double
    let delay: Double
}

// MARK: - Confetti Piece View

struct ConfettiPiece: View {
    let particle: ConfettiParticle
    let screenHeight: CGFloat
    
    @State private var yOffset: CGFloat = -50
    @State private var opacity: Double = 1
    @State private var currentRotation: Double = 0
    
    var body: some View {
        Rectangle()
            .fill(particle.color)
            .frame(width: particle.size, height: particle.size * 0.6)
            .rotationEffect(.degrees(currentRotation))
            .position(x: particle.x, y: yOffset)
            .opacity(opacity)
            .onAppear {
                currentRotation = particle.rotation
                withAnimation(
                    .easeIn(duration: 2.5)
                        .delay(particle.delay)
                ) {
                    yOffset = screenHeight + 50
                    currentRotation += 720
                }
                withAnimation(
                    .easeIn(duration: 1)
                        .delay(particle.delay + 1.5)
                ) {
                    opacity = 0
                }
            }
    }
}

#Preview {
    ZStack {
        Color.black.opacity(0.5)
        ConfettiView(trigger: true)
    }
}
