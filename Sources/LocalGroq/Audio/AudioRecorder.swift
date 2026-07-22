import AVFoundation
import Foundation

enum AudioRecorderError: LocalizedError {
    case permissionDenied
    case couldNotCreateRecorder

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            "Microphone access is required. Enable it in System Settings → Privacy & Security → Microphone."
        case .couldNotCreateRecorder:
            "Vorb could not start the microphone."
        }
    }
}

@MainActor
final class AudioRecorder: NSObject, AVAudioRecorderDelegate {
    var onLevel: ((Double) -> Void)?

    private var recorder: AVAudioRecorder?
    private var levelTimer: Timer?
    private var recordingURL: URL?
    private var levelEnvelope = VoiceLevelEnvelope()

    func start() async throws {
        guard await requestMicrophoneAccess() else {
            throw AudioRecorderError.permissionDenied
        }

        cancel()

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("vorb-\(UUID().uuidString)")
            .appendingPathExtension("wav")

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 16_000,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false
        ]

        let recorder = try AVAudioRecorder(url: url, settings: settings)
        recorder.delegate = self
        recorder.isMeteringEnabled = true

        guard recorder.prepareToRecord(), recorder.record() else {
            throw AudioRecorderError.couldNotCreateRecorder
        }

        self.recorder = recorder
        recordingURL = url

        levelTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.sampleLevel()
            }
        }
    }

    func stop() -> URL? {
        let url = recordingURL
        levelTimer?.invalidate()
        levelTimer = nil
        recorder?.stop()
        recorder = nil
        recordingURL = nil
        levelEnvelope.reset()
        onLevel?(0)
        return url
    }

    func cancel() {
        let url = recordingURL
        levelTimer?.invalidate()
        levelTimer = nil
        recorder?.stop()
        recorder = nil
        recordingURL = nil
        levelEnvelope.reset()
        onLevel?(0)

        if let url {
            try? FileManager.default.removeItem(at: url)
        }
    }

    private func sampleLevel() {
        guard let recorder, recorder.isRecording else { return }
        recorder.updateMeters()

        let level = levelEnvelope.update(
            averagePower: recorder.averagePower(forChannel: 0),
            peakPower: recorder.peakPower(forChannel: 0)
        )
        onLevel?(level)
    }

    private func requestMicrophoneAccess() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            true
        case .notDetermined:
            await AVCaptureDevice.requestAccess(for: .audio)
        case .denied, .restricted:
            false
        @unknown default:
            false
        }
    }
}
