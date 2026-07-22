import AppKit
import Carbon.HIToolbox
import SwiftUI

@main
struct VorbApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @AppStorage("showMenuBarIcon") private var showMenuBarIcon = true

    var body: some Scene {
        MenuBarExtra(isInserted: $showMenuBarIcon) {
            MenuBarContent(
                model: appDelegate.model,
                showMenuBarIcon: $showMenuBarIcon
            )
        } label: {
            Label("Vorb", systemImage: appDelegate.model.menuBarIcon)
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView(model: appDelegate.model)
                .frame(width: 600, height: 520)
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let model = AppModel()

    private var hotKey: GlobalHotKey?
    private var overlayController: OverlayPanelController?
    private var settingsWindowController: NSWindowController?
    private var historyWindowController: NSWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let overlayController = OverlayPanelController(model: model)
        self.overlayController = overlayController
        model.onOverlayVisibilityChanged = { [weak overlayController] isVisible in
            if isVisible {
                overlayController?.show()
            } else {
                overlayController?.hide()
            }
        }

        let settingsRootView = SettingsView(model: model)
            .frame(width: 600, height: 520)
        let settingsHostingController = NSHostingController(rootView: settingsRootView)
        let settingsWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 520),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        settingsWindow.title = localized("Vorb Settings")
        settingsWindow.contentViewController = settingsHostingController
        settingsWindow.setContentSize(NSSize(width: 600, height: 520))
        settingsWindow.contentMinSize = NSSize(width: 600, height: 520)
        settingsWindow.isReleasedWhenClosed = false
        settingsWindow.collectionBehavior = [.moveToActiveSpace]
        settingsWindow.center()
        settingsWindowController = NSWindowController(window: settingsWindow)

        let historyRootView = HistoryView(model: model)
            .frame(width: 660, height: 540)
        let historyHostingController = NSHostingController(rootView: historyRootView)
        let historyWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 660, height: 540),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        historyWindow.title = localized("Vorb History")
        historyWindow.contentViewController = historyHostingController
        historyWindow.contentMinSize = NSSize(width: 620, height: 500)
        historyWindow.isReleasedWhenClosed = false
        historyWindow.collectionBehavior = [.moveToActiveSpace]
        historyWindow.center()
        historyWindowController = NSWindowController(window: historyWindow)

        model.onShowSettings = { [weak self] in
            self?.showSettingsWindow()
        }
        model.onShowHistory = { [weak self] in
            self?.showHistoryWindow()
        }

        model.onShortcutChanged = { [weak self] shortcut in
            self?.registerHotKey(shortcut) ?? false
        }
        if !registerHotKey(model.shortcut) {
            model.reportHotKeyRegistrationFailure()
        }

        if model.selectedProvider.requiresAPIKey && model.apiKey.isEmpty {
            Task { @MainActor [weak self] in
                try? await Task.sleep(for: .milliseconds(250))
                self?.showSettingsWindow()
            }
        }
    }

    func applicationShouldHandleReopen(
        _ sender: NSApplication,
        hasVisibleWindows flag: Bool
    ) -> Bool {
        showSettingsWindow()
        return true
    }

    private func showSettingsWindow() {
        NSApp.activate()
        settingsWindowController?.showWindow(nil)
        guard let window = settingsWindowController?.window else { return }
        window.makeKeyAndOrderFront(nil)
        DispatchQueue.main.async { [weak window] in
            window?.makeFirstResponder(nil)
        }
    }

    private func showHistoryWindow() {
        NSApp.activate()
        historyWindowController?.showWindow(nil)
        historyWindowController?.window?.makeKeyAndOrderFront(nil)
    }

    private func registerHotKey(_ shortcut: GlobalShortcut) -> Bool {
        guard let newHotKey = GlobalHotKey(shortcut: shortcut, action: { [weak model] isPressed in
            Task { @MainActor in
                model?.handleShortcut(isPressed: isPressed)
            }
        }) else {
            return false
        }
        hotKey = newHotKey
        return true
    }
}

private struct MenuBarContent: View {
    @ObservedObject var model: AppModel
    @Binding var showMenuBarIcon: Bool

    var body: some View {
        Button(model.primaryActionTitle) {
            model.toggleDictation()
        }
        .disabled(model.phase == .transcribing)

        if let lastTranscript = model.lastTranscript, !lastTranscript.isEmpty {
            Button("Copy Last Transcript") {
                model.copyTranscript(lastTranscript)
            }
        }

        Button("History…") {
            model.showHistory()
        }

        Divider()

        Button("Settings…") {
            model.showSettings()
        }

        Menu("Help & Community") {
            Link("Star on GitHub", destination: AppLinks.github)
            Link("Privacy Policy", destination: AppLinks.privacy)
            Link("Support", destination: AppLinks.support)
            Link("Email Support", destination: AppLinks.supportEmailURL)
        }

        Button("Hide Menu Bar Icon") {
            showMenuBarIcon = false
        }

        Divider()

        Button("Quit Vorb") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
