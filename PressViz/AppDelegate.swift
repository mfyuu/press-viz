import Cocoa
import SwiftUI

/// アプリケーションデリゲート
final class AppDelegate: NSObject, NSApplicationDelegate {
    // MARK: - Singleton

    static var shared: AppDelegate?

    // MARK: - Properties

    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var eventMonitor: Any?

    // MARK: - NSApplicationDelegate

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self
        setupStatusItem()
        setupPopover()
        setupEventMonitor()

        // アクセシビリティ権限の確認
        let permissionManager = AccessibilityPermissionManager.shared
        permissionManager.checkAccessibility()

        // 権限があれば監視を開始
        if permissionManager.isAccessibilityEnabled {
            AppSettings.shared.hasCompletedOnboarding = true
            startVisualization()
        } else {
            // 権限がない場合は監視を開始して、付与されたら自動で開始
            permissionManager.startMonitoring()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        stopVisualization()
        GlobalShortcutManager.shared.unregister()
    }

    // MARK: - Private Methods

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            button.image = NSImage(named: "MenuBarIcon")
            button.action = #selector(togglePopover)
            button.target = self
        }
    }

    private func setupPopover() {
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 320, height: 400)
        popover?.behavior = .transient
        popover?.animates = true
        popover?.contentViewController = NSHostingController(rootView: MenuPopoverView())
    }

    private func setupEventMonitor() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            if self?.popover?.isShown == true {
                self?.closePopover()
            }
        }
    }

    @objc private func togglePopover() {
        if let popover, popover.isShown {
            closePopover()
        } else {
            showPopover()
        }
    }

    private func showPopover() {
        guard let button = statusItem?.button else { return }
        popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func closePopover() {
        popover?.performClose(nil)
    }

    // MARK: - Visualization Control

    func startVisualization() {
        let overlayManager = OverlayWindowManager.shared
        let inputMonitor = InputEventMonitor.shared
        let shortcutManager = GlobalShortcutManager.shared

        overlayManager.setup()
        inputMonitor.startMonitoring()
        shortcutManager.register()
        startEventObservation()
    }

    func stopVisualization() {
        let overlayManager = OverlayWindowManager.shared
        let inputMonitor = InputEventMonitor.shared

        overlayManager.teardown()
        inputMonitor.stopMonitoring()
    }

    private func startEventObservation() {
        // イベント監視のセットアップ（Combineや他の仕組みで実装可能）
        // ここではシンプルにタイマーベースで監視
        Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor [weak self] in
                self?.processEvents()
            }
        }
    }

    private func processEvents() {
        let inputMonitor = InputEventMonitor.shared
        let overlayManager = OverlayWindowManager.shared
        let settings = AppSettings.shared

        guard settings.isEnabled else {
            overlayManager.clearKeyDisplay()
            return
        }

        // キーイベントの処理
        if let keyEvent = inputMonitor.currentKeyEvent {
            overlayManager.showKeyEvent(keyEvent)
            inputMonitor.clearKeyEvent()
        }

        // クリックイベントの処理
        if let clickEvent = inputMonitor.currentClickEvent {
            overlayManager.handleClickEvent(at: clickEvent.location, isRelease: clickEvent.isRelease)
            inputMonitor.clearClickEvent()
        }

        // ドラッグイベントの処理
        if let dragLocation = inputMonitor.currentDragLocation {
            overlayManager.updateDragPosition(at: dragLocation)
            inputMonitor.clearDragLocation()
        }
    }
}
