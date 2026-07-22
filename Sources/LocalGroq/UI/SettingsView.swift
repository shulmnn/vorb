import AppKit
import SwiftUI

private enum SettingsTab: Hashable {
    case transcription
    case shortcut
    case behavior
    case about
}

private enum SettingsField: Hashable {
    case endpoint
    case apiKey
    case model
    case language
}

struct SettingsView: View {
    @ObservedObject var model: AppModel
    @AppStorage("showMenuBarIcon") private var showMenuBarIcon = true
    @State private var selectedTab: SettingsTab = .transcription
    @State private var keyIsVisible = false
    @State private var autoSaveTask: Task<Void, Never>?
    @State private var isConfirmingModelRemoval = false
    @State private var isConfirmingCacheClear = false
    @FocusState private var focusedField: SettingsField?

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $selectedTab) {
                transcriptionTab
                    .tabItem { Label("Transcription", systemImage: "waveform") }
                    .tag(SettingsTab.transcription)

                shortcutTab
                    .tabItem { Label("Shortcut", systemImage: "command") }
                    .tag(SettingsTab.shortcut)

                behaviorTab
                    .tabItem { Label("Behavior", systemImage: "switch.2") }
                    .tag(SettingsTab.behavior)

                aboutTab
                    .tabItem { Label("About", systemImage: "info.circle") }
                    .tag(SettingsTab.about)
            }
            .padding(.top, 8)

            Divider()

            statusBar
                .padding(.horizontal, 20)
                .frame(height: 36)
                .background(.bar)
        }
        .background {
            Color(nsColor: .windowBackgroundColor)
                .contentShape(Rectangle())
                .onTapGesture {
                    dismissTextFieldFocus()
                }
        }
        .onExitCommand {
            dismissTextFieldFocus()
        }
        .onChange(of: selectedTab) { _, _ in
            dismissTextFieldFocus()
        }
        .onChange(of: settingsSnapshot) { _, _ in
            scheduleAutoSave()
        }
        .onDisappear {
            autoSaveTask?.cancel()
            model.saveSettings()
        }
        .confirmationDialog(
            "Remove the selected Whisper model?",
            isPresented: $isConfirmingModelRemoval
        ) {
            Button("Remove Model", role: .destructive) {
                model.removeSelectedLocalWhisperModel()
            }
        } message: {
            Text("Vorb will require another download before this model can be used again.")
        }
        .confirmationDialog(
            "Clear all Local Whisper models?",
            isPresented: $isConfirmingCacheClear
        ) {
            Button("Clear Model Cache", role: .destructive) {
                model.clearLocalWhisperCache()
            }
        } message: {
            Text("This removes every downloaded model and partial model download from Vorb.")
        }
    }

    private var transcriptionTab: some View {
        SettingsPage {
            SettingsGroup("Provider") {
                Picker("Service", selection: providerBinding) {
                    ForEach(TranscriptionProvider.allCases) { provider in
                        Text(provider.title).tag(provider)
                    }
                }

                Text(model.selectedProvider.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if model.selectedProvider == .localWhisper {
                    HStack {
                        Label("Private · no API key", systemImage: "lock.shield")
                            .foregroundStyle(.secondary)
                        Spacer()
                        if let documentationURL = model.selectedProvider.documentationURL {
                            Link("WhisperKit", destination: documentationURL)
                        }
                    }
                    .font(.caption)
                } else {
                    providerCredentials
                }
            }

            SettingsGroup("Model & language") {
                if model.selectedProvider.usesModel {
                    LabeledContent("Model") {
                        modelPicker
                    }

                    Text(model.activeModelDetail)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if model.selectedProvider == .localWhisper {
                        localWhisperModelManagement
                    }
                } else {
                    Text("The deployment or model is selected by the endpoint URL.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                LabeledContent("Language") {
                    TextField("Auto-detect", text: $model.language)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 160)
                        .focused($focusedField, equals: .language)
                }

                Text("Leave blank to auto-detect, or enter an ISO-639-1 code such as en, de, fr, or ru.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var providerCredentials: some View {
        if model.selectedProvider.endpointIsEditable {
            LabeledContent("Endpoint") {
                TextField(
                    model.selectedProvider.endpointPlaceholder,
                    text: $model.endpoint
                )
                .textFieldStyle(.roundedBorder)
                .frame(width: 330)
                .focused($focusedField, equals: .endpoint)
            }

            if let endpointHelp = model.selectedProvider.endpointHelp {
                Text(endpointHelp)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } else {
            LabeledContent("Endpoint") {
                Text(model.selectedProvider.defaultEndpoint)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .textSelection(.enabled)
            }
        }

        LabeledContent(
            model.selectedProvider.requiresAPIKey ? "API key" : "API key (optional)"
        ) {
            HStack(spacing: 7) {
                Group {
                    if keyIsVisible {
                        TextField(model.selectedProvider.keyPlaceholder, text: $model.apiKey)
                            .focused($focusedField, equals: .apiKey)
                    } else {
                        SecureField(model.selectedProvider.keyPlaceholder, text: $model.apiKey)
                            .focused($focusedField, equals: .apiKey)
                    }
                }
                .textFieldStyle(.roundedBorder)
                .frame(width: 290)

                Button {
                    keyIsVisible.toggle()
                } label: {
                    Image(systemName: keyIsVisible ? "eye.slash" : "eye")
                }
                .buttonStyle(.borderless)
                .help(keyIsVisible ? "Hide API key" : "Show API key")
            }
        }

        HStack {
            Text("Stored in Keychain. Audio goes directly to the selected provider.")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            if let documentationURL = model.selectedProvider.documentationURL {
                Link("API documentation", destination: documentationURL)
                    .font(.caption)
            }
        }
    }

    @ViewBuilder
    private var modelPicker: some View {
        if model.selectedProvider == .localWhisper {
            Picker("Model", selection: $model.modelName) {
                ForEach(model.selectedProvider.recommendedModels) { option in
                    Text(option.title).tag(option.id)
                }
            }
            .labelsHidden()
            .frame(width: 210)
            .disabled(model.isLocalWhisperModelDownloading)
        } else {
            HStack(spacing: 6) {
                TextField(model.selectedProvider.defaultModel, text: $model.modelName)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 280)
                    .focused($focusedField, equals: .model)

                if !model.selectedProvider.recommendedModels.isEmpty {
                    Menu {
                        ForEach(model.selectedProvider.recommendedModels) { option in
                            Button(option.title) {
                                model.modelName = option.id
                            }
                        }
                    } label: {
                        Image(systemName: "list.bullet")
                    }
                    .menuStyle(.borderlessButton)
                    .fixedSize()
                    .help("Recommended models")
                }
            }
        }
    }

    private var localWhisperModelManagement: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                localWhisperModelStatus
                Spacer()

                switch model.localWhisperModelState {
                case .notDownloaded, .failed:
                    Button("Download Model") {
                        model.downloadSelectedLocalWhisperModel()
                    }
                    .disabled(model.activeModel.isEmpty)
                case .downloading:
                    Button("Downloading…") {}
                        .disabled(true)
                case .downloaded:
                    Button("Reveal in Finder") {
                        model.revealSelectedLocalWhisperModel()
                    }
                    Button("Remove…", role: .destructive) {
                        isConfirmingModelRemoval = true
                    }
                }
            }

            if case let .downloading(progress) = model.localWhisperModelState {
                ProgressView(value: progress)
                Text("Downloading \(progress.formatted(.percent.precision(.fractionLength(0))))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                if let repositoryURL = model.localWhisperModelRepositoryURL {
                    Link("Model page", destination: repositoryURL)
                }
                Button("Import Existing…") {
                    model.importSelectedLocalWhisperModel()
                }
                .disabled(model.isLocalWhisperModelDownloading)
                Spacer()
                Button("Clear Cache…") {
                    isConfirmingCacheClear = true
                }
                .disabled(
                    model.localWhisperCacheSize == 0
                    || model.isLocalWhisperModelDownloading
                )
            }
            .font(.caption)
        }
        .padding(10)
        .background(.quaternary.opacity(0.25), in: RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    private var localWhisperModelStatus: some View {
        switch model.localWhisperModelState {
        case .notDownloaded:
            Label("Not downloaded", systemImage: "arrow.down.circle")
                .foregroundStyle(.secondary)
        case .downloading:
            Label("Downloading", systemImage: "arrow.down.circle.fill")
                .foregroundStyle(.secondary)
        case let .downloaded(bytes):
            Label(
                "Downloaded · \(Self.byteCountFormatter.string(fromByteCount: bytes))",
                systemImage: "checkmark.circle.fill"
            )
            .foregroundStyle(.green)
        case let .failed(message):
            Label(message, systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
                .lineLimit(2)
        }
    }

    private var shortcutTab: some View {
        SettingsPage {
            SettingsGroup("Global shortcut") {
                LabeledContent("Start or stop dictation") {
                    ShortcutRecorder(shortcut: $model.shortcut)
                        .frame(width: 150)
                }

                Picker("Behavior", selection: $model.activationMode) {
                    ForEach(DictationActivationMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                Text(model.activationMode.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            SettingsGroup("How to change it") {
                Label(
                    "Click the shortcut field, then press a key with Command, Option, or Control.",
                    systemImage: "keyboard"
                )
                Text("Press Escape to cancel. The shortcut keeps working when the menu bar icon is hidden.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var behaviorTab: some View {
        SettingsPage {
            SettingsGroup("Recording indicator") {
                Picker("Style", selection: $model.overlayStyle) {
                    ForEach(OverlayStyle.allCases) { style in
                        Text(style.title).tag(style)
                    }
                }
                .pickerStyle(.segmented)

                Text(model.overlayStyle.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            SettingsGroup("Text delivery") {
                if model.automaticPasteAvailable {
                    Toggle("Paste into the previously active app", isOn: $model.pasteAutomatically)
                }
                Toggle("Copy transcript to the clipboard", isOn: $model.copyToClipboard)

                if !model.automaticPasteAvailable {
                    Text("The Mac App Store build copies text to the clipboard so you can paste it normally.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if model.pasteAutomatically && !model.hasAccessibilityPermission {
                    HStack {
                        Label("Accessibility access is required for automatic paste", systemImage: "exclamationmark.circle")
                            .foregroundStyle(.orange)
                        Spacer()
                        Button("Request Access") {
                            model.requestAccessibilityPermission()
                        }
                        Button("Open Settings") {
                            model.openAccessibilitySettings()
                        }
                    }
                    .font(.caption)
                }
            }

            SettingsGroup("History & menu bar") {
                Toggle("Save transcription history on this Mac", isOn: $model.preserveHistory)
                HStack {
                    Text(savedTranscriptCount)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Open History…") {
                        model.showHistory()
                    }
                }
                Divider()
                Toggle("Show Vorb in the menu bar", isOn: $showMenuBarIcon)
            }
        }
    }

    private var aboutTab: some View {
        SettingsPage {
            HStack(spacing: 14) {
                Image(nsImage: NSApplication.shared.applicationIconImage)
                    .resizable()
                    .interpolation(.high)
                    .frame(width: 58, height: 58)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Vorb")
                        .font(.title2.weight(.semibold))
                    Text("Private Whisper dictation for macOS")
                        .foregroundStyle(.secondary)
                    Text(versionText)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            SettingsGroup("Community") {
                Link(destination: AppLinks.github) {
                    Label("View source and star Vorb on GitHub", systemImage: "star")
                }

                Text("Report issues, request features, or fork Vorb for noncommercial use.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let reviewURL = AppLinks.appStoreReview {
                    Link(destination: reviewURL) {
                        Label("Rate Vorb on the Mac App Store", systemImage: "hand.thumbsup")
                    }
                }
            }

            SettingsGroup("Help & privacy") {
                HStack(spacing: 18) {
                    Link("Privacy Policy", destination: AppLinks.privacy)
                    Link("Support", destination: AppLinks.support)
                    Link(AppLinks.supportEmail, destination: AppLinks.supportEmailURL)
                }

                Text("No Vorb account, analytics, advertising, or application backend.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text("Source available under the PolyForm Noncommercial License 1.0.0.")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }

    private var statusBar: some View {
        HStack {
            if let message = model.settingsMessage {
                Text(message)
                    .transition(.opacity)
            } else {
                Label("Changes save automatically", systemImage: "checkmark.circle")
            }
            Spacer()
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    private var providerBinding: Binding<TranscriptionProvider> {
        Binding(
            get: { model.selectedProvider },
            set: { provider in
                guard provider != model.selectedProvider else { return }
                autoSaveTask?.cancel()
                model.saveSettings()
                model.selectedProvider = provider
            }
        )
    }

    private var savedTranscriptCount: String {
        model.history.count == 1
            ? localized("1 saved transcript")
            : localizedFormat("%lld saved transcripts", Int64(model.history.count))
    }

    private var versionText: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "2"
        return localizedFormat("Version %@ (%@)", version, build)
    }

    private static let byteCountFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter
    }()

    private var settingsSnapshot: SettingsSnapshot {
        SettingsSnapshot(
            provider: model.selectedProvider,
            apiKey: model.apiKey,
            modelName: model.modelName,
            endpoint: model.endpoint,
            language: model.language,
            pasteAutomatically: model.pasteAutomatically,
            copyToClipboard: model.copyToClipboard,
            preserveHistory: model.preserveHistory,
            overlayStyle: model.overlayStyle,
            activationMode: model.activationMode
        )
    }

    private func scheduleAutoSave() {
        autoSaveTask?.cancel()
        autoSaveTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(450))
            guard !Task.isCancelled else { return }
            model.saveSettings()
        }
    }

    private func dismissTextFieldFocus() {
        focusedField = nil
        NSApp.keyWindow?.makeFirstResponder(nil)
    }

}

private struct SettingsPage<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                content
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct SettingsGroup<Content: View>: View {
    let title: LocalizedStringKey
    @ViewBuilder let content: Content

    init(_ title: LocalizedStringKey, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(title)
                .font(.headline)

            VStack(alignment: .leading, spacing: 9) {
                content
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.quaternary.opacity(0.16), in: RoundedRectangle(cornerRadius: 9))
        }
    }
}

private struct SettingsSnapshot: Equatable {
    let provider: TranscriptionProvider
    let apiKey: String
    let modelName: String
    let endpoint: String
    let language: String
    let pasteAutomatically: Bool
    let copyToClipboard: Bool
    let preserveHistory: Bool
    let overlayStyle: OverlayStyle
    let activationMode: DictationActivationMode
}
