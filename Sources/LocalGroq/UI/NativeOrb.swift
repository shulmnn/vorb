import SwiftUI

struct NativeOrb: View {
    let phase: DictationPhase
    var audioLevel: Double = 0

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
        let particleCount = 104
        let level = phase == .recording
            ? CGFloat(max(0, min(1, audioLevel)))
            : 0
        let speed: CGFloat
        switch phase {
        case .recording: speed = 0.24 + level * 0.58
        case .transcribing: speed = 0.46
        default: speed = 0.18
        }
        let pulse = phase == .recording
            ? 1 + level * 0.24 + sin(time * 6.2) * level * 0.025
            : 1 + sin(time * 2.2) * 0.025

        context.addFilter(
            .shadow(
                color: .white.opacity(0.10 + Double(level) * 0.20),
                radius: 2 + level * 4
            )
        )

        for index in 0..<particleCount {
            let indexValue = CGFloat(index)
            let fraction = (indexValue + 0.5) / CGFloat(particleCount)
            let goldenAngle = indexValue * 2.399_963_2
            let baseRadius = sqrt(fraction)

            let phaseOffset: CGFloat
            let wave: CGFloat
            switch phase {
            case .recording:
                phaseOffset = time * speed + sin(indexValue * 0.31) * level * 0.95
                wave =
                    sin(time * (4.2 + level * 4.8) + indexValue * 0.23)
                        * (0.035 + level * 0.11)
                    + sin(time * 10.8 + indexValue * 0.91) * level * 0.035
            case .transcribing:
                phaseOffset = time * speed + baseRadius * 5.2
                wave = sin(time * 2.8 + indexValue * 0.41) * 0.08
            case .success:
                phaseOffset = time * 0.25
                wave = sin(indexValue * 0.4) * 0.018
            case .failure:
                phaseOffset = -time * 0.45
                wave = sin(time * 5 + indexValue) * 0.05
            case .idle:
                phaseOffset = time * 0.35
                wave = sin(time * 1.4 + indexValue * 0.17) * 0.025
            }

            let theta = goldenAngle + phaseOffset
            let warpedRadius = max(0.05, baseRadius + wave) * radius * pulse
            let perspective = 0.68 + 0.32 * sin(theta * 0.55 + time * 0.3)
            let x = center.x + cos(theta) * warpedRadius
            let y = center.y + sin(theta) * warpedRadius * perspective

            let edgeFade = 1 - baseRadius * 0.55
            let shimmer = 0.54 + 0.46 * sin(theta + time * 1.7)
            let opacity = max(
                0.12,
                edgeFade * (0.42 + shimmer * 0.5 + level * 0.18)
            )
            let voiceScale = 1 + level * (0.25 + (1 - baseRadius) * 0.55)
            let dotSize = side
                * (0.018 + (1 - baseRadius) * 0.013)
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
