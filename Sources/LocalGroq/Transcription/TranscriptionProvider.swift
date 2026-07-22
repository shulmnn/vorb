import Foundation

struct TranscriptionModelOption: Identifiable, Hashable {
    let id: String
    let title: String
    let detail: String

    init(_ id: String, title: String, detail: String) {
        self.id = id
        self.title = title
        self.detail = detail
    }
}

enum TranscriptionAPIStyle: Equatable {
    case openAIMultipart
    case openRouterJSON
    case deepgram
    case elevenLabs
    case huggingFace
    case cloudflare
}

enum TranscriptionProvider: String, CaseIterable, Identifiable, Codable {
    case localWhisper
    case groq
    case openAI
    case openRouter
    case mistral
    case together
    case deepInfra
    case siliconFlow
    case scaleway
    case ovhcloud
    case deepgram
    case elevenLabs
    case huggingFace
    case cloudflare
    case azureOpenAI
    case localAI
    case speaches
    case nvidiaNIM
    case whisperLiveKit
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .localWhisper: localized("Local Whisper")
        case .groq: "Groq"
        case .openAI: "OpenAI"
        case .openRouter: "OpenRouter"
        case .mistral: "Mistral"
        case .together: "Together AI"
        case .deepInfra: "DeepInfra"
        case .siliconFlow: "SiliconFlow"
        case .scaleway: "Scaleway"
        case .ovhcloud: "OVHcloud AI Endpoints"
        case .deepgram: "Deepgram"
        case .elevenLabs: "ElevenLabs"
        case .huggingFace: "Hugging Face Inference"
        case .cloudflare: "Cloudflare Workers AI"
        case .azureOpenAI: "Azure OpenAI"
        case .localAI: "LocalAI"
        case .speaches: "Speaches"
        case .nvidiaNIM: "NVIDIA Speech NIM"
        case .whisperLiveKit: "WhisperLiveKit"
        case .custom: localized("Other OpenAI-compatible")
        }
    }

    var detail: String {
        let value: String
        switch self {
        case .localWhisper: value = "Private on-device transcription with no API key"
        case .groq: value = "Fast hosted Whisper inference"
        case .openAI: value = "Whisper and GPT transcription models"
        case .openRouter: value = "Routes OpenAI, Google, Groq, Mistral, NVIDIA, Qwen, and Microsoft STT"
        case .mistral: value = "Hosted Voxtral transcription"
        case .together: value = "Hosted Whisper and NVIDIA Parakeet"
        case .deepInfra: value = "Hosted open-source Whisper models"
        case .siliconFlow: value = "Hosted multilingual SenseVoice transcription"
        case .scaleway: value = "European-hosted Whisper transcription"
        case .ovhcloud: value = "Whisper on OVHcloud AI Endpoints"
        case .deepgram: value = "Nova and Whisper speech recognition"
        case .elevenLabs: value = "Scribe multilingual speech recognition"
        case .huggingFace: value = "Whisper through Hugging Face Inference Providers"
        case .cloudflare: value = "Whisper on Cloudflare Workers AI"
        case .azureOpenAI: value = "Your Azure-hosted Whisper deployment"
        case .localAI: value = "Self-hosted Whisper, Moonshine, or faster-whisper"
        case .speaches: value = "Self-hosted faster-whisper server"
        case .nvidiaNIM: value = "Self-hosted Whisper, Parakeet, Canary, or Nemotron ASR"
        case .whisperLiveKit: value = "Self-hosted Whisper-compatible transcription"
        case .custom: value = "Any server implementing OpenAI’s transcription endpoint"
        }
        return localized(value)
    }

    var apiStyle: TranscriptionAPIStyle {
        switch self {
        case .openRouter:
            .openRouterJSON
        case .deepgram:
            .deepgram
        case .elevenLabs:
            .elevenLabs
        case .huggingFace:
            .huggingFace
        case .cloudflare:
            .cloudflare
        default:
            .openAIMultipart
        }
    }

    var defaultEndpoint: String {
        switch self {
        case .localWhisper:
            ""
        case .groq:
            "https://api.groq.com/openai/v1/audio/transcriptions"
        case .openAI:
            "https://api.openai.com/v1/audio/transcriptions"
        case .openRouter:
            "https://openrouter.ai/api/v1/audio/transcriptions"
        case .mistral:
            "https://api.mistral.ai/v1/audio/transcriptions"
        case .together:
            "https://api.together.ai/v1/audio/transcriptions"
        case .deepInfra:
            "https://api.deepinfra.com/v1/audio/transcriptions"
        case .siliconFlow:
            "https://api.siliconflow.com/v1/audio/transcriptions"
        case .scaleway:
            "https://api.scaleway.ai/v1/audio/transcriptions"
        case .ovhcloud:
            "https://oai.endpoints.kepler.ai.cloud.ovh.net/v1/audio/transcriptions"
        case .deepgram:
            "https://api.deepgram.com/v1/listen"
        case .elevenLabs:
            "https://api.elevenlabs.io/v1/speech-to-text"
        case .huggingFace:
            "https://router.huggingface.co/hf-inference/models"
        case .cloudflare, .azureOpenAI, .custom:
            ""
        case .localAI:
            "http://localhost:8080/v1/audio/transcriptions"
        case .speaches:
            "http://localhost:8000/v1/audio/transcriptions"
        case .nvidiaNIM:
            "http://localhost:9000/v1/audio/transcriptions"
        case .whisperLiveKit:
            "http://localhost:8000/v1/audio/transcriptions"
        }
    }

    var endpointIsEditable: Bool {
        switch self {
        case .cloudflare, .azureOpenAI, .localAI, .speaches, .nvidiaNIM,
             .whisperLiveKit, .custom:
            true
        default:
            false
        }
    }

    var usesRemoteEndpoint: Bool {
        self != .localWhisper
    }

    var acceptsAPIKey: Bool {
        self != .localWhisper
    }

    var endpointPlaceholder: String {
        switch self {
        case .cloudflare:
            "https://api.cloudflare.com/client/v4/accounts/ACCOUNT_ID/ai/run/@cf/openai/whisper"
        case .azureOpenAI:
            "https://RESOURCE.openai.azure.com/openai/deployments/DEPLOYMENT/audio/transcriptions?api-version=2024-10-21"
        case .custom:
            "https://provider.example/v1/audio/transcriptions"
        default:
            defaultEndpoint
        }
    }

    var endpointHelp: String? {
        let value: String?
        switch self {
        case .cloudflare:
            value = "Paste the full Workers AI model URL containing your Cloudflare account ID."
        case .azureOpenAI:
            value = "Paste the full deployment transcription URL, including api-version."
        case .localAI, .speaches, .nvidiaNIM, .whisperLiveKit:
            value = "The local default can be replaced with any reachable server URL."
        case .custom:
            value = "The endpoint must accept OpenAI-style multipart file uploads."
        default:
            value = nil
        }
        return value.map(localized)
    }

    var usesModel: Bool {
        switch self {
        case .cloudflare, .azureOpenAI:
            false
        default:
            true
        }
    }

    var requiresAPIKey: Bool {
        switch self {
        case .localWhisper, .ovhcloud, .localAI, .speaches, .nvidiaNIM,
             .whisperLiveKit, .custom:
            false
        default:
            true
        }
    }

    var keychainAccount: String {
        "provider-api-key-\(rawValue)"
    }

    var legacyKeychainAccount: String? {
        switch self {
        case .groq: "groq-api-key"
        case .openAI: "openai-api-key"
        case .custom: "custom-provider-api-key"
        default: nil
        }
    }

    var keyPlaceholder: String {
        switch self {
        case .groq: "gsk_…"
        case .openAI: "sk-…"
        case .openRouter: "sk-or-v1-…"
        case .huggingFace: "hf_…"
        case .custom, .localAI, .speaches, .nvidiaNIM, .whisperLiveKit:
            localized("Optional API key")
        default:
            localized("API key")
        }
    }

    var recommendedModels: [TranscriptionModelOption] {
        switch self {
        case .localWhisper:
            [
                .init("openai_whisper-tiny", title: "Tiny", detail: "Smallest and fastest; best for quick English dictation"),
                .init("openai_whisper-base", title: "Base", detail: "Lightweight multilingual transcription"),
                .init("openai_whisper-small", title: "Small", detail: "Recommended balance of speed and accuracy"),
                .init("openai_whisper-large-v3-v20240930_626MB", title: "Large V3", detail: "Highest local accuracy; larger download and memory use")
            ]
        case .groq:
            [
                .init("whisper-large-v3-turbo", title: "Whisper Large V3 Turbo", detail: "Fastest Groq option"),
                .init("whisper-large-v3", title: "Whisper Large V3", detail: "Higher accuracy")
            ]
        case .openAI:
            [
                .init("whisper-1", title: "Whisper", detail: "Open-source Whisper V2 via the API"),
                .init("gpt-4o-mini-transcribe", title: "GPT-4o Mini Transcribe", detail: "Fast GPT transcription"),
                .init("gpt-4o-transcribe", title: "GPT-4o Transcribe", detail: "Highest-quality OpenAI option")
            ]
        case .openRouter:
            [
                .init("openai/whisper-large-v3", title: "Whisper Large V3", detail: "Routed hosted Whisper"),
                .init("openai/whisper-large-v3-turbo", title: "Whisper Large V3 Turbo", detail: "Faster hosted Whisper"),
                .init("openai/whisper-1", title: "Whisper 1", detail: "OpenAI Whisper through OpenRouter"),
                .init("openai/gpt-4o-mini-transcribe", title: "GPT-4o Mini Transcribe", detail: "Fast OpenAI transcription"),
                .init("openai/gpt-4o-transcribe", title: "GPT-4o Transcribe", detail: "High-quality OpenAI transcription"),
                .init("nvidia/parakeet-tdt-0.6b-v3", title: "NVIDIA Parakeet TDT", detail: "Very fast English transcription"),
                .init("google/chirp-3", title: "Google Chirp 3", detail: "Multilingual Google STT")
            ]
        case .mistral:
            [
                .init("voxtral-mini-latest", title: "Voxtral Mini Transcribe", detail: "Mistral’s current batch transcription model")
            ]
        case .together:
            [
                .init("openai/whisper-large-v3", title: "Whisper Large V3", detail: "Multilingual Whisper"),
                .init("nvidia/parakeet-tdt-0.6b-v3", title: "NVIDIA Parakeet TDT", detail: "Very fast English transcription")
            ]
        case .deepInfra:
            [
                .init("openai/whisper-large", title: "Whisper Large", detail: "Best DeepInfra accuracy"),
                .init("openai/whisper-medium", title: "Whisper Medium", detail: "Balanced"),
                .init("openai/whisper-small", title: "Whisper Small", detail: "Faster"),
                .init("openai/whisper-base", title: "Whisper Base", detail: "Smallest")
            ]
        case .siliconFlow:
            [
                .init("FunAudioLLM/SenseVoiceSmall", title: "SenseVoice Small", detail: "Multilingual speech recognition")
            ]
        case .scaleway:
            [
                .init("whisper-large-v3", title: "Whisper Large V3", detail: "Serverless multilingual Whisper")
            ]
        case .ovhcloud:
            [
                .init("whisper-large-v3", title: "Whisper Large V3", detail: "OVHcloud’s multilingual transcription model")
            ]
        case .deepgram:
            [
                .init("nova-3", title: "Nova 3", detail: "Deepgram’s current general model"),
                .init("nova-2", title: "Nova 2", detail: "Previous-generation general model"),
                .init("whisper", title: "Whisper Cloud", detail: "Deepgram-hosted Whisper")
            ]
        case .elevenLabs:
            [
                .init("scribe_v2", title: "Scribe V2", detail: "Current multilingual model"),
                .init("scribe_v1", title: "Scribe V1", detail: "Previous Scribe model")
            ]
        case .huggingFace:
            [
                .init("openai/whisper-large-v3-turbo", title: "Whisper Large V3 Turbo", detail: "Fast multilingual Whisper"),
                .init("openai/whisper-large-v3", title: "Whisper Large V3", detail: "High-accuracy multilingual Whisper")
            ]
        case .localAI:
            [
                .init("whisper-1", title: "Whisper", detail: "Use the name configured in LocalAI")
            ]
        case .speaches:
            [
                .init("Systran/faster-whisper-small", title: "Faster Whisper Small", detail: "Downloaded automatically by Speaches"),
                .init("deepdml/faster-whisper-large-v3-turbo-ct2", title: "Whisper Large V3 Turbo", detail: "High-quality faster-whisper model")
            ]
        case .nvidiaNIM:
            [
                .init("whisper-large-v3", title: "Whisper Large V3", detail: "Multilingual Whisper NIM"),
                .init("parakeet-1-1b-rnnt-multilingual", title: "Parakeet Multilingual", detail: "NVIDIA multilingual ASR")
            ]
        case .whisperLiveKit:
            [
                .init("large-v3", title: "Whisper Large V3", detail: "Use the model loaded by your server")
            ]
        case .cloudflare, .azureOpenAI:
            []
        case .custom:
            [
                .init("whisper-1", title: "Whisper-compatible", detail: "Common default model ID")
            ]
        }
    }

    var defaultModel: String {
        if self == .localWhisper {
            return "openai_whisper-small"
        }
        return recommendedModels.first?.id ?? ""
    }

    var documentationURL: URL? {
        let value: String
        switch self {
        case .localWhisper: value = "https://github.com/argmaxinc/argmax-oss-swift"
        case .groq: value = "https://console.groq.com/docs/speech-to-text"
        case .openAI: value = "https://developers.openai.com/api/docs/guides/speech-to-text"
        case .openRouter: value = "https://openrouter.ai/docs/guides/overview/multimodal/stt"
        case .mistral: value = "https://docs.mistral.ai/studio-api/audio/speech_to_text"
        case .together: value = "https://docs.together.ai/docs/inference/transcription/overview"
        case .deepInfra: value = "https://docs.deepinfra.com/api-reference/audio/openai-audio-transcriptions"
        case .siliconFlow: value = "https://docs.siliconflow.com/en/api-reference/audio/create-audio-transcriptions"
        case .scaleway: value = "https://www.scaleway.com/en/developers/api/generative-apis/audio"
        case .ovhcloud: value = "https://docs.ovhcloud.com/en/guides/public-cloud/ai-machine-learning/ai-endpoints-audio-models"
        case .deepgram: value = "https://developers.deepgram.com/docs/pre-recorded-audio"
        case .elevenLabs: value = "https://elevenlabs.io/docs/api-reference/speech-to-text/convert"
        case .huggingFace: value = "https://huggingface.co/docs/inference-providers/tasks/automatic-speech-recognition"
        case .cloudflare: value = "https://developers.cloudflare.com/workers-ai/models/whisper/"
        case .azureOpenAI: value = "https://learn.microsoft.com/azure/foundry/openai/whisper-quickstart"
        case .localAI: value = "https://localai.io/features/audio-to-text/"
        case .speaches: value = "https://speaches.ai/usage/speech-to-text/"
        case .nvidiaNIM: value = "https://docs.nvidia.com/nim/speech/latest/reference/api-references/asr/http-asr.html"
        case .whisperLiveKit: value = "https://github.com/QuentinFuxa/WhisperLiveKit"
        case .custom: return nil
        }
        return URL(string: value)
    }
}
