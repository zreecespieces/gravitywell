import AppKit
import Observation
import SwiftUI

@MainActor
final class StatusBarController: NSObject, NSPopoverDelegate, NSWindowDelegate {
    private let appState: AppState
    private let statusItem: NSStatusItem
    private let popover = NSPopover()
    private var settingsWindow: NSWindow?
    private var localEventMonitor: Any?
    private var globalEventMonitor: Any?
    private var lastPopoverCloseDate: Date?

    init(appState: AppState) {
        self.appState = appState
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        super.init()

        configureStatusItem()
        configurePopover()
        observeAppState()
        updateStatusItem()
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else { return }

        button.target = self
        button.action = #selector(togglePopover(_:))
        button.imagePosition = .imageLeft
    }

    private func configurePopover() {
        popover.behavior = .transient
        popover.delegate = self
        popover.contentViewController = NSHostingController(
            rootView: DashboardPopoverView(openSettingsAction: { [weak self] in
                self?.openSettingsFromPopover()
            })
            .environment(appState)
        )
    }

    private func observeAppState() {
        withObservationTracking {
            _ = appState.isConfigured
            _ = appState.menuBarDisplayMode
            _ = appState.snapshot
            _ = appState.errorMessage
            _ = appState.displayStatus
            _ = appState.blockingDisabledUntil
        } onChange: { [weak self] in
            Task { @MainActor in
                self?.updateStatusItem()
                self?.observeAppState()
            }
        }
    }

    private func updateStatusItem() {
        guard let button = statusItem.button else { return }

        let image = Self.statusBarImage()
        image?.size = NSSize(width: 18, height: 18)
        image?.isTemplate = true

        button.image = image
        button.title = ""
        button.attributedTitle = appState.menuBarDisplayMode == .iconOnly ? NSAttributedString() : NSAttributedString(
            string: " \(appState.menuBarStatusText())",
            attributes: [
                .font: NSFont.systemFont(ofSize: 12, weight: .regular),
                .foregroundColor: NSColor.labelColor
            ]
        )
    }

    private static func statusBarImage() -> NSImage? {
        if let image = NSImage(named: "AppIcon")?.copy() as? NSImage {
            return image
        }

        if let url = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
           let image = NSImage(contentsOf: url) {
            return image
        }

        if let url = Bundle.main.url(forResource: "AppIcon1024-White", withExtension: "png"),
           let image = NSImage(contentsOf: url) {
            return image
        }

        Logger.app.warning("GravityWell status bar icon resource was not found")
        return nil
    }

    @objc private func togglePopover(_ sender: Any?) {
        if let lastPopoverCloseDate, Date().timeIntervalSince(lastPopoverCloseDate) < 0.25 {
            return
        }

        if popover.isShown {
            closePopover()
        } else {
            showPopover()
        }
    }

    private func showPopover() {
        guard let button = statusItem.button else { return }

        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        startEventMonitoring()
    }

    private func closePopover() {
        lastPopoverCloseDate = Date()
        popover.performClose(nil)
        stopEventMonitoring()
    }

    func popoverDidClose(_ notification: Notification) {
        lastPopoverCloseDate = Date()
        stopEventMonitoring()
    }

    private func openSettingsFromPopover() {
        closePopover()
        showSettingsWindow()
    }

    private func showSettingsWindow() {
        if let settingsWindow {
            NSApp.activate(ignoringOtherApps: true)
            settingsWindow.makeKeyAndOrderFront(nil)
            return
        }

        let hostingView = NSHostingView(
            rootView: SettingsView()
                .environment(appState)
        )

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 520),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "GravityWell Settings"
        window.contentView = hostingView
        window.delegate = self
        window.isReleasedWhenClosed = false
        window.center()

        settingsWindow = window
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    func windowWillClose(_ notification: Notification) {
        guard notification.object as? NSWindow === settingsWindow else { return }

        settingsWindow = nil
    }

    private func startEventMonitoring() {
        stopEventMonitoring()

        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]) { [weak self] event in
            guard let self, self.popover.isShown else { return event }

            let popoverWindow = self.popover.contentViewController?.view.window
            if event.window !== popoverWindow {
                self.closePopover()
            }

            return event
        }

        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.popover.isShown else { return }
                self.closePopover()
            }
        }
    }

    private func stopEventMonitoring() {
        if let localEventMonitor {
            NSEvent.removeMonitor(localEventMonitor)
            self.localEventMonitor = nil
        }

        if let globalEventMonitor {
            NSEvent.removeMonitor(globalEventMonitor)
            self.globalEventMonitor = nil
        }
    }
}
