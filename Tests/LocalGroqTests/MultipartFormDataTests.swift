import Foundation
import XCTest
@testable import LocalGroq

final class MultipartFormDataTests: XCTestCase {
    func testMultipartFormIncludesFieldsAndFile() throws {
        var form = MultipartFormData(boundary: "test-boundary")
        form.addField(named: "model", value: "whisper-large-v3-turbo")
        form.addFile(
            named: "file",
            filename: "voice.wav",
            mimeType: "audio/wav",
            contents: Data([0x01, 0x02, 0x03])
        )
        form.finalize()

        let body = try XCTUnwrap(String(data: form.data, encoding: .isoLatin1))
        XCTAssertTrue(body.contains("name=\"model\""))
        XCTAssertTrue(body.contains("whisper-large-v3-turbo"))
        XCTAssertTrue(body.contains("filename=\"voice.wav\""))
        XCTAssertTrue(body.contains("Content-Type: audio/wav"))
        XCTAssertTrue(body.hasSuffix("--test-boundary--\r\n"))
    }

    func testTranscriptionResponseDecodes() throws {
        let data = Data(#"{"text":"hello from Groq"}"#.utf8)
        let response = try JSONDecoder().decode(TranscriptionResponse.self, from: data)
        XCTAssertEqual(response.text, "hello from Groq")
    }

    func testGroqCatalogUsesCurrentModelIdentifiers() {
        XCTAssertEqual(TranscriptionProvider.groq.defaultModel, "whisper-large-v3-turbo")
        XCTAssertTrue(
            TranscriptionProvider.groq.recommendedModels.contains {
                $0.id == "whisper-large-v3"
            }
        )
    }

    func testDefaultGlobalShortcutPresentation() {
        XCTAssertEqual(GlobalShortcut.optionSpace.displayString, "⌥ Space")
    }

    func testOpenAIModelsIncludeWhisper() {
        XCTAssertEqual(TranscriptionProvider.openAI.defaultModel, "whisper-1")
        XCTAssertTrue(
            TranscriptionProvider.openAI.recommendedModels.contains {
                $0.id == "gpt-4o-transcribe"
            }
        )
        XCTAssertEqual(
            TranscriptionProvider.openAI.defaultEndpoint,
            "https://api.openai.com/v1/audio/transcriptions"
        )
    }

    func testProviderCatalogCoversHostedSelfHostedAndCustomAPIs() {
        XCTAssertEqual(TranscriptionProvider.allCases.count, 20)
        XCTAssertFalse(TranscriptionProvider.localWhisper.requiresAPIKey)
        XCTAssertFalse(TranscriptionProvider.localWhisper.usesRemoteEndpoint)
        XCTAssertFalse(TranscriptionProvider.localWhisper.acceptsAPIKey)
        XCTAssertEqual(
            TranscriptionProvider.localWhisper.defaultModel,
            "openai_whisper-small"
        )
        XCTAssertEqual(TranscriptionProvider.openRouter.apiStyle, .openRouterJSON)
        XCTAssertEqual(TranscriptionProvider.deepgram.apiStyle, .deepgram)
        XCTAssertEqual(TranscriptionProvider.elevenLabs.apiStyle, .elevenLabs)
        XCTAssertEqual(TranscriptionProvider.huggingFace.apiStyle, .huggingFace)
        XCTAssertEqual(TranscriptionProvider.cloudflare.apiStyle, .cloudflare)
        XCTAssertFalse(TranscriptionProvider.localAI.requiresAPIKey)
        XCTAssertFalse(TranscriptionProvider.ovhcloud.requiresAPIKey)
        XCTAssertTrue(TranscriptionProvider.azureOpenAI.endpointIsEditable)
        XCTAssertTrue(TranscriptionProvider.custom.endpointIsEditable)
    }

    func testOpenRouterUsesBase64JSONRequest() throws {
        let request = try TranscriptionClient().makeRequest(
            audioData: Data([0x01, 0x02, 0x03]),
            filename: "voice.wav",
            endpoint: try XCTUnwrap(URL(string: TranscriptionProvider.openRouter.defaultEndpoint)),
            provider: .openRouter,
            apiKey: "router-key",
            model: "openai/whisper-1",
            language: "en"
        )

        let body = try XCTUnwrap(request.httpBody)
        let json = try XCTUnwrap(
            JSONSerialization.jsonObject(with: body) as? [String: Any]
        )
        let inputAudio = try XCTUnwrap(json["input_audio"] as? [String: Any])

        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer router-key")
        XCTAssertEqual(json["model"] as? String, "openai/whisper-1")
        XCTAssertEqual(inputAudio["data"] as? String, "AQID")
        XCTAssertEqual(inputAudio["format"] as? String, "wav")
        XCTAssertEqual(json["language"] as? String, "en")
    }

    func testNativeProviderRequestShapes() throws {
        let client = TranscriptionClient()
        let audio = Data([0x01, 0x02])

        let deepgram = try client.makeRequest(
            audioData: audio,
            filename: "voice.wav",
            endpoint: try XCTUnwrap(URL(string: TranscriptionProvider.deepgram.defaultEndpoint)),
            provider: .deepgram,
            apiKey: "deepgram-key",
            model: "nova-3",
            language: "de"
        )
        let deepgramComponents = try XCTUnwrap(
            URLComponents(url: try XCTUnwrap(deepgram.url), resolvingAgainstBaseURL: false)
        )
        XCTAssertEqual(deepgram.value(forHTTPHeaderField: "Authorization"), "Token deepgram-key")
        XCTAssertTrue(deepgramComponents.queryItems?.contains(URLQueryItem(name: "model", value: "nova-3")) == true)
        XCTAssertTrue(deepgramComponents.queryItems?.contains(URLQueryItem(name: "language", value: "de")) == true)

        let elevenLabs = try client.makeRequest(
            audioData: audio,
            filename: "voice.wav",
            endpoint: try XCTUnwrap(URL(string: TranscriptionProvider.elevenLabs.defaultEndpoint)),
            provider: .elevenLabs,
            apiKey: "eleven-key",
            model: "scribe_v2",
            language: "fr"
        )
        let elevenBody = try XCTUnwrap(
            String(data: try XCTUnwrap(elevenLabs.httpBody), encoding: .isoLatin1)
        )
        XCTAssertEqual(elevenLabs.value(forHTTPHeaderField: "xi-api-key"), "eleven-key")
        XCTAssertTrue(elevenBody.contains("name=\"model_id\""))
        XCTAssertTrue(elevenBody.contains("scribe_v2"))
        XCTAssertTrue(elevenBody.contains("name=\"language_code\""))
    }

    func testAzureAndLocalAuthenticationRules() throws {
        let client = TranscriptionClient()
        let endpoint = try XCTUnwrap(URL(string: "https://example.openai.azure.com/audio/transcriptions"))

        let azure = try client.makeRequest(
            audioData: Data([0x01]),
            filename: "voice.wav",
            endpoint: endpoint,
            provider: .azureOpenAI,
            apiKey: "azure-key",
            model: "ignored-deployment-model",
            language: nil
        )
        let azureBody = try XCTUnwrap(
            String(data: try XCTUnwrap(azure.httpBody), encoding: .isoLatin1)
        )
        XCTAssertEqual(azure.value(forHTTPHeaderField: "api-key"), "azure-key")
        XCTAssertNil(azure.value(forHTTPHeaderField: "Authorization"))
        XCTAssertFalse(azureBody.contains("name=\"model\""))

        let local = try client.makeRequest(
            audioData: Data([0x01]),
            filename: "voice.wav",
            endpoint: try XCTUnwrap(URL(string: TranscriptionProvider.localAI.defaultEndpoint)),
            provider: .localAI,
            apiKey: "",
            model: "whisper-1",
            language: nil
        )
        XCTAssertNil(local.value(forHTTPHeaderField: "Authorization"))
    }

    func testNativeProviderResponsesAreExtracted() throws {
        let client = TranscriptionClient()
        let deepgram = Data(
            #"{"results":{"channels":[{"alternatives":[{"transcript":"hello"}]}]}}"#.utf8
        )
        let cloudflare = Data(#"{"result":{"text":"bonjour"},"success":true}"#.utf8)

        XCTAssertEqual(try client.extractTranscript(from: deepgram, provider: .deepgram), "hello")
        XCTAssertEqual(try client.extractTranscript(from: cloudflare, provider: .cloudflare), "bonjour")
    }

    func testHistoryPersistsRecords() throws {
        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("LocalGroqTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }

        let store = TranscriptHistoryStore(baseDirectoryURL: temporaryDirectory)
        let record = TranscriptRecord(
            text: "A saved transcript",
            provider: "OpenAI",
            model: "whisper-1"
        )

        try store.save([record])

        XCTAssertEqual(try store.load(), [record])
    }

    func testProviderKeyRoundTripsThroughKeychain() throws {
        let store = KeychainStore()
        let account = "integration-test-\(UUID().uuidString)"
        defer { try? store.delete(account: account) }

        try store.save("first-key", account: account)
        XCTAssertEqual(try store.read(account: account), "first-key")

        try store.save("updated-key", account: account)
        XCTAssertEqual(try store.read(account: account), "updated-key")

        try store.delete(account: account)
        XCTAssertNil(try store.read(account: account))
    }

    @MainActor
    func testLocalWhisperEndToEndWhenFixtureIsProvided() async throws {
        let environment = ProcessInfo.processInfo.environment
        guard let fixturePath = environment["VORB_LOCAL_WHISPER_AUDIO"],
              !fixturePath.isEmpty else {
            throw XCTSkip("Set VORB_LOCAL_WHISPER_AUDIO to run the local Whisper integration test")
        }

        let fixtureURL = URL(fileURLWithPath: fixturePath)
        XCTAssertTrue(FileManager.default.fileExists(atPath: fixtureURL.path))

        let modelDirectory = URL(
            fileURLWithPath: environment["VORB_LOCAL_WHISPER_MODELS"]
                ?? "/tmp/VorbLocalWhisperIntegrationModels",
            isDirectory: true
        )
        let transcriber = LocalWhisperTranscriber(downloadBase: modelDirectory)
        let model = environment["VORB_LOCAL_WHISPER_MODEL"] ?? "openai_whisper-tiny"
        if !transcriber.isModelDownloaded(model) {
            try await transcriber.download(model: model)
        }
        let transcript = try await transcriber.transcribe(
            audioFileURL: fixtureURL,
            model: model,
            language: "en"
        )
        let normalizedTranscript = transcript.lowercased()

        XCTAssertTrue(normalizedTranscript.contains("country"), transcript)
        XCTAssertTrue(normalizedTranscript.contains("americans"), transcript)
    }

    func testCustomProviderEndToEndWhenMockEndpointIsProvided() async throws {
        guard let endpointValue = ProcessInfo.processInfo.environment["VORB_MOCK_TRANSCRIPTION_ENDPOINT"],
              let endpoint = URL(string: endpointValue) else {
            throw XCTSkip("Set VORB_MOCK_TRANSCRIPTION_ENDPOINT to run the provider integration test")
        }

        let audioURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("VorbProviderIntegration-\(UUID().uuidString).wav")
        try Data([0x52, 0x49, 0x46, 0x46]).write(to: audioURL)
        defer { try? FileManager.default.removeItem(at: audioURL) }

        let transcript = try await TranscriptionClient().transcribe(
            audioFileURL: audioURL,
            endpoint: endpoint,
            provider: .custom,
            apiKey: "integration-test-key",
            model: "whisper-integration-test",
            language: "en"
        )

        XCTAssertEqual(transcript, "Vorb provider integration works")
    }
}
