import XCTest
@testable import LocalGroq

final class VoiceLevelEnvelopeTests: XCTestCase {
    func testSilenceStaysAtZero() {
        var envelope = VoiceLevelEnvelope()

        XCTAssertEqual(
            envelope.update(averagePower: -160, peakPower: -160),
            0
        )
    }

    func testNormalVoiceProducesVisibleResponse() {
        var envelope = VoiceLevelEnvelope()
        var level = 0.0

        for _ in 0..<3 {
            level = envelope.update(averagePower: -12, peakPower: -6)
        }

        XCTAssertGreaterThan(level, 0.7)
    }

    func testReleaseDecaysInsteadOfDroppingImmediately() {
        var envelope = VoiceLevelEnvelope()
        for _ in 0..<3 {
            _ = envelope.update(averagePower: -12, peakPower: -6)
        }

        let firstSilentFrame = envelope.update(
            averagePower: -160,
            peakPower: -160
        )
        XCTAssertGreaterThan(firstSilentFrame, 0.5)

        for _ in 0..<36 {
            _ = envelope.update(averagePower: -160, peakPower: -160)
        }
        XCTAssertEqual(envelope.value, 0)
    }
}
