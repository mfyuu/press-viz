import Carbon
import Foundation

/// グローバルショートカットを管理
@MainActor
final class GlobalShortcutManager {
    // MARK: - Singleton

    static let shared = GlobalShortcutManager()

    // MARK: - Properties

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    /// グローバルショートカットを登録
    func register() {
        unregister()

        let shortcut = AppSettings.shared.globalShortcut
        guard shortcut.isSet else { return }

        // ホットキーIDを作成
        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = OSType(0x5056_495A) // "PVIZ"
        hotKeyID.id = 1

        // イベントハンドラをインストール
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        let handlerResult = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, _ -> OSStatus in
                Task { @MainActor in
                    AppSettings.shared.toggleEnabled()
                }
                return noErr
            },
            1,
            &eventType,
            nil,
            &eventHandler
        )

        guard handlerResult == noErr else {
            print("Failed to install event handler: \(handlerResult)")
            return
        }

        // ホットキーを登録
        let registerResult = RegisterEventHotKey(
            shortcut.keyCode,
            shortcut.modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        if registerResult != noErr {
            print("Failed to register hotkey: \(registerResult)")
        }
    }

    /// グローバルショートカットを解除
    func unregister() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }

        if let handler = eventHandler {
            RemoveEventHandler(handler)
            eventHandler = nil
        }
    }

    /// ショートカットを更新
    func updateShortcut(_ shortcut: GlobalShortcut) {
        AppSettings.shared.globalShortcut = shortcut
        register()
    }
}
