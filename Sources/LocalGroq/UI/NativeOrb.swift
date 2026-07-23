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

    // A fixed Fibonacci sphere keeps every particle spatially anchored. Motion is
    // applied along the sphere's surface normal, never by rotating the cloud.
    private static let particles: [Particle] = {
        let count = 104
        return (0..<count).map { index in
            let value = CGFloat(index)
            let fraction = (value + 0.5) / CGFloat(count)
            let y = 1 - 2 * fraction
            let longitude = value * 2.399_963_2
            let horizontalRadius = sqrt(max(0, 1 - y * y))
            let radialSeed = abs(sin((value + 1) * 12.989_8) * 43_758.545_3)
                .truncatingRemainder(dividingBy: 1)
            let volumeRadius = 0.14 + pow(radialSeed, 0.62) * 0.86
            return Particle(
                index: value,
                x: cos(longitude) * horizontalRadius * volumeRadius,
                y: y * volumeRadius,
                z: sin(longitude) * horizontalRadius * volumeRadius,
                longitude: longitude
            )
        }
        .sorted { $0.z < $1.z }
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
        let radius = side * 0.35
        let level = phase == .recording
            ? CGFloat(max(0, min(1, audioLevel)))
            : 0
        let ambientBreath = sin(time * 0.78) * 0.014

        context.addFilter(
            .shadow(
                color: .white.opacity(0.08 + Double(level) * 0.16),
                radius: 1.6 + level * 3
            )
        )

        for particle in Self.particles {
            let depth = (particle.z + 1) / 2
            let expansion: CGFloat
            let surfaceWave: CGFloat
            switch phase {
            case .recording:
                expansion = level * 0.14
                surfaceWave = sin(
                    particle.longitude * 1.7
                        + particle.y * 3.8
                        - time * 2.15
                ) * level * 0.045
            case .transcribing:
                expansion = sin(time * 0.9) * 0.012
                surfaceWave = sin(particle.y * 5.2 - time * 1.35) * 0.032
            case .success:
                expansion = 0.04 + sin(time * 1.1) * 0.006
                surfaceWave = 0
            case .failure:
                expansion = -0.025
                surfaceWave = sin(time * 2.8 + particle.index * 0.62) * 0.018
            case .idle:
                expansion = 0
                surfaceWave = 0
            }

            let radialScale = 1 + ambientBreath + expansion + surfaceWave
            let perspective = 0.88 + depth * 0.12
            let x = center.x + particle.x * radius * radialScale * perspective
            let y = center.y + particle.y * radius * radialScale * perspective * 0.98

            let slowShimmer = sin(
                time * 0.72 + particle.longitude * 0.55 + particle.y
            ) * 0.045
            let opacity = min(
                1,
                max(0.18, 0.24 + depth * 0.68 + slowShimmer + level * 0.08)
            )
            let voiceScale = 1 + level * (0.12 + depth * 0.18)
            let dotSize = side
                * (0.014 + depth * 0.014)
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
