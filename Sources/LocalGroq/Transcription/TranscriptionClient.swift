import Foundation

struct TranscriptionResponse: Decodable {
    let text: String
}

enum TranscriptionClientError: LocalizedError {
    case invalidResponse(provider: String)
    case emptyTranscript
    case api(provider: String, statusCode: Int, message: String)

    var errorDescription: String? {
        switch self {
        case let .invalidResponse(provider):
            "\(provider) returned an unreadable response."
        case .emptyTranscript:
            "No speech was detected."
        case let .api(provider, statusCode, message):
            "\(provider) API error \(statusCode): \(message)"
        }
    }
}

struct TranscriptionClient: Sendable {
    func transcribe(
        audioFileURL: URL,
        endpoint: URL,
        provider: TranscriptionProvider,
        apiKey: String,
        model: String,
        language: String?
    ) async throws -> String {
        let audioData = try Data(contentsOf: audioFileURL)
        let request = try makeRequest(
            audioData: audioData,
            filename: audioFileURL.lastPathComponent,
            endpoint: endpoint,
            provider: provider,
            apiKey: apiKey,
            model: model,
            language: language
        )

        let data = try await perform(request, provider: provider)
        let transcript = try extractTranscript(from: data, provider: provider)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !transcript.isEmpty else {
            throw TranscriptionClientError.emptyTranscript
        }
        return transcript
    }

    func makeRequest(
        audioData: Data,
        filename: String,
        endpoint: URL,
        provider: TranscriptionProvider,
        apiKey: String,
        model: String,
        language: String?
    ) throws -> URLRequest {
        switch provider.apiStyle {
        case .openAIMultipart:
            return makeOpenAIMultipartRequest(
                audioData: audioData,
                filename: filename,
                endpoint: endpoint,
                provider: provider,
                apiKey: apiKey,
                model: model,
                language: language
            )
        case .openRouterJSON:
            return try makeOpenRouterRequest(
                audioData: audioData,
                endpoint: endpoint,
                apiKey: apiKey,
                model: model,
                language: language
            )
        case .deepgram:
            return makeDeepgramRequest(
                audioData: audioData,
                endpoint: endpoint,
                apiKey: apiKey,
                model: model,
                language: language
            )
        case .elevenLabs:
            return makeElevenLabsRequest(
                audioData: audioData,
                filename: filename,
                endpoint: endpoint,
                apiKey: apiKey,
                model: model,
                language: language
            )
        case .huggingFace:
            return try makeHuggingFaceRequest(
                audioData: audioData,
                endpoint: endpoint,
                apiKey: apiKey,
                model: model
            )
        case .cloudflare:
            return makeRawAudioRequest(
                audioData: audioData,
                endpoint: endpoint,
                authorization: "Bearer \(apiKey)"
            )
        }
    }

    private func makeOpenAIMultipartRequest(
        audioData: Data,
        filename: String,
        endpoint: URL,
        provider: TranscriptionProvider,
        apiKey: String,
        model: String,
        language: String?
    ) -> URLRequest {
        var form = MultipartFormData()
        if provider != .azureOpenAI {
            form.addField(named: "model", value: model)
        }
        if provider != .siliconFlow {
            form.addField(named: "response_format", value: "json")
            form.addField(named: "temperature", value: "0")
            if let language {
                form.addField(named: "language", value: language)
            }
        }
        form.addFile(
            named: "file",
            filename: filename,
            mimeType: "audio/wav",
            contents: audioData
        )
        form.finalize()

        var request = baseRequest(url: endpoint)
        request.setValue(form.contentType, forHTTPHeaderField: "Content-Type")
        request.httpBody = form.data

        if provider == .azureOpenAI {
            request.setValue(apiKey, forHTTPHeaderField: "api-key")
        } else if !apiKey.isEmpty {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        return request
    }

    private func makeOpenRouterRequest(
        audioData: Data,
        endpoint: URL,
        apiKey: String,
        model: String,
        language: String?
    ) throws -> URLRequest {
        struct Audio: Encodable {
            let data: String
            let format: String
        }
        struct Body: Encodable {
            let model: String
            let inputAudio: Audio
            let language: String?
            let temperature: Double

            enum CodingKeys: String, CodingKey {
                case model
                case inputAudio = "input_audio"
                case language
                case temperature
            }
        }

        let body = Body(
            model: model,
            inputAudio: Audio(data: audioData.base64EncodedString(), format: "wav"),
            language: language,
            temperature: 0
        )
        var request = baseRequest(url: endpoint)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Vorb", forHTTPHeaderField: "X-OpenRouter-Title")
        request.httpBody = try JSONEncoder().encode(body)
        return request
    }

    private func makeDeepgramRequest(
        audioData: Data,
        endpoint: URL,
        apiKey: String,
        model: String,
        language: String?
    ) -> URLRequest {
        var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false)
        var queryItems = [
            URLQueryItem(name: "model", value: model),
            URLQueryItem(name: "smart_format", value: "true"),
            URLQueryItem(name: "punctuate", value: "true")
        ]
        if let language {
            queryItems.append(URLQueryItem(name: "language", value: language))
        }
        components?.queryItems = queryItems

        var request = baseRequest(url: components?.url ?? endpoint)
        request.setValue("Token \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("audio/wav", forHTTPHeaderField: "Content-Type")
        request.httpBody = audioData
        return request
    }

    private func makeElevenLabsRequest(
        audioData: Data,
        filename: String,
        endpoint: URL,
        apiKey: String,
        model: String,
        language: String?
    ) -> URLRequest {
        var form = MultipartFormData()
        form.addField(named: "model_id", value: model)
        form.addField(named: "tag_audio_events", value: "false")
        form.addField(named: "timestamps_granularity", value: "none")
        if let language {
            form.addField(named: "language_code", value: language)
        }
        form.addFile(
            named: "file",
            filename: filename,
            mimeType: "audio/wav",
            contents: audioData
        )
        form.finalize()

        var request = baseRequest(url: endpoint)
        request.setValue(apiKey, forHTTPHeaderField: "xi-api-key")
        request.setValue(form.contentType, forHTTPHeaderField: "Content-Type")
        request.httpBody = form.data
        return request
    }

    private func makeHuggingFaceRequest(
        audioData: Data,
        endpoint: URL,
        apiKey: String,
        model: String
    ) throws -> URLRequest {
        let encodedModel = model.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? model
        guard let modelURL = URL(string: endpoint.absoluteString + "/" + encodedModel) else {
            throw TranscriptionClientError.invalidResponse(provider: "Hugging Face Inference")
        }
        return makeRawAudioRequest(
            audioData: audioData,
            endpoint: modelURL,
            authorization: "Bearer \(apiKey)"
        )
    }

    private func makeRawAudioRequest(
        audioData: Data,
        endpoint: URL,
        authorization: String
    ) -> URLRequest {
        var request = baseRequest(url: endpoint)
        request.setValue(authorization, forHTTPHeaderField: "Authorization")
        request.setValue("audio/wav", forHTTPHeaderField: "Content-Type")
        request.httpBody = audioData
        return request
    }

    private func baseRequest(url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 120
        return request
    }

    private func perform(
        _ request: URLRequest,
        provider: TranscriptionProvider
    ) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TranscriptionClientError.invalidResponse(provider: provider.title)
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw TranscriptionClientError.api(
                provider: provider.title,
                statusCode: httpResponse.statusCode,
                message: serverMessage(from: data)
                    ?? HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
            )
        }
        return data
    }

    func extractTranscript(
        from data: Data,
        provider: TranscriptionProvider
    ) throws -> String {
        guard let object = try? JSONSerialization.jsonObject(with: data),
              let dictionary = object as? [String: Any] else {
            throw TranscriptionClientError.invalidResponse(provider: provider.title)
        }

        let paths: [[String]]
        switch provider {
        case .deepgram:
            paths = [["results", "channels", "0", "alternatives", "0", "transcript"]]
        case .cloudflare:
            paths = [["result", "text"], ["text"]]
        case .azureOpenAI:
            paths = [["text"], ["body", "text"]]
        default:
            paths = [["text"]]
        }

        for path in paths {
            if let transcript = stringValue(in: dictionary, path: path) {
                return transcript
            }
        }
        throw TranscriptionClientError.invalidResponse(provider: provider.title)
    }

    private func serverMessage(from data: Data) -> String? {
        guard let object = try? JSONSerialization.jsonObject(with: data),
              let dictionary = object as? [String: Any] else {
            return String(data: data, encoding: .utf8)
        }

        let paths = [
            ["error", "message"],
            ["error"],
            ["message"],
            ["detail", "message"],
            ["detail"],
            ["err_msg"],
            ["errors", "0", "message"]
        ]
        for path in paths {
            if let message = stringValue(in: dictionary, path: path), !message.isEmpty {
                return message
            }
        }
        return nil
    }

    private func stringValue(in root: Any, path: [String]) -> String? {
        var current: Any = root
        for component in path {
            if let index = Int(component), let array = current as? [Any], array.indices.contains(index) {
                current = array[index]
            } else if let dictionary = current as? [String: Any], let value = dictionary[component] {
                current = value
            } else {
                return nil
            }
        }
        return current as? String
    }
}
