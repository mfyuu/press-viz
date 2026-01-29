import Cocoa
import SwiftUI

/// キー表示の状態を管理
@Observable
@MainActor
final class KeyOverlayState {
    var keyText: String = ""
    var isVisible: Bool = false
    var position: DisplayPosition = .bottomCenter
    /// アニメーショントリガー（キーが押されるたびにインクリメント）
    var pressCount: Int = 0
}

/// クリックエフェクトの状態を管理
@Observable
@MainActor
final class ClickEffectState {
    var clicks: [ClickEffectItem] = []
    /// 現在ドラッグ中のクリックID
    var draggingClickId: UUID?
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

        // 同じキーの連打時のみアニメーションをトリガー
        let isSameKey = keyState.keyText == displayText
        keyState.keyText = displayText
        keyState.position = AppSettings.shared.displayPosition
        keyState.isVisible = true
        if isSameKey {
            keyState.pressCount += 1
        }
        keyDisplayTimestamp = Date()
    }

    func clearKeyDisplay() {
        keyState.isVisible = false
        keyState.keyText = ""
    }

    func handleClickEvent(at location: CGPoint, isRelease: Bool) {
        guard AppSettings.shared.showClickEffect else {
            return
        }

        // マウスアップ時：ドラッグ中のクリックを終了
        if isRelease {
            if let draggingId = clickState.draggingClickId,
               let index = clickState.clicks.firstIndex(where: { $0.id == draggingId }) {
                clickState.clicks[index].isDragging = false
                clickState.draggingClickId = nil
            }
            return
        }

        // マウスダウン時：新しいクリックを追加
        // CGEvent座標系からCocoa（NSScreen）座標系に変換
        // CGEvent: メインディスプレイ左上が原点、Y軸下向き正
        // Cocoa: メインディスプレイ左下が原点、Y軸上向き正
        guard let mainScreen = NSScreen.screens.first else {
            return
        }
        let cocoaY = mainScreen.frame.height - location.y
        let cocoaLocation = NSPoint(x: location.x, y: cocoaY)

        // クリック位置のスクリーンを取得
        guard let screen = findScreen(containing: cocoaLocation) else {
            return
        }

        // ウィンドウをそのスクリーンに移動
        moveWindowToScreen(clickWindow, screen: screen)

        // スクリーンローカル座標へ変換（SwiftUI用：左上原点、Y軸下向き正）
        let screenLocalX = cocoaLocation.x - screen.frame.origin.x
        let screenLocalY = screen.frame.height - (cocoaLocation.y - screen.frame.origin.y)

        let clickItem = ClickEffectItem(
            location: CGPoint(x: screenLocalX, y: screenLocalY),
            isDragging: true
        )

        clickState.clicks.append(clickItem)
        clickState.draggingClickId = clickItem.id
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

        // クリックエフェクトのクリーンアップ（ドラッグ中は除外）
        let clickExpiredThreshold: TimeInterval = 0.5
        clickState.clicks.removeAll { !$0.isDragging && now.timeIntervalSince($0.timestamp) > clickExpiredThreshold }

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

    func updateDragPosition(at location: CGPoint) {
        guard let draggingId = clickState.draggingClickId,
              let index = clickState.clicks.firstIndex(where: { $0.id == draggingId }) else {
            return
        }

        // CGEvent座標系からCocoa座標系に変換
        guard let mainScreen = NSScreen.screens.first else { return }
        let cocoaY = mainScreen.frame.height - location.y
        let cocoaLocation = NSPoint(x: location.x, y: cocoaY)

        // スクリーンを取得
        guard let screen = findScreen(containing: cocoaLocation) else { return }

        // ウィンドウをそのスクリーンに移動
        moveWindowToScreen(clickWindow, screen: screen)

        // スクリーンローカル座標へ変換
        let screenLocalX = cocoaLocation.x - screen.frame.origin.x
        let screenLocalY = screen.frame.height - (cocoaLocation.y - screen.frame.origin.y)

        clickState.clicks[index].location = CGPoint(x: screenLocalX, y: screenLocalY)
    }
}

// MARK: - SwiftUI Views with State

struct KeyOverlayViewWithState: View {
    @Bindable var state: KeyOverlayState
    let screenFrame: CGRect
    @State private var scale: CGFloat = 1.0

    var body: some View {
        GeometryReader { geometry in
            if state.isVisible && !state.keyText.isEmpty {
                HStack(spacing: 0) {
                    ForEach(Array(state.keyText.enumerated()), id: \.offset) { _, char in
                        Text(String(char))
                            .baselineOffset(baselineOffset(for: char))
                    }
                }
                .font(.system(size: 32, weight: .medium, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.black.opacity(0.75))
                        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 4)
                }
                .scaleEffect(scale)
                .position(calculatePosition(in: geometry.size))
                .onChange(of: state.pressCount) {
                    // パルスアニメーション
                    withAnimation(.easeOut(duration: 0.08)) {
                        scale = 1.15
                    }
                    withAnimation(.easeInOut(duration: 0.12).delay(0.08)) {
                        scale = 1.0
                    }
                }
            }
        }
        .ignoresSafeArea()
    }

    /// 文字に応じたbaselineOffsetを返す
    private func baselineOffset(for char: Character) -> CGFloat {
        // Enterキー（↩）は他より下に
        if char == "↩" {
            return -5
        }
        // 下に移動が必要な記号（矢印・特殊キー記号）
        let needsDownward: Set<Character> = ["↑", "↓", "←", "→", "⇥", "⌫", "⌦", "⎋"]
        // 修飾キー記号
        let modifierSymbols: Set<Character> = ["⌃", "⌥", "⇧", "⌘", "⇪", "🌐"]

        if needsDownward.contains(char) {
            return -3  // 下に移動
        } else if modifierSymbols.contains(char) {
            return -2  // やや下に移動
        } else if char.isLowercase {
            return 2  // 小文字は上に移動（esc用）
        }
        // 通常の文字はオフセットなし
        return 0
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
                ClickEffectView(location: click.location, isDragging: click.isDragging)
            }
        }
        .ignoresSafeArea()
    }
}
