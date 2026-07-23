import SwiftUI

struct DictationOverlayView: View {
    @ObservedObject var model: AppModel

    @ViewBuilder
    var body: some View {
        switch model.overlayStyle {
        case .orbOnly:
            orbOnlyOverlay
        case .detailed:
            detailedOverlay
        }
    }

    private var orbOnlyOverlay: some View {
        NativeOrb(
            phase: model.phase,
            audioLevel: model.audioLevel
        )
        .frame(width: 60, height: 60)
        .padding(4)
        .background {
            Circle()
                .fill(.black.opacity(0.91))
        }
        .frame(width: 72, height: 72)
        .contentShape(Circle())
        .onTapGesture {
            stopRecordingIfNeeded()
        }
        .help(title)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityHint(model.phase == .recording ? localized("Click to stop recording") : "")
    }

    private var detailedOverlay: some View {
        HStack(spacing: 14) {
            NativeOrb(
                phase: model.phase,
                audioLevel: model.audioLevel
            )
            .frame(width: 54, height: 54)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.93))
                    .lineLimit(1)

                Text(subtitle)
                    .font(.system(size: 11.5, weight: .regular, design: .rounded))
                    .foregroundStyle(.white.opacity(0.48))
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .frame(width: 286, height: 84)
        .background {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(.black.opacity(0.92))
                .overlay {
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .strokeBorder(.white.opacity(0.10), lineWidth: 0.7)
                }
        }
        .contentShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .onTapGesture {
            stopRecordingIfNeeded()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityHint(model.phase == .recording ? localized("Click to stop recording") : "")
    }

    private func stopRecordingIfNeeded() {
        if model.phase == .recording {
            model.toggleDictation()
        }
    }

    private var title: String {
        switch model.phase {
        case .idle: localized("Ready")
        case .recording: localized("Listening…")
        case .transcribing: localized("Transcribing…")
        case .success: localized("Done")
        case .failure: localized("Couldn’t transcribe")
        }
    }

    private var subtitle: String {
        switch model.phase {
        case .idle: localizedFormat("Press %@ to dictate", model.shortcut.displayString)
        case .recording:
            model.activationMode == .hold
                ? localizedFormat("Release %@ to finish", model.shortcut.displayString)
                : localizedFormat("Press %@ again to finish", model.shortcut.displayString)
        case .transcribing: model.transcriptionStatus
        case .success:
            model.completionMessage
        case let .failure(message):
            message
        }
    }
}
