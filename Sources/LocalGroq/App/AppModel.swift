import AppKit
import Foundation

enum DictationPhase: Equatable {
    case idle
    case recording
    case transcribing
    case success
    case failure(String)
}

enum LocalWhisperModelState: Equatable {
    case notDownloaded
    case downloading(Double)
    case downloaded(bytes: Int64)
    case failed(String)
}

enum DictationActivationMode: String, CaseIterable, Identifiable {
    case toggle
    case hold

    var id: String { rawValue }

    var title: String {
        switch self {
        case .toggle: localized("Toggle")
        case .hold: localized("Hold")
        }
    }

    var detail: String {
        switch self {
        case .toggle: localized("Press once to start and again to stop.")
        case .hold: localized("Hold the shortcut while speaking and release it to stop.")
        }
    }
}

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var phase: DictationPhase = .idle {
        didSet {
            // The recording indicator must leave the screen the instant recording ends.
            // Transcription and completion continue through the menu-bar state.
            onOverlayVisibilityChanged?(phase == .recording)
        }
    }
    @Published private(set) var audioLevel: Double = 0
    @Published private(set) var lastTranscript: String?
    @Published private(set) var completionMessage = "Transcription complete"
    @Published private(set) var settingsMessage: String?
    @Published private(set) var history: [TranscriptRecord]
    @Published private(set) var localWhisperModelState: LocalWhisperModelState = .notDownloaded
    @Published private(set) var localWhisperCacheSize: Int64 = 0

    @Published var apiKey: String {
        didSet {
            if apiKey != oldValue { settingsMessage = nil }
        }
    }
    @Published var selectedProvider: TranscriptionProvider {
        didSet {
            guard selectedProvider != oldValue else { return }
            apiKeyDrafts[oldValue] = apiKey
            modelDrafts[oldValue] = modelName
            endpointDrafts[oldValue] = endpoint
            apiKey = apiKeyDrafts[selectedProvider]
                ?? storedAPIKey(for: selectedProvider)
                ?? ""
            modelName = modelDrafts[selectedProvider]
                ?? Self.storedModel(for: selectedProvider, defaults: .standard)
            endpoint = endpointDrafts[selectedProvider]
                ?? Self.storedEndpoint(for: selectedProvider, defaults: .standard)
            settingsMessage = nil
        }
    }
    @Published var modelName: String {
        didSet {
            if modelName != oldValue {
                settingsMessage = nil
                refreshLocalWhisperModelState()
            }
        }
    }
    @Published var endpoint: String {
        didSet {
            if endpoint != oldValue { settingsMessage = nil }
        }
    }
    @Published var language: String {
        didSet {
            if language != oldValue { settingsMessage = nil }
        }
    }
    @Published var pasteAutomatically: Bool {
        didSet {
            if pasteAutomatically != oldValue { settingsMessage = nil }
        }
    }
    @Published var copyToClipboard: Bool {
        didSet {
            if copyToClipboard != oldValue { settingsMessage = nil }
        }
    }
    @Published var preserveHistory: Bool {
        didSet {
            if preserveHistory != oldValue { settingsMessage = nil }
        }
    }
    @Published var overlayStyle: OverlayStyle {
        didSet {
            if overlayStyle != oldValue {
                settingsMessage = nil
                onOverlayStyleChanged?(overlayStyle)
            }
        }
    }
    @Published var shortcut: GlobalShortcut {
        didSet {
            guard shortcut != oldValue, !isRevertingShortcut else { return }
            if let onShortcutChanged, !onShortcutChanged(shortcut) {
                isRevertingShortcut = true
                shortcut = oldValue
                isRevertingShortcut = false
                settingsMessage = localized("That shortcut is already in use")
                return
            }
            Self.storeShortcut(shortcut, defaults: .standard)
            settingsMessage = localizedFormat(
                "Shortcut changed to %@",
                shortcut.displayString
            )
        }
    }
    @Published var activationMode: DictationActivationMode {
        didSet {
            guard activationMode != oldValue else { return }
            UserDefaults.standard.set(
                activationMode.rawValue,
                forKey: DefaultsKey.activationMode
            )
            settingsMessage = nil
        }
    }

    var onOverlayVisibilityChanged: ((Bool) -> Void)?
    var onOverlayStyleChanged: ((OverlayStyle) -> Void)?
    var onShowSettings: (() -> Void)?
    var onShowHistory: (() -> Void)?
    var onShortcutChanged: ((GlobalShortcut) -> Bool)?

    private let recorder: AudioRecorder
    private let client: TranscriptionClient
    private let localWhisper: LocalWhisperTranscriber
    private let keychain: KeychainStore
    private let insertionService: TextInsertionService
    private let historyStore: TranscriptHistoryStore
    private var apiKeyDrafts: [TranscriptionProvider: String] = [:]
    private var modelDrafts: [TranscriptionProvider: String] = [:]
    private var endpointDrafts: [TranscriptionProvider: String] = [:]
    private var targetApplication: NSRunningApplication?
    private var resetTask: Task<Void, Never>?
    private var isRevertingShortcut = false

    private enum DefaultsKey {
        static let provider = "transcriptionProvider"
        static let legacyGroqModel = "transcriptionModel"
        static let groqModel = "groqTranscriptionModel"
        static let openAIModel = "openAITranscriptionModel"
        static let customModel = "customTranscriptionModel"
        static let customEndpoint = "customTranscriptionEndpoint"
        static let providerModelPrefix = "providerModel."
        static let providerEndpointPrefix = "providerEndpoint."
        static let language = "transcriptionLanguage"
        static let pasteAutomatically = "pasteAutomatically"
        static let copyToClipboard = "copyToClipboard"
        static let preserveHistory = "preserveHistory"
        static let overlayStyle = "overlayStyle"
        static let shortcutKeyCode = "shortcutKeyCode"
        static let shortcutModifiers = "shortcutModifiers"
        static let shortcutKeyLabel = "shortcutKeyLabel"
        static let activationMode = "shortcutActivationMode"
    }

    init(
        recorder: AudioRecorder = AudioRecorder(),
        client: TranscriptionClient = TranscriptionClient(),
        localWhisper: LocalWhisperTranscriber = LocalWhisperTranscriber(),
        keychain: KeychainStore = KeychainStore(),
        insertionService: TextInsertionService = TextInsertionService(),
        historyStore: TranscriptHistoryStore = TranscriptHistoryStore()
    ) {
        self.recorder = recorder
        self.client = client
        self.localWhisper = localWhisper
        self.keychain = keychain
        self.insertionService = insertionService
        self.historyStore = historyStore

        let defaults = UserDefaults.standard
        let storedProvider = defaults.string(forKey: DefaultsKey.provider)
        let provider = TranscriptionProvider(rawValue: storedProvider ?? "") ?? .localWhisper
        selectedProvider = provider

        modelName = Self.storedModel(for: provider, defaults: defaults)
        endpoint = Self.storedEndpoint(for: provider, defaults: defaults)
        language = defaults.string(forKey: DefaultsKey.language) ?? ""
        #if APP_STORE
        pasteAutomatically = false
        #else
        pasteAutomatically = defaults.object(forKey: DefaultsKey.pasteAutomatically) as? Bool ?? true
        #endif
        copyToClipboard = defaults.object(forKey: DefaultsKey.copyToClipboard) as? Bool ?? true
        preserveHistory = defaults.object(forKey: DefaultsKey.preserveHistory) as? Bool ?? true
        overlayStyle = OverlayStyle(
            rawValue: defaults.string(forKey: DefaultsKey.overlayStyle) ?? ""
        ) ?? .orbOnly
        shortcut = Self.storedShortcut(defaults: defaults)
        activationMode = DictationActivationMode(
            rawValue: defaults.string(forKey: DefaultsKey.activationMode) ?? ""
        ) ?? .toggle
        apiKey = (try? keychain.read(account: provider.keychainAccount))
            ?? provider.legacyKeychainAccount.flatMap { try? keychain.read(account: $0) }
            ?? ""
        history = ((try? historyStore.load()) ?? []).sorted { $0.createdAt > $1.createdAt }

        recorder.onLevel = { [weak self] level in
            Task { @MainActor in
                self?.audioLevel = level
            }
        }

        refreshLocalWhisperModelState()
    }

    var primaryActionTitle: String {
        switch phase {
        case .recording: localized("Stop Recording")
        case .transcribing: localized("Transcribing…")
        default: localized("Start Dictation")
        }
    }

    var menuBarIcon: String {
        switch phase {
        case .recording: "waveform.circle.fill"
        case .transcribing: "ellipsis.circle.fill"
        case .success: "checkmark.circle.fill"
        case .failure: "exclamationmark.circle.fill"
        case .idle: "waveform.circle"
        }
    }

    var hasAccessibilityPermission: Bool {
        insertionService.isAccessibilityTrusted
    }

    var automaticPasteAvailable: Bool {
        #if APP_STORE
        false
        #else
        true
        #endif
    }

    var activeModel: String {
        modelName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var activeModelDetail: String {
        if let detail = selectedProvider.recommendedModels.first(where: {
            $0.id == activeModel
        })?.detail {
            return localized(detail)
        }
        return localized(
            selectedProvider.usesModel
                ? "Custom model ID"
                : "The deployment is selected by the endpoint URL"
        )
    }

    var localWhisperModelRepositoryURL: URL? {
        guard selectedProvider == .localWhisper, !activeModel.isEmpty else {
            return nil
        }
        return localWhisper.modelRepositoryURL(for: activeModel)
    }

    var isLocalWhisperModelDownloading: Bool {
        if case .downloading = localWhisperModelState {
            return true
        }
        return false
    }

    var transcriptionStatus: String {
        if selectedProvider == .localWhisper {
            localized("Transcribing privately on this Mac")
        } else {
            localizedFormat("Sending audio securely to %@", selectedProvider.title)
        }
    }

    func toggleDictation() {
        resetTask?.cancel()

        switch phase {
        case .recording:
            stopAndTranscribe()
        case .transcribing:
            break
        case .idle, .success, .failure:
            startRecording()
        }
    }

    func handleShortcut(isPressed: Bool) {
        switch activationMode {
        case .toggle:
            if isPressed {
                toggleDictation()
            }
        case .hold:
            if isPressed {
                resetTask?.cancel()
                switch phase {
                case .idle, .success, .failure:
                    startRecording()
                case .recording, .transcribing:
                    break
                }
            } else if phase == .recording {
                stopAndTranscribe()
            }
        }
    }

    func saveSettings() {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLanguage = language.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let trimmedModel = modelName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEndpoint = endpoint.trimmingCharacters(in: .whitespacesAndNewlines)

        if selectedProvider.usesModel && trimmedModel.isEmpty {
            settingsMessage = localized("Enter a model name")
            return
        }
        guard !selectedProvider.usesRemoteEndpoint
                || Self.validEndpoint(from: trimmedEndpoint) != nil else {
            settingsMessage = localized("Enter a valid HTTP or HTTPS transcription endpoint")
            return
        }

        do {
            if selectedProvider.acceptsAPIKey {
                if trimmedKey.isEmpty {
                    try keychain.delete(account: selectedProvider.keychainAccount)
                    if let legacyAccount = selectedProvider.legacyKeychainAccount {
                        try keychain.delete(account: legacyAccount)
                    }
                } else {
                    try keychain.save(trimmedKey, account: selectedProvider.keychainAccount)
                }
            }

            apiKey = trimmedKey
            apiKeyDrafts[selectedProvider] = trimmedKey
            language = trimmedLanguage
            modelName = trimmedModel
            endpoint = trimmedEndpoint
            modelDrafts[selectedProvider] = trimmedModel
            endpointDrafts[selectedProvider] = trimmedEndpoint

            let defaults = UserDefaults.standard
            defaults.set(selectedProvider.rawValue, forKey: DefaultsKey.provider)
            defaults.set(
                trimmedModel,
                forKey: DefaultsKey.providerModelPrefix + selectedProvider.rawValue
            )
            defaults.set(
                trimmedEndpoint,
                forKey: DefaultsKey.providerEndpointPrefix + selectedProvider.rawValue
            )
            defaults.set(trimmedLanguage, forKey: DefaultsKey.language)
            let effectivePaste = automaticPasteAvailable && pasteAutomatically
            pasteAutomatically = effectivePaste
            defaults.set(effectivePaste, forKey: DefaultsKey.pasteAutomatically)
            defaults.set(copyToClipboard, forKey: DefaultsKey.copyToClipboard)
            defaults.set(preserveHistory, forKey: DefaultsKey.preserveHistory)
            defaults.set(overlayStyle.rawValue, forKey: DefaultsKey.overlayStyle)
            if selectedProvider == .localWhisper {
                settingsMessage = localized("Saved")
            } else {
                settingsMessage = localized(
                    trimmedKey.isEmpty ? "Saved" : "Saved · API key is in Keychain"
                )
            }
        } catch {
            settingsMessage = error.localizedDescription
        }
    }

    func requestAccessibilityPermission() {
        insertionService.requestAccessibilityPermission()
        objectWillChange.send()
    }

    func openAccessibilitySettings() {
        insertionService.openAccessibilitySettings()
    }

    func showSettings() {
        onShowSettings?()
    }

    func showHistory() {
        onShowHistory?()
    }

    func reportHotKeyRegistrationFailure() {
        settingsMessage = localized("The saved shortcut could not be registered")
    }

    func downloadSelectedLocalWhisperModel() {
        let model = activeModel
        guard selectedProvider == .localWhisper,
              !model.isEmpty,
              !isLocalWhisperModelDownloading else {
            return
        }

        localWhisperModelState = .downloading(0)
        Task { [weak self] in
            guard let self else { return }
            do {
                try await localWhisper.download(model: model) { [weak self] progress in
                    Task { @MainActor [weak self] in
                        guard let self,
                              self.selectedProvider == .localWhisper,
                              self.activeModel == model else {
                            return
                        }
                        self.localWhisperModelState = .downloading(
                            max(0, min(1, progress))
                        )
                    }
                }
                if selectedProvider == .localWhisper, activeModel == model {
                    refreshLocalWhisperModelState()
                }
            } catch {
                if selectedProvider == .localWhisper, activeModel == model {
                    localWhisperModelState = .failed(error.localizedDescription)
                    localWhisperCacheSize = localWhisper.cacheSize()
                }
            }
        }
    }

    func removeSelectedLocalWhisperModel() {
        guard selectedProvider == .localWhisper,
              !activeModel.isEmpty,
              !isLocalWhisperModelDownloading else {
            return
        }

        do {
            try localWhisper.removeModel(activeModel)
            refreshLocalWhisperModelState()
        } catch {
            localWhisperModelState = .failed(error.localizedDescription)
        }
    }

    func clearLocalWhisperCache() {
        guard !isLocalWhisperModelDownloading else { return }
        do {
            try localWhisper.clearCache()
            refreshLocalWhisperModelState()
        } catch {
            localWhisperModelState = .failed(error.localizedDescription)
        }
    }

    func revealSelectedLocalWhisperModel() {
        guard selectedProvider == .localWhisper,
              localWhisper.isModelDownloaded(activeModel) else {
            return
        }
        NSWorkspace.shared.activateFileViewerSelecting([
            localWhisper.modelFolder(for: activeModel)
        ])
    }

    func importSelectedLocalWhisperModel() {
        guard selectedProvider == .localWhisper,
              !activeModel.isEmpty,
              !isLocalWhisperModelDownloading else {
            return
        }

        let panel = NSOpenPanel()
        panel.title = localized("Import WhisperKit Model")
        panel.message = localizedFormat(
            "Choose the %@ model folder or a WhisperKit model repository containing it.",
            activeModel
        )
        panel.prompt = localized("Import Model")
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false

        guard panel.runModal() == .OK, let folder = panel.url else { return }
        do {
            try localWhisper.importModel(from: folder, model: activeModel)
            refreshLocalWhisperModelState()
            settingsMessage = "Imported \(activeModel)"
        } catch {
            localWhisperModelState = .failed(error.localizedDescription)
            localWhisperCacheSize = localWhisper.cacheSize()
        }
    }

    func copyTranscript(_ transcript: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(transcript, forType: .string)
    }

    func deleteHistoryRecord(id: UUID) {
        history.removeAll { $0.id == id }
        persistHistory()
    }

    func clearHistory() {
        history = []
        persistHistory()
    }

    private func startRecording() {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !selectedProvider.requiresAPIKey || !trimmedKey.isEmpty else {
            showFailure("Add your \(selectedProvider.title) API key in Settings")
            return
        }
        guard !selectedProvider.usesRemoteEndpoint || endpointURL != nil else {
            showFailure("Add a valid transcription endpoint in Settings")
            return
        }
        guard !selectedProvider.usesModel || !activeModel.isEmpty else {
            showFailure("Add a transcription model in Settings")
            return
        }
        guard selectedProvider != .localWhisper
                || localWhisper.isModelDownloaded(activeModel) else {
            settingsMessage = localized("Download the selected Whisper model before dictating")
            refreshLocalWhisperModelState()
            showSettings()
            return
        }

        targetApplication = automaticPasteAvailable
            ? NSWorkspace.shared.frontmostApplication
            : nil
        audioLevel = 0

        Task {
            do {
                try await recorder.start()
                phase = .recording
            } catch {
                showFailure(error.localizedDescription)
            }
        }
    }

    private func stopAndTranscribe() {
        guard let audioURL = recorder.stop() else {
            showFailure(localized("No recording was available"))
            return
        }
        let provider = selectedProvider
        let endpoint = endpointURL
        guard !provider.usesRemoteEndpoint || endpoint != nil else {
            try? FileManager.default.removeItem(at: audioURL)
            showFailure("The transcription endpoint is invalid")
            return
        }

        audioLevel = 0
        phase = .transcribing

        let apiKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let model = activeModel
        let language = normalizedLanguage
        let targetApplication = targetApplication
        let shouldPaste = automaticPasteAvailable && pasteAutomatically
        let shouldCopy = copyToClipboard
        let shouldPreserveHistory = preserveHistory

        Task {
            defer { try? FileManager.default.removeItem(at: audioURL) }

            do {
                let transcript: String
                if provider == .localWhisper {
                    transcript = try await localWhisper.transcribe(
                        audioFileURL: audioURL,
                        model: model,
                        language: language
                    )
                } else if let endpoint {
                    transcript = try await client.transcribe(
                        audioFileURL: audioURL,
                        endpoint: endpoint,
                        provider: provider,
                        apiKey: apiKey,
                        model: model,
                        language: language
                    )
                } else {
                    throw URLError(.badURL)
                }

                lastTranscript = transcript
                if shouldPreserveHistory {
                    addHistoryRecord(
                        text: transcript,
                        provider: provider.title,
                        model: model.isEmpty ? "Deployment endpoint" : model
                    )
                }

                let delivery = await insertionService.deliver(
                    transcript,
                    to: targetApplication,
                    pasteAutomatically: shouldPaste,
                    copyToClipboard: shouldCopy
                )
                completionMessage = completionText(
                    for: delivery,
                    wasSavedToHistory: shouldPreserveHistory
                )
                phase = .success
                scheduleReset(after: .milliseconds(1100))
            } catch {
                showFailure(error.localizedDescription)
            }
        }
    }

    private var endpointURL: URL? {
        return Self.validEndpoint(from: endpoint)
    }

    private static func validEndpoint(from value: String) -> URL? {
        guard let url = URL(string: value),
              let scheme = url.scheme?.lowercased(),
              scheme == "https" || scheme == "http",
              url.host != nil else {
            return nil
        }
        return url
    }

    private func storedAPIKey(for provider: TranscriptionProvider) -> String? {
        if let value = try? keychain.read(account: provider.keychainAccount),
           !value.isEmpty {
            return value
        }
        if let legacyAccount = provider.legacyKeychainAccount,
           let value = try? keychain.read(account: legacyAccount),
           !value.isEmpty {
            return value
        }
        return nil
    }

    private static func storedModel(
        for provider: TranscriptionProvider,
        defaults: UserDefaults
    ) -> String {
        if let value = defaults.string(
            forKey: DefaultsKey.providerModelPrefix + provider.rawValue
        ), !value.isEmpty {
            return value
        }

        let legacyValue: String?
        switch provider {
        case .groq:
            legacyValue = defaults.string(forKey: DefaultsKey.groqModel)
                ?? defaults.string(forKey: DefaultsKey.legacyGroqModel)
        case .openAI:
            legacyValue = defaults.string(forKey: DefaultsKey.openAIModel)
        case .custom:
            legacyValue = defaults.string(forKey: DefaultsKey.customModel)
        default:
            legacyValue = nil
        }
        return legacyValue.flatMap { $0.isEmpty ? nil : $0 } ?? provider.defaultModel
    }

    private static func storedEndpoint(
        for provider: TranscriptionProvider,
        defaults: UserDefaults
    ) -> String {
        if let value = defaults.string(
            forKey: DefaultsKey.providerEndpointPrefix + provider.rawValue
        ), !value.isEmpty {
            return value
        }
        if provider == .custom,
           let legacyValue = defaults.string(forKey: DefaultsKey.customEndpoint),
           !legacyValue.isEmpty {
            return legacyValue
        }
        return provider.defaultEndpoint
    }

    private static func storedShortcut(defaults: UserDefaults) -> GlobalShortcut {
        guard defaults.object(forKey: DefaultsKey.shortcutKeyCode) != nil,
              defaults.object(forKey: DefaultsKey.shortcutModifiers) != nil,
              let keyLabel = defaults.string(forKey: DefaultsKey.shortcutKeyLabel),
              !keyLabel.isEmpty else {
            return .optionSpace
        }
        return GlobalShortcut(
            keyCode: UInt32(defaults.integer(forKey: DefaultsKey.shortcutKeyCode)),
            modifiers: UInt32(defaults.integer(forKey: DefaultsKey.shortcutModifiers)),
            keyLabel: keyLabel
        )
    }

    private static func storeShortcut(
        _ shortcut: GlobalShortcut,
        defaults: UserDefaults
    ) {
        defaults.set(Int(shortcut.keyCode), forKey: DefaultsKey.shortcutKeyCode)
        defaults.set(Int(shortcut.modifiers), forKey: DefaultsKey.shortcutModifiers)
        defaults.set(shortcut.keyLabel, forKey: DefaultsKey.shortcutKeyLabel)
    }

    private var normalizedLanguage: String? {
        let trimmed = language.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed.lowercased()
    }

    private func addHistoryRecord(text: String, provider: String, model: String) {
        history.insert(
            TranscriptRecord(text: text, provider: provider, model: model),
            at: 0
        )
        if history.count > 250 {
            history.removeLast(history.count - 250)
        }
        persistHistory()
    }

    private func persistHistory() {
        do {
            try historyStore.save(history)
        } catch {
            settingsMessage = "History could not be saved: \(error.localizedDescription)"
        }
    }

    private func refreshLocalWhisperModelState() {
        guard selectedProvider == .localWhisper else { return }
        let model = activeModel
        guard !model.isEmpty else {
            localWhisperModelState = .notDownloaded
            localWhisperCacheSize = localWhisper.cacheSize()
            return
        }

        if localWhisper.isModelDownloaded(model) {
            localWhisperModelState = .downloaded(
                bytes: localWhisper.modelSize(model)
            )
        } else {
            localWhisperModelState = .notDownloaded
        }
        localWhisperCacheSize = localWhisper.cacheSize()
    }

    private func completionText(
        for delivery: TextDeliveryResult,
        wasSavedToHistory: Bool
    ) -> String {
        switch delivery {
        case let .pasted(copiedToClipboard):
            return localized(copiedToClipboard ? "Pasted and copied" : "Pasted · clipboard preserved")
        case .copied:
            return localized("Copied to the clipboard")
        case .historyOnly:
            return localized(wasSavedToHistory ? "Saved to history" : "Transcription complete")
        case let .pasteUnavailable(copiedToClipboard, reason):
            let destination = copiedToClipboard
                ? "Copied"
                : (wasSavedToHistory ? "Saved to history" : "Transcription complete")
            switch reason {
            case .accessibilityIsMissing:
                return "\(destination) · enable Accessibility to paste"
            case .targetIsUnavailable:
                return "\(destination) · the previous app is unavailable"
            case .pasteEventCouldNotBeCreated:
                return "\(destination) · automatic paste failed"
            }
        }
    }

    private func showFailure(_ message: String) {
        recorder.cancel()
        audioLevel = 0
        phase = .failure(message)
        scheduleReset(after: .seconds(3))
    }

    private func scheduleReset(after duration: Duration) {
        resetTask?.cancel()
        resetTask = Task { [weak self] in
            try? await Task.sleep(for: duration)
            guard !Task.isCancelled else { return }
            self?.phase = .idle
        }
    }
}
