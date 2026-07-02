import AppKit
import SwiftUI

@MainActor
final class SettingsWindowController: NSWindowController {
    init(preferences: PreferencesStore, readwiseAPI: ReadwiseAPI) {
        let settingsView = SettingsView(preferences: preferences, readwiseAPI: readwiseAPI)
        let hostingController = NSHostingController(rootView: settingsView)
        let window = NSWindow(contentViewController: hostingController)
        window.title = "Clipboard to Readwise Settings"
        window.setContentSize(NSSize(width: 520, height: 360))
        window.minSize = NSSize(width: 480, height: 320)
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.isReleasedWhenClosed = false
        window.center()

        super.init(window: window)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        window?.makeKeyAndOrderFront(sender)
    }
}
