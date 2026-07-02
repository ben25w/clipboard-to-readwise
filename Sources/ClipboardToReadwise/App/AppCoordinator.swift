import AppKit
import ClipboardToReadwiseCore
import Foundation

@MainActor
final class AppCoordinator: NSObject {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let tokenStore = KeychainTokenStore()
    private lazy var preferences = PreferencesStore(tokenStore: tokenStore)
    private lazy var readwiseAPI = ReadwiseAPI()

    private var settingsWindowController: SettingsWindowController?
    private var animationTimer: Timer?
    private var frameIndex = 0
    private var isSending = false
    private var restoreIdleWorkItem: DispatchWorkItem?

    func start() {
        configureStatusItem()

        if !preferences.hasToken {
            openSettings()
        }
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else { return }
        button.image = Icons.idle
        button.title = "RW"
        button.imagePosition = .imageLeft
        button.font = .systemFont(ofSize: NSFont.systemFontSize, weight: .semibold)
        button.toolTip = "Send clipboard to Readwise"
        button.target = self
        button.action = #selector(handleStatusItemClick(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        statusItem.length = NSStatusItem.variableLength
    }

    @objc private func handleStatusItemClick(_ sender: Any?) {
        guard let event = NSApp.currentEvent else {
            sendClipboardFromMenuBar()
            return
        }

        if event.type == .rightMouseUp {
            showStatusMenu()
        } else {
            sendClipboardFromMenuBar()
        }
    }

    private func showStatusMenu() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(
            title: "Send Clipboard to Readwise",
            action: #selector(sendClipboardMenuItem(_:)),
            keyEquivalent: ""
        ))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettingsMenuItem(_:)), keyEquivalent: ","))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitMenuItem(_:)), keyEquivalent: "q"))

        for item in menu.items {
            item.target = self
        }

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc private func sendClipboardMenuItem(_ sender: Any?) {
        sendClipboardFromMenuBar()
    }

    @objc private func openSettingsMenuItem(_ sender: Any?) {
        openSettings()
    }

    @objc private func quitMenuItem(_ sender: Any?) {
        NSApp.terminate(nil)
    }

    func openSettings() {
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController(preferences: preferences, readwiseAPI: readwiseAPI)
        }
        settingsWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func sendClipboardFromMenuBar() {
        Task {
            do {
                let result = try await sendClipboard()
                showSuccess(result: result)
            } catch {
                showIdle()
                await NotificationService.showFailure(message: ErrorPresenter.message(for: error))
            }
        }
    }

    private func sendClipboard() async throws -> SendResult {
        guard !isSending else {
            throw AppError.alreadySending
        }

        isSending = true
        startSendingAnimation()

        do {
            let clipboardText = NSPasteboard.general.string(forType: .string) ?? ""
            guard !clipboardText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw AppError.emptyClipboard
            }

            guard let token = tokenStore.readToken(), !token.isEmpty else {
                throw AppError.missingToken
            }

            let parsed = ClipboardParser.parse(clipboardText)
            guard !parsed.highlights.isEmpty else {
                throw AppError.emptyClipboard
            }

            let configuration = ReadwiseConfiguration(author: preferences.author, category: preferences.category)
            let payload = ReadwisePayloadBuilder.build(parsed: parsed, configuration: configuration)
            try await readwiseAPI.sendHighlights(payload, token: token)

            isSending = false
            stopSendingAnimation()
            return SendResult(title: parsed.title, highlightCount: parsed.highlights.count)
        } catch {
            isSending = false
            stopSendingAnimation()
            throw error
        }
    }

    private func startSendingAnimation() {
        restoreIdleWorkItem?.cancel()
        restoreIdleWorkItem = nil
        frameIndex = 0
        animationTimer?.invalidate()

        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.18, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.advanceSendingFrame()
            }
        }
        animationTimer?.fire()
    }

    private func advanceSendingFrame() {
        guard let button = statusItem.button else { return }
        button.image = Icons.sending
        button.title = "RW"
        button.contentTintColor = Icons.sendingColors[frameIndex % Icons.sendingColors.count]
        button.toolTip = "Sending clipboard to Readwise..."
        frameIndex += 1
    }

    private func stopSendingAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
    }

    private func showSuccess(result: SendResult) {
        stopSendingAnimation()
        guard let button = statusItem.button else { return }
        button.image = Icons.success
        button.title = "RW"
        button.contentTintColor = .systemGreen
        button.toolTip = "Saved \(result.highlightCount) highlight\(result.highlightCount == 1 ? "" : "s") to Readwise"

        let workItem = DispatchWorkItem { [weak self] in
            self?.showIdle()
        }
        restoreIdleWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4, execute: workItem)
    }

    private func showIdle() {
        stopSendingAnimation()
        guard let button = statusItem.button else { return }
        button.image = Icons.idle
        button.title = "RW"
        button.contentTintColor = nil
        button.toolTip = "Send clipboard to Readwise"
    }
}

private enum Icons {
    static let idle = symbol("highlighter")
    static let sending = symbol("highlighter")
    static let success = symbol("checkmark.circle.fill")
    static let sendingColors: [NSColor] = [.systemBlue, .controlAccentColor, .systemTeal, .controlAccentColor]

    private static func symbol(_ name: String) -> NSImage {
        let image = NSImage(systemSymbolName: name, accessibilityDescription: nil) ?? NSImage()
        image.isTemplate = true
        return image
    }
}

struct SendResult: Equatable {
    let title: String
    let highlightCount: Int
}
