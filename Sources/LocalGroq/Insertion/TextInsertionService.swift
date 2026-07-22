import AppKit
#if !APP_STORE
import ApplicationServices
#endif
import Foundation

enum TextDeliveryFallbackReason {
    case accessibilityIsMissing
    case targetIsUnavailable
    case pasteEventCouldNotBeCreated
}

enum TextDeliveryResult {
    case pasted(copiedToClipboard: Bool)
    case copied
    case historyOnly
    case pasteUnavailable(copiedToClipboard: Bool, reason: TextDeliveryFallbackReason)
}

@MainActor
struct TextInsertionService {
    var isAccessibilityTrusted: Bool {
        #if APP_STORE
        false
        #else
        AXIsProcessTrusted()
        #endif
    }

    func requestAccessibilityPermission() {
        #if !APP_STORE
        // The imported SDK constant is mutable global state and therefore rejected by
        // Swift 6 strict concurrency. Its documented CFString value is stable.
        let options = ["AXTrustedCheckOptionPrompt": true]
        AXIsProcessTrustedWithOptions(options as CFDictionary)
        #endif
    }

    func openAccessibilitySettings() {
        #if !APP_STORE
        guard let url = URL(
            string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        ) else { return }
        NSWorkspace.shared.open(url)
        #endif
    }

    func deliver(
        _ text: String,
        to targetApplication: NSRunningApplication?,
        pasteAutomatically: Bool,
        copyToClipboard: Bool
    ) async -> TextDeliveryResult {
        #if APP_STORE
        if copyToClipboard {
            writeToClipboard(text)
            return .copied
        }
        return .historyOnly
        #else
        guard pasteAutomatically else {
            if copyToClipboard {
                writeToClipboard(text)
                return .copied
            }
            return .historyOnly
        }
        guard isAccessibilityTrusted else {
            if copyToClipboard {
                writeToClipboard(text)
            }
            return .pasteUnavailable(
                copiedToClipboard: copyToClipboard,
                reason: .accessibilityIsMissing
            )
        }
        guard let targetApplication, !targetApplication.isTerminated else {
            if copyToClipboard {
                writeToClipboard(text)
            }
            return .pasteUnavailable(
                copiedToClipboard: copyToClipboard,
                reason: .targetIsUnavailable
            )
        }

        let clipboardSnapshot = copyToClipboard ? nil : PasteboardSnapshot(pasteboard: .general)
        writeToClipboard(text)

        targetApplication.activate(options: [])
        try? await Task.sleep(for: .milliseconds(120))

        guard let source = CGEventSource(stateID: .combinedSessionState),
              let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: false) else {
            clipboardSnapshot?.restore(to: .general, ifCurrentTextIs: text)
            return .pasteUnavailable(
                copiedToClipboard: copyToClipboard,
                reason: .pasteEventCouldNotBeCreated
            )
        }

        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)

        if let clipboardSnapshot {
            try? await Task.sleep(for: .milliseconds(250))
            clipboardSnapshot.restore(to: .general, ifCurrentTextIs: text)
        }
        return .pasted(copiedToClipboard: copyToClipboard)
        #endif
    }

    private func writeToClipboard(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
}

#if !APP_STORE
private struct PasteboardSnapshot {
    private let items: [[NSPasteboard.PasteboardType: Data]]

    init(pasteboard: NSPasteboard) {
        items = pasteboard.pasteboardItems?.map { item in
            Dictionary(uniqueKeysWithValues: item.types.compactMap { type in
                item.data(forType: type).map { (type, $0) }
            })
        } ?? []
    }

    func restore(to pasteboard: NSPasteboard, ifCurrentTextIs expectedText: String) {
        guard pasteboard.string(forType: .string) == expectedText else {
            return
        }

        pasteboard.clearContents()
        let restoredItems = items.map { storedItem in
            let item = NSPasteboardItem()
            for (type, data) in storedItem {
                item.setData(data, forType: type)
            }
            return item
        }
        if !restoredItems.isEmpty {
            pasteboard.writeObjects(restoredItems)
        }
    }
}
#endif
