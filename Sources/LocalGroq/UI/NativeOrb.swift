import SwiftUI

struct NativeOrb: View {
    let phase: DictationPhase
    var audioLevel: Double = 0

    private struct Particle {
        let index: CGFloat
        let x: CGFloat
        let y: CGFloat
        let z: CGFloat
        let longitude: CGFloat
    }

    // Fibonacci points live on a true sphere rather than in a flat particle
    // cloud. The sphere turns in 3D, revealing front and back depth.
    private static let particles: [Particle] = {
        let count = 128
        return (0..<count).map { index in
            let value = CGFloat(index)
            let fraction = (value + 0.5) / CGFloat(count)
            let y = 1 - 2 * fraction
            let longitude = value * 2.399_963_2
            let horizontalRadius = sqrt(max(0, 1 - y * y))
            return Particle(
                index: value,
                x: cos(longitude) * horizontalRadius,
                y: y,
                z: sin(longitude) * horizontalRadius,
                longitude: longitude
            )
        }
    }()

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            Canvas { context, size in
                drawOrb(
                    in: &context,
                    size: size,
                    time: CGFloat(timeline.date.timeIntervalSinceReferenceDate)
                )
            }
        }
        .drawingGroup(opaque: false, colorMode: .linear)
        .accessibilityHidden(true)
    }

    private func drawOrb(in context: inout GraphicsContext, size: CGSize, time: CGFloat) {
        let side = min(size.width, size.height)
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let radius = side * 0.43
        let level = phase == .recording
            ? CGFloat(max(0, min(1, audioLevel)))
            : 0
        let ambientBreath = sin(time * 0.94) * 0.018
        let rotationSpeed: CGFloat
        switch phase {
        case .recording: rotationSpeed = 0.16
        case .transcribing: rotationSpeed = 0.20
        case .success: rotationSpeed = 0.12
        case .failure: rotationSpeed = -0.14
        case .idle: rotationSpeed = 0.11
        }
        let rotation = time * rotationSpeed
        let rotationCosine = cos(rotation)
        let rotationSine = sin(rotation)

        context.addFilter(
            .shadow(
                color: .white.opacity(0.08 + Double(level) * 0.17),
                radius: 1.4 + level * 2.8
            )
        )

        for particle in Self.particles {
            let expansion: CGFloat
            let radialWave: CGFloat
            switch phase {
            case .recording:
                expansion = level * 0.14
                radialWave = sin(
                    particle.longitude * 2.2
                        + particle.y * 3.4
                        - time * 2.05
                ) * level * 0.055
            case .transcribing:
                expansion = sin(time * 0.9) * 0.014
                radialWave = sin(
                    particle.y * 6.2 - time * 1.55
                ) * 0.035
            case .success:
                expansion = 0.05 + sin(time * 1.1) * 0.006
                radialWave = 0
            case .failure:
                expansion = -0.025
                radialWave = sin(
                    time * 2.8 + particle.index * 0.62
                ) * 0.018
            case .idle:
                expansion = 0
                radialWave = 0
            }

            let rotatedX = particle.x * rotationCosine + particle.z * rotationSine
            let rotatedZ = -particle.x * rotationSine + particle.z * rotationCosine
            let depth = (rotatedZ + 1) / 2
            let radialScale = 1 + ambientBreath + expansion + radialWave
            let perspective = 0.91 + depth * 0.09
            let x = center.x + rotatedX * radius * radialScale * perspective
            let y = center.y + particle.y * radius * radialScale * perspective

            let slowShimmer = sin(
                time * 0.72 + particle.longitude * 0.6 + particle.y
            ) * 0.035
            let opacity = min(
                1,
                max(
                    0.12,
                    0.16
                        + depth * 0.76
                        + slowShimmer
                        + level * 0.10
                )
            )
            let voiceScale = 1 + level * (0.12 + depth * 0.18)
            let dotSize = side
                * (0.010 + depth * 0.014)
                * voiceScale
            let dotOrigin = CGPoint(x: x - dotSize / 2, y: y - dotSize / 2)
            let dotDimensions = CGSize(width: dotSize, height: dotSize)
            let rect = CGRect(origin: dotOrigin, size: dotDimensions)

            let color = particleColor.opacity(Double(opacity))
            context.fill(Path(ellipseIn: rect), with: .color(color))
        }
    }

    private var particleColor: Color {
        switch phase {
        case .failure: Color(red: 1, green: 0.48, blue: 0.42)
        default: .white
        }
    }
}
