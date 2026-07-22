import AppKit
import SwiftUI

@MainActor
final class OverlayPanelController {
    private let panel: NSPanel

    init(model: AppModel) {
        let initialSize = Self.panelSize(for: model.overlayStyle)
        panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: initialSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: true
        )
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        // The panel itself is rectangular even though the visible overlay is circular.
        // SwiftUI draws the shaped shadow, so an AppKit window shadow would reveal the
        // panel bounds as a faint square.
        panel.hasShadow = false
        panel.hidesOnDeactivate = false
        panel.isMovableByWindowBackground = false
        panel.contentView = NSHostingView(rootView: DictationOverlayView(model: model))

        model.onOverlayStyleChanged = { [weak self] style in
            self?.resizePanel(for: style)
        }
    }

    func show() {
        positionPanel()
        panel.orderFrontRegardless()
    }

    func hide() {
        panel.orderOut(nil)
    }

    private func positionPanel() {
        let screen = NSScreen.main ?? NSScreen.screens.first
        guard let visibleFrame = screen?.visibleFrame else { return }

        let x = visibleFrame.midX - panel.frame.width / 2
        let y = visibleFrame.minY + 44
        panel.setFrameOrigin(NSPoint(x: x.rounded(), y: y.rounded()))
    }

    private func resizePanel(for style: OverlayStyle) {
        panel.setContentSize(Self.panelSize(for: style))
        if panel.isVisible {
            positionPanel()
        }
    }

    private static func panelSize(for style: OverlayStyle) -> NSSize {
        switch style {
        case .orbOnly:
            NSSize(width: 76, height: 76)
        case .detailed:
            NSSize(width: 292, height: 92)
        }
    }
}
