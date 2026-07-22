import Foundation
import XCTest
@testable import LocalGroq

@MainActor
final class LocalWhisperModelManagerTests: XCTestCase {
    private let model = "openai_whisper-tiny"

    func testIncompleteDownloadIsNotAvailableAndCountsTowardCache() throws {
        let root = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }

        let transcriber = LocalWhisperTranscriber(downloadBase: root)
        let partial = transcriber.partialDownloadFolder(for: model)
            .appendingPathComponent("partial.incomplete")
        try FileManager.default.createDirectory(
            at: partial.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Data(repeating: 7, count: 1_024).write(to: partial)

        XCTAssertFalse(transcriber.isModelDownloaded(model))
        XCTAssertEqual(transcriber.modelSize(model), 0)
        XCTAssertEqual(transcriber.cacheSize(), 1_024)
    }

    func testCompleteModelIsDetectedAndCanBeRemovedWithPartialFiles() throws {
        let root = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }

        let transcriber = LocalWhisperTranscriber(downloadBase: root)
        let modelFolder = transcriber.modelFolder(for: model)
        try createCompleteModel(at: modelFolder)

        let partial = transcriber.partialDownloadFolder(for: model)
            .appendingPathComponent("pending.incomplete")
        try FileManager.default.createDirectory(
            at: partial.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Data([1, 2, 3]).write(to: partial)

        XCTAssertTrue(transcriber.isModelDownloaded(model))
        XCTAssertGreaterThan(transcriber.modelSize(model), 10_000_000)

        try transcriber.removeModel(model)

        XCTAssertFalse(FileManager.default.fileExists(atPath: modelFolder.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: partial.path))
        XCTAssertFalse(transcriber.isModelDownloaded(model))
    }

    func testClearCacheRemovesAllModelsAndRecreatesEmptyRoot() throws {
        let root = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }

        let transcriber = LocalWhisperTranscriber(downloadBase: root)
        try createCompleteModel(at: transcriber.modelFolder(for: model))
        XCTAssertGreaterThan(transcriber.cacheSize(), 0)

        try transcriber.clearCache()

        var isDirectory: ObjCBool = false
        XCTAssertTrue(FileManager.default.fileExists(
            atPath: root.path,
            isDirectory: &isDirectory
        ))
        XCTAssertTrue(isDirectory.boolValue)
        XCTAssertEqual(transcriber.cacheSize(), 0)
        XCTAssertFalse(transcriber.isModelDownloaded(model))
    }

    func testExistingWhisperKitRepositoryCanBeImported() throws {
        let root = temporaryDirectory()
        let externalRoot = temporaryDirectory()
        defer {
            try? FileManager.default.removeItem(at: root)
            try? FileManager.default.removeItem(at: externalRoot)
        }

        let externalModel = externalRoot
            .appendingPathComponent("models/argmaxinc/whisperkit-coreml", isDirectory: true)
            .appendingPathComponent(model, isDirectory: true)
        try createCompleteModel(at: externalModel)

        let transcriber = LocalWhisperTranscriber(downloadBase: root)
        try transcriber.importModel(from: externalRoot, model: model)

        XCTAssertTrue(transcriber.isModelDownloaded(model))
        XCTAssertGreaterThan(transcriber.modelSize(model), 10_000_000)
        XCTAssertTrue(FileManager.default.fileExists(
            atPath: transcriber.modelFolder(for: model)
                .appendingPathComponent(".vorb-download-complete").path
        ))
    }

    func testIncompleteExistingModelCannotBeImported() throws {
        let root = temporaryDirectory()
        let incomplete = temporaryDirectory()
        defer {
            try? FileManager.default.removeItem(at: root)
            try? FileManager.default.removeItem(at: incomplete)
        }
        try FileManager.default.createDirectory(
            at: incomplete,
            withIntermediateDirectories: true
        )
        try Data("{}".utf8).write(
            to: incomplete.appendingPathComponent("config.json")
        )

        let transcriber = LocalWhisperTranscriber(downloadBase: root)
        XCTAssertThrowsError(
            try transcriber.importModel(from: incomplete, model: model)
        ) { error in
            XCTAssertEqual(
                error as? LocalWhisperModelError,
                .invalidModelFolder(model)
            )
        }
        XCTAssertFalse(transcriber.isModelDownloaded(model))
    }

    func testTranscriptionDoesNotTriggerImplicitDownload() async throws {
        let root = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }

        let transcriber = LocalWhisperTranscriber(downloadBase: root)

        do {
            _ = try await transcriber.transcribe(
                audioFileURL: root.appendingPathComponent("missing.wav"),
                model: model,
                language: "en"
            )
            XCTFail("Expected a missing-model error")
        } catch let error as LocalWhisperModelError {
            XCTAssertEqual(error, .notDownloaded(model))
        }
        XCTAssertEqual(transcriber.cacheSize(), 0)
    }

    private func temporaryDirectory() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("VorbModelTests-\(UUID().uuidString)", isDirectory: true)
    }

    private func createCompleteModel(at folder: URL) throws {
        let fileManager = FileManager.default
        try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
        try Data("{}".utf8).write(to: folder.appendingPathComponent("config.json"))

        for name in [
            "AudioEncoder.mlmodelc",
            "MelSpectrogram.mlmodelc",
            "TextDecoder.mlmodelc"
        ] {
            try fileManager.createDirectory(
                at: folder.appendingPathComponent(name, isDirectory: true),
                withIntermediateDirectories: true
            )
        }

        let weights = folder
            .appendingPathComponent("AudioEncoder.mlmodelc", isDirectory: true)
            .appendingPathComponent("weights.bin")
        XCTAssertTrue(fileManager.createFile(atPath: weights.path, contents: nil))
        let handle = try FileHandle(forWritingTo: weights)
        try handle.truncate(atOffset: 10_000_001)
        try handle.close()
    }
}
