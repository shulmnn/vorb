import Foundation

struct VoiceLevelEnvelope {
    private(set) var value: Double = 0

    mutating func update(averagePower: Float, peakPower: Float) -> Double {
        let average = Self.normalizedPower(averagePower)
        let peak = Self.normalizedPower(peakPower)
        let combined = max(average, peak * 0.82)

        // Remove room noise, then compress the voice range so normal speech is
        // visually expressive without requiring the user to speak loudly.
        let noiseFloor = 0.08
        let gated = max(0, (combined - noiseFloor) / (1 - noiseFloor))
        let compressed = pow(gated, 0.68)

        // Fast attack makes syllables feel immediate; slower release prevents
        // the particle cloud from flickering between meter samples.
        let smoothing = compressed > value ? 0.62 : 0.14
        value += (compressed - value) * smoothing
        if value < 0.01 { value = 0 }
        return value
    }

    mutating func reset() {
        value = 0
    }

    private static func normalizedPower(_ decibels: Float) -> Double {
        guard decibels.isFinite else { return 0 }
        let floor = -52.0
        return max(0, min(1, (Double(decibels) - floor) / -floor))
    }
}
