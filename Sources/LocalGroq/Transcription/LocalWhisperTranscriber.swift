import Foundation
@preconcurrency import WhisperKit

enum LocalWhisperModelError: LocalizedError, Equatable {
    case notDownloaded(String)
    case invalidModelFolder(String)

    var errorDescription: String? {
        switch self {
        case let .notDownloaded(model):
            "Download the \(model) model in Settings before dictating."
        case let .invalidModelFolder(model):
            "The selected folder does not contain a complete \(model) WhisperKit model."
        }
    }
}

@MainActor
final class LocalWhisperTranscriber {
    private var pipeline: WhisperKit?
    private var loadedModel: String?
    private let downloadBase: URL
    private let repositoryRoot: URL

    init(downloadBase: URL? = nil) {
        let resolvedDownloadBase: URL
        if let downloadBase {
            resolvedDownloadBase = downloadBase
        } else {
            let applicationSupport = FileManager.default.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).first ?? FileManager.default.temporaryDirectory
            resolvedDownloadBase = applicationSupport
                .appendingPathComponent("Vorb", isDirectory: true)
                .appendingPathComponent("WhisperModels", isDirectory: true)
        }
        self.downloadBase = resolvedDownloadBase
        repositoryRoot = resolvedDownloadBase
            .appendingPathComponent("models", isDirectory: true)
            .appendingPathComponent("argmaxinc", isDirectory: true)
            .appendingPathComponent("whisperkit-coreml", isDirectory: true)
    }

    var cacheURL: URL { downloadBase }

    func modelFolder(for model: String) -> URL {
        repositoryRoot.appendingPathComponent(model, isDirectory: true)
    }

    func partialDownloadFolder(for model: String) -> URL {
        repositoryRoot
            .appendingPathComponent(".cache", isDirectory: true)
            .appendingPathComponent("huggingface", isDirectory: true)
            .appendingPathComponent("download", isDirectory: true)
            .appendingPathComponent(model, isDirectory: true)
    }

    func modelRepositoryURL(for model: String) -> URL? {
        var components = URLComponents(
            string: "https://huggingface.co/argmaxinc/whisperkit-coreml/tree/main"
        )
        components?.path += "/\(model)"
        return components?.url
    }

    func isModelDownloaded(_ model: String) -> Bool {
        let folder = modelFolder(for: model)
        let marker = folder.appendingPathComponent(".vorb-download-complete")
        if FileManager.default.fileExists(atPath: marker.path) {
            return true
        }
        return isCompleteModelFolder(folder)
    }

    private func isCompleteModelFolder(_ folder: URL) -> Bool {
        let requiredItems = [
            "config.json",
            "AudioEncoder.mlmodelc",
            "MelSpectrogram.mlmodelc",
            "TextDecoder.mlmodelc"
        ]
        guard requiredItems.allSatisfy({ item in
            FileManager.default.fileExists(
                atPath: folder.appendingPathComponent(item).path
            )
        }) else {
            return false
        }

        // Completed WhisperKit variants are tens or hundreds of megabytes. This also
        // excludes folders left behind by an interrupted Hugging Face download.
        return sizeOfDirectory(folder) > 10_000_000
    }

    func modelSize(_ model: String) -> Int64 {
        guard isModelDownloaded(model) else { return 0 }
        return sizeOfDirectory(modelFolder(for: model))
    }

    func cacheSize() -> Int64 {
        sizeOfDirectory(downloadBase)
    }

    @discardableResult
    func download(
        model: String,
        progress: (@Sendable (Double) -> Void)? = nil
    ) async throws -> URL {
        try FileManager.default.createDirectory(
            at: downloadBase,
            withIntermediateDirectories: true
        )

        let folder = try await WhisperKit.download(
            variant: model,
            downloadBase: downloadBase,
            progressCallback: { downloadProgress in
                progress?(downloadProgress.fractionCompleted)
            }
        )
        try Data().write(
            to: folder.appendingPathComponent(".vorb-download-complete"),
            options: .atomic
        )
        return folder
    }

    func removeModel(_ model: String) throws {
        if loadedModel == model {
            pipeline = nil
            loadedModel = nil
        }

        let fileManager = FileManager.default
        let folder = modelFolder(for: model)
        if fileManager.fileExists(atPath: folder.path) {
            try fileManager.removeItem(at: folder)
        }

        let partialDownloads = partialDownloadFolder(for: model)
        if fileManager.fileExists(atPath: partialDownloads.path) {
            try fileManager.removeItem(at: partialDownloads)
        }
    }

    func importModel(from selectedFolder: URL, model: String) throws {
        let fileManager = FileManager.default
        let candidates = [
            selectedFolder,
            selectedFolder.appendingPathComponent(model, isDirectory: true),
            selectedFolder
                .appendingPathComponent("models", isDirectory: true)
                .appendingPathComponent("argmaxinc", isDirectory: true)
                .appendingPathComponent("whisperkit-coreml", isDirectory: true)
                .appendingPathComponent(model, isDirectory: true)
        ]
        guard let source = candidates.first(where: isCompleteModelFolder) else {
            throw LocalWhisperModelError.invalidModelFolder(model)
        }

        try fileManager.createDirectory(
            at: repositoryRoot,
            withIntermediateDirectories: true
        )
        let staging = repositoryRoot.appendingPathComponent(
            ".vorb-import-\(UUID().uuidString)",
            isDirectory: true
        )
        defer { try? fileManager.removeItem(at: staging) }
        try fileManager.copyItem(at: source, to: staging)
        guard isCompleteModelFolder(staging) else {
            throw LocalWhisperModelError.invalidModelFolder(model)
        }

        let destination = modelFolder(for: model)
        if fileManager.fileExists(atPath: destination.path) {
            try fileManager.removeItem(at: destination)
        }
        try fileManager.moveItem(at: staging, to: destination)
        try Data().write(
            to: destination.appendingPathComponent(".vorb-download-complete"),
            options: .atomic
        )
    }

    func clearCache() throws {
        pipeline = nil
        loadedModel = nil

        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: downloadBase.path) {
            try fileManager.removeItem(at: downloadBase)
        }
        try fileManager.createDirectory(
            at: downloadBase,
            withIntermediateDirectories: true
        )
    }

    func transcribe(
        audioFileURL: URL,
        model: String,
        language: String?
    ) async throws -> String {
        let whisper = try await pipeline(for: model)
        let options = DecodingOptions(
            language: language,
            temperature: 0,
            usePrefillPrompt: true,
            detectLanguage: language == nil,
            skipSpecialTokens: true,
            withoutTimestamps: true,
            wordTimestamps: false,
            chunkingStrategy: .vad
        )
        let results = try await whisper.transcribe(
            audioPath: audioFileURL.path,
            decodeOptions: options
        )
        let transcript = results
            .map(\.text)
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !transcript.isEmpty else {
            throw TranscriptionClientError.emptyTranscript
        }
        return transcript
    }

    private func pipeline(for model: String) async throws -> WhisperKit {
        if loadedModel == model, let pipeline {
            return pipeline
        }

        guard isModelDownloaded(model) else {
            throw LocalWhisperModelError.notDownloaded(model)
        }

        let config = WhisperKitConfig(
            downloadBase: downloadBase,
            modelFolder: modelFolder(for: model).path,
            verbose: false,
            logLevel: .error,
            prewarm: true,
            load: true,
            download: false
        )
        let pipeline = try await WhisperKit(config)
        self.pipeline = pipeline
        loadedModel = model
        return pipeline
    }

    private func sizeOfDirectory(_ directory: URL) -> Int64 {
        guard let enumerator = FileManager.default.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey],
            options: []
        ) else {
            return 0
        }

        var total: Int64 = 0
        for case let fileURL as URL in enumerator {
            guard let values = try? fileURL.resourceValues(
                forKeys: [.isRegularFileKey, .fileSizeKey]
            ), values.isRegularFile == true else {
                continue
            }
            total += Int64(values.fileSize ?? 0)
        }
        return total
    }
}
