import Foundation

struct TranscriptRecord: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    let text: String
    let createdAt: Date
    let provider: String
    let model: String

    init(
        id: UUID = UUID(),
        text: String,
        createdAt: Date = Date(),
        provider: String,
        model: String
    ) {
        self.id = id
        self.text = text
        self.createdAt = createdAt
        self.provider = provider
        self.model = model
    }
}

struct TranscriptHistoryStore: Sendable {
    let fileURL: URL

    init(baseDirectoryURL: URL? = nil) {
        let baseDirectory = baseDirectoryURL ?? FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0]
        fileURL = baseDirectory
            .appendingPathComponent("Vorb", isDirectory: true)
            .appendingPathComponent("transcription-history.json", isDirectory: false)
    }

    func load() throws -> [TranscriptRecord] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode([TranscriptRecord].self, from: data)
    }

    func save(_ records: [TranscriptRecord]) throws {
        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        let data = try JSONEncoder().encode(records)
        try data.write(to: fileURL, options: .atomic)
    }
}
