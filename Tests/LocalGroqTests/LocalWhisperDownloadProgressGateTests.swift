import Foundation
import XCTest
@testable import LocalGroq

final class LocalWhisperDownloadProgressGateTests: XCTestCase {
    func testLateProgressFromFinishedDownloadIsRejected() {
        var gate = LocalWhisperDownloadProgressGate()
        let downloadID = gate.begin()

        XCTAssertTrue(gate.accepts(downloadID))
        XCTAssertTrue(gate.finish(downloadID))
        XCTAssertFalse(gate.accepts(downloadID))
        XCTAssertFalse(gate.finish(downloadID))
    }

    func testStartingNewDownloadInvalidatesPreviousProgress() {
        var gate = LocalWhisperDownloadProgressGate()
        let previousDownloadID = gate.begin()
        let currentDownloadID = gate.begin()

        XCTAssertFalse(gate.accepts(previousDownloadID))
        XCTAssertTrue(gate.accepts(currentDownloadID))
        XCTAssertFalse(gate.finish(previousDownloadID))
        XCTAssertTrue(gate.finish(currentDownloadID))
    }
}
