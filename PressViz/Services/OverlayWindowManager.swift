import Cocoa
import SwiftUI

/// キー表示の状態を管理
@Observable
@MainActor
final class KeyOverlayState {
    var keyText: String = ""
    var isVisible: Bool = false
    var position: DisplayPosition = .bottomCenter
}

/// クリックエフェクトの状態を管理
@Observable
@MainActor
final class ClickEffectState {
    var clicks: [ClickEffectItem] = []
}

/// オーバーレイウィンドウを管理
@MainActor
final class OverlayWindowManager {
    // MARK: - Singleton

    static let shared = OverlayWindowManager()

    // MARK: - Properties

    private var keyWindow: NSWindow?
    private var clickWindow: NSWindow?
    private let keyState = KeyOverlayState()
    private let clickState = ClickEffectState()
    private var cleanupTimer: Timer?
    private var keyDisplayTimestamp: Date?
    private let keyDisplayDuration: TimeInterval = 1.0 // 1秒後に消える

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    func setup() {
        guard let screen = NSScreen.main else { return }

        // キー表示ウィンドウ
        keyWindow = createOverlayWindow(for: screen)
        let keyView = KeyOverlayViewWithState(state: keyState, screenFrame: screen.frame)
        keyWindow?.contentView = NSHostingView(rootView: keyView)

        // クリックエフェクトウィンドウ
        clickWindow = createOverlayWindow(for: screen)
        let clickView = ClickEffectContainerWithState(state: clickState)
        clickWindow?.contentView = NSHostingView(rootView: clickView)

        startCleanupTimer()
    }

    func teardown() {
        stopCleanupTimer()
        keyWindow?.close()
        keyWindow = nil
        clickWindow?.close()
        clickWindow = nil
    }

    func showKeyEvent(_ keyEvent: KeyEvent) {
        let displayText = keyEvent.displayString

        // 制御文字を除去して、表示可能な文字のみをチェック
        let printableText = displayText.unicodeScalars.filter { !CharacterSet.controlCharacters.contains($0) }
        guard !printableText.isEmpty else {
            return
        }

        // カーソル位置のスクリーンにウィンドウを移動
        let cursorLocation = NSEvent.mouseLocation
        if let screen = findScreen(containing: cursorLocation) {
            moveWindowToScreen(keyWindow, screen: screen)
        }

        keyState.keyText = displayText
        keyState.position = AppSettings.shared.displayPosition
        keyState.isVisible = true
        keyDisplayTimestamp = Date()
    }

    func clearKeyDisplay() {
        keyState.isVisible = false
        keyState.keyText = ""
    }

    func showClickEffect(at location: CGPoint) {
        guard AppSettings.shared.showClickEffect else {
            return
        }

        // クリック位置のスクリーンを取得
        guard let screen = findScreen(containing: NSPoint(x: location.x, y: location.y)) else {
            return
        }

        // ウィンドウをそのスクリーンに移動
        moveWindowToScreen(clickWindow, screen: screen)

        // 座標変換（スクリーンローカル座標へ）
        let screenLocalX = location.x - screen.frame.origin.x
        let screenLocalY = screen.frame.height - (location.y - screen.frame.origin.y)

        let clickItem = ClickEffectItem(
            location: CGPoint(x: screenLocalX, y: screenLocalY),
            timestamp: Date()
        )

        clickState.clicks.append(clickItem)
    }

    // MARK: - Private Methods

    private func createOverlayWindow(for screen: NSScreen) -> NSWindow {
        let window = NSWindow(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )

        window.level = .screenSaver
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        window.setFrame(screen.frame, display: true)
        window.orderFront(nil)

        return window
    }

    private func startCleanupTimer() {
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.cleanupExpiredClicks()
            }
        }
    }

    private func stopCleanupTimer() {
        cleanupTimer?.invalidate()
        cleanupTimer = nil
    }

    private func cleanupExpiredClicks() {
        let now = Date()

        // クリックエフェクトのクリーンアップ
        let clickExpiredThreshold: TimeInterval = 0.5
        clickState.clicks.removeAll { now.timeIntervalSince($0.timestamp) > clickExpiredThreshold }

        // キー表示のクリーンアップ（一定時間後に消える）
        // ただし、キーが押されている間はスキップ
        if InputEventMonitor.shared.isPressing {
            // キーが押されている間はタイムスタンプを更新して表示を維持
            keyDisplayTimestamp = now
            return
        }

        if let timestamp = keyDisplayTimestamp,
           now.timeIntervalSince(timestamp) > keyDisplayDuration {
            clearKeyDisplay()
            keyDisplayTimestamp = nil
        }
    }

    private func findScreen(containing point: NSPoint) -> NSScreen? {
        NSScreen.screens.first { NSPointInRect(point, $0.frame) } ?? NSScreen.main
    }

    private func moveWindowToScreen(_ window: NSWindow?, screen: NSScreen) {
        guard let window else { return }
        if window.frame != screen.frame {
            window.setFrame(screen.frame, display: true)
        }
    }
}

// MARK: - SwiftUI Views with State

struct KeyOverlayViewWithState: View {
    @Bindable var state: KeyOverlayState
    let screenFrame: CGRect

    var body: some View {
        GeometryReader { geometry in
            if state.isVisible && !state.keyText.isEmpty {
                Text(state.keyText)
                    .font(.system(size: 32, weight: .medium, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(.black.opacity(0.75))
                            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 4)
                    }
                    .position(calculatePosition(in: geometry.size))
            }
        }
        .ignoresSafeArea()
    }

    private func calculatePosition(in size: CGSize) -> CGPoint {
        let padding: CGFloat = 40

        let x: CGFloat
        let y: CGFloat

        switch state.position.gridPosition.column {
        case 0: x = padding + 100
        case 1: x = size.width / 2
        case 2: x = size.width - padding - 100
        default: x = size.width / 2
        }

        switch state.position.gridPosition.row {
        case 0: y = padding + 30
        case 1: y = size.height / 2
        case 2: y = size.height - padding - 30
        default: y = size.height / 2
        }

        return CGPoint(x: x, y: y)
    }
}

struct ClickEffectContainerWithState: View {
    @Bindable var state: ClickEffectState

    var body: some View {
        ZStack {
            ForEach(state.clicks) { click in
                ClickEffectView(location: click.location)
            }
        }
        .ignoresSafeArea()
    }
}
