import Carbon.HIToolbox
import Cocoa
import CoreGraphics
import Foundation

/// マウスクリックイベント
struct ClickEvent: Sendable {
    let location: CGPoint
    let screenFrame: CGRect
    let timestamp: Date
    let isRelease: Bool
}

/// 入力イベントを監視
@Observable
@MainActor
final class InputEventMonitor {
    // MARK: - Singleton

    static let shared = InputEventMonitor()

    // MARK: - Properties

    /// 現在のキーイベント
    private(set) var currentKeyEvent: KeyEvent?

    /// 現在のクリックイベント
    private(set) var currentClickEvent: ClickEvent?

    /// 現在のドラッグ位置（CGEvent座標系）
    private(set) var currentDragLocation: CGPoint?

    /// 現在押されているキーコード
    private var pressedKeyCodes: Set<UInt16> = []

    /// 現在押されている修飾キー
    private var pressedModifiers: ModifierFlags = []

    /// キーが押されている状態かどうか
    var isPressing: Bool {
        !pressedKeyCodes.isEmpty || !pressedModifiers.isEmpty
    }

    /// イベントタップ
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    /// 監視中かどうか
    private(set) var isMonitoring: Bool = false

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    /// 監視を開始
    func startMonitoring() {
        guard !isMonitoring else {
            return
        }


        let keyMask: CGEventMask =
            (1 << CGEventType.keyDown.rawValue) |
            (1 << CGEventType.keyUp.rawValue) |
            (1 << CGEventType.flagsChanged.rawValue)

        let mouseDownMask: CGEventMask =
            (1 << CGEventType.leftMouseDown.rawValue) |
            (1 << CGEventType.rightMouseDown.rawValue) |
            (1 << CGEventType.otherMouseDown.rawValue)

        let mouseUpMask: CGEventMask =
            (1 << CGEventType.leftMouseUp.rawValue) |
            (1 << CGEventType.rightMouseUp.rawValue) |
            (1 << CGEventType.otherMouseUp.rawValue)

        let mouseDragMask: CGEventMask =
            (1 << CGEventType.leftMouseDragged.rawValue) |
            (1 << CGEventType.rightMouseDragged.rawValue) |
            (1 << CGEventType.otherMouseDragged.rawValue)

        let eventMask = keyMask | mouseDownMask | mouseUpMask | mouseDragMask

        let callback: CGEventTapCallBack = { _, type, event, userInfo in
            guard let userInfo else { return Unmanaged.passRetained(event) }
            let monitor = Unmanaged<InputEventMonitor>.fromOpaque(userInfo).takeUnretainedValue()
            monitor.handleEvent(event)
            return Unmanaged.passRetained(event)
        }

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: eventMask,
            callback: callback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            return
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)

        if let source = runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
        }

        CGEvent.tapEnable(tap: tap, enable: true)
        isMonitoring = true
    }

    /// 監視を停止
    func stopMonitoring() {
        guard isMonitoring else { return }

        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }

        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
        }

        eventTap = nil
        runLoopSource = nil
        isMonitoring = false
    }

    /// キーイベントをクリア
    func clearKeyEvent() {
        currentKeyEvent = nil
    }

    /// クリックイベントをクリア
    func clearClickEvent() {
        currentClickEvent = nil
    }

    /// ドラッグ位置をクリア
    func clearDragLocation() {
        currentDragLocation = nil
    }

    // MARK: - Internal Methods

    nonisolated func handleEvent(_ event: CGEvent) {
        let eventType = event.type

        Task { @MainActor in
            switch eventType {
            case .keyDown:
                self.handleKeyDown(event)
            case .keyUp:
                self.handleKeyUp(event)
            case .flagsChanged:
                self.handleFlagsChanged(event)
            case .leftMouseDown, .rightMouseDown, .otherMouseDown:
                self.handleMouseEvent(event, isRelease: false)
            case .leftMouseUp, .rightMouseUp, .otherMouseUp:
                self.handleMouseEvent(event, isRelease: true)
            case .leftMouseDragged, .rightMouseDragged, .otherMouseDragged:
                self.handleMouseDrag(event)
            default:
                break
            }
        }
    }

    // MARK: - Private Methods

    private func handleKeyUp(_ event: CGEvent) {
        let keyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
        pressedKeyCodes.remove(keyCode)
    }

    private func handleKeyDown(_ event: CGEvent) {
        let keyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
        let flags = event.flags
        let modifiers = extractModifiers(from: flags)

        // 押されているキーを追跡
        pressedKeyCodes.insert(keyCode)

        var characters: String?
        if let nsEvent = NSEvent(cgEvent: event) {
            characters = nsEvent.charactersIgnoringModifiers?.uppercased()
        }

        let keyEvent = KeyEvent(
            keyCode: keyCode,
            modifiers: modifiers,
            characters: characters,
            timestamp: Date()
        )

        updateKeyEvent(keyEvent)
    }

    private func handleFlagsChanged(_ event: CGEvent) {
        let keyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
        let flags = event.flags
        let newModifiers = extractModifiers(from: flags)

        // 修飾キーが押されたか離されたかを判定
        // wasPressed: 以前このキーが押されていたか
        // isPressed: 今このキーが押されているか
        let modifier = modifierForKeyCode(keyCode)
        let wasPressed = pressedModifiers.contains(modifier)
        let isPressed = newModifiers.contains(modifier)

        // 押されている修飾キーを更新
        pressedModifiers = newModifiers

        // 修飾キーが新しく押されたときのみ表示を更新
        if isPressed && !wasPressed {
            let keyEvent = KeyEvent(
                keyCode: keyCode,
                modifiers: newModifiers,
                characters: nil,
                timestamp: Date()
            )
            updateKeyEvent(keyEvent)
        }
        // 修飾キーがすべて離されても表示は消さない（タイマーで消える）
    }

    /// キーコードから対応する修飾フラグを取得
    private func modifierForKeyCode(_ keyCode: UInt16) -> ModifierFlags {
        switch Int(keyCode) {
        case kVK_Shift, kVK_RightShift:
            return ModifierFlags.shift
        case kVK_Control, kVK_RightControl:
            return ModifierFlags.control
        case kVK_Option, kVK_RightOption:
            return ModifierFlags.option
        case kVK_Command, kVK_RightCommand:
            return ModifierFlags.command
        case kVK_CapsLock:
            return ModifierFlags.capsLock
        case kVK_Function:
            return ModifierFlags.function
        default:
            return ModifierFlags()
        }
    }

    private func handleMouseEvent(_ event: CGEvent, isRelease: Bool) {
        let location = event.location

        // カーソルがあるスクリーンを取得
        let screenFrame = NSScreen.screens
            .first { NSPointInRect(NSPoint(x: location.x, y: location.y), $0.frame) }?
            .frame ?? NSScreen.main?.frame ?? .zero

        let clickEvent = ClickEvent(
            location: location,
            screenFrame: screenFrame,
            timestamp: Date(),
            isRelease: isRelease
        )

        currentClickEvent = clickEvent

        // マウスアップ時はドラッグ位置をクリア
        if isRelease {
            currentDragLocation = nil
        }
    }

    private func handleMouseDrag(_ event: CGEvent) {
        currentDragLocation = event.location
    }

    private func updateKeyEvent(_ keyEvent: KeyEvent) {
        // 空の表示文字列は無視
        guard !keyEvent.displayString.isEmpty else { return }

        let settings = AppSettings.shared
        let mode = settings.keyDisplayMode

        switch mode {
        case .allKeys:
            currentKeyEvent = keyEvent
        case .modifierOnly:
            if keyEvent.isModifierOnly {
                currentKeyEvent = keyEvent
            }
        case .modifierPlusKey:
            if keyEvent.hasModifiers || keyEvent.isModifierOnly {
                currentKeyEvent = keyEvent
            }
        }
    }

    private func extractModifiers(from flags: CGEventFlags) -> ModifierFlags {
        var modifiers = ModifierFlags()

        if flags.contains(.maskShift) {
            modifiers.insert(.shift)
        }
        if flags.contains(.maskControl) {
            modifiers.insert(.control)
        }
        if flags.contains(.maskAlternate) {
            modifiers.insert(.option)
        }
        if flags.contains(.maskCommand) {
            modifiers.insert(.command)
        }
        if flags.contains(.maskAlphaShift) {
            modifiers.insert(.capsLock)
        }
        if flags.contains(.maskSecondaryFn) {
            modifiers.insert(.function)
        }

        return modifiers
    }
}

