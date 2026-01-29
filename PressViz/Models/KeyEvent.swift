import Carbon.HIToolbox
import Foundation

/// 修飾キーのフラグ
struct ModifierFlags: OptionSet, Sendable {
    let rawValue: UInt

    static let shift = ModifierFlags(rawValue: 1 << 0)
    static let control = ModifierFlags(rawValue: 1 << 1)
    static let option = ModifierFlags(rawValue: 1 << 2)
    static let command = ModifierFlags(rawValue: 1 << 3)
    static let capsLock = ModifierFlags(rawValue: 1 << 4)
    static let function = ModifierFlags(rawValue: 1 << 5)

    var symbols: [String] {
        var result: [String] = []
        if contains(.control) { result.append("⌃") }
        if contains(.option) { result.append("⌥") }
        if contains(.shift) { result.append("⇧") }
        if contains(.command) { result.append("⌘") }
        if contains(.capsLock) { result.append("⇪") }
        if contains(.function) { result.append("fn") }
        return result
    }

    var isEmpty: Bool {
        rawValue == 0
    }
}

/// キーイベントの情報
struct KeyEvent: Sendable, Equatable {
    let keyCode: UInt16
    let modifiers: ModifierFlags
    let characters: String?
    let timestamp: Date

    /// キーの表示文字列を取得
    var displayString: String {
        let modifierString = modifiers.symbols.joined()

        // 特殊キーの記号を優先、なければcharactersを使用
        let specialKeyString = keyCodeToString(keyCode)
        let keyString = specialKeyString.isEmpty ? (characters ?? "") : specialKeyString

        if modifiers.isEmpty {
            return keyString.isEmpty ? "" : keyString
        } else if keyString.isEmpty {
            return modifierString
        } else {
            return modifierString + keyString
        }
    }

    /// 修飾キーのみかどうか
    var isModifierOnly: Bool {
        let modifierKeyCodes: Set<UInt16> = [
            UInt16(kVK_Shift), UInt16(kVK_RightShift),
            UInt16(kVK_Control), UInt16(kVK_RightControl),
            UInt16(kVK_Option), UInt16(kVK_RightOption),
            UInt16(kVK_Command), UInt16(kVK_RightCommand),
            UInt16(kVK_CapsLock), UInt16(kVK_Function)
        ]
        return modifierKeyCodes.contains(keyCode)
    }

    /// 修飾キーを含むかどうか
    var hasModifiers: Bool {
        !modifiers.isEmpty
    }
}

/// キーコードを表示文字列に変換
private func keyCodeToString(_ keyCode: UInt16) -> String {
    switch Int(keyCode) {
    // 特殊キー
    case kVK_Return: return "↩"
    case kVK_Tab: return "⇥"
    case kVK_Space: return "␣"
    case kVK_Delete: return "⌫"
    case kVK_Escape: return "⎋"
    case kVK_ForwardDelete: return "⌦"
    case kVK_Home: return "↖"
    case kVK_End: return "↘"
    case kVK_PageUp: return "⇞"
    case kVK_PageDown: return "⇟"
    case kVK_UpArrow: return "↑"
    case kVK_DownArrow: return "↓"
    case kVK_LeftArrow: return "←"
    case kVK_RightArrow: return "→"
    // ファンクションキー
    case kVK_F1: return "F1"
    case kVK_F2: return "F2"
    case kVK_F3: return "F3"
    case kVK_F4: return "F4"
    case kVK_F5: return "F5"
    case kVK_F6: return "F6"
    case kVK_F7: return "F7"
    case kVK_F8: return "F8"
    case kVK_F9: return "F9"
    case kVK_F10: return "F10"
    case kVK_F11: return "F11"
    case kVK_F12: return "F12"
    case kVK_F13: return "F13"
    case kVK_F14: return "F14"
    case kVK_F15: return "F15"
    case kVK_F16: return "F16"
    case kVK_F17: return "F17"
    case kVK_F18: return "F18"
    case kVK_F19: return "F19"
    case kVK_F20: return "F20"
    // 数字キー（メインキーボード）
    case kVK_ANSI_1: return "1"
    case kVK_ANSI_2: return "2"
    case kVK_ANSI_3: return "3"
    case kVK_ANSI_4: return "4"
    case kVK_ANSI_5: return "5"
    case kVK_ANSI_6: return "6"
    case kVK_ANSI_7: return "7"
    case kVK_ANSI_8: return "8"
    case kVK_ANSI_9: return "9"
    case kVK_ANSI_0: return "0"
    // アルファベットキー
    case kVK_ANSI_A: return "A"
    case kVK_ANSI_B: return "B"
    case kVK_ANSI_C: return "C"
    case kVK_ANSI_D: return "D"
    case kVK_ANSI_E: return "E"
    case kVK_ANSI_F: return "F"
    case kVK_ANSI_G: return "G"
    case kVK_ANSI_H: return "H"
    case kVK_ANSI_I: return "I"
    case kVK_ANSI_J: return "J"
    case kVK_ANSI_K: return "K"
    case kVK_ANSI_L: return "L"
    case kVK_ANSI_M: return "M"
    case kVK_ANSI_N: return "N"
    case kVK_ANSI_O: return "O"
    case kVK_ANSI_P: return "P"
    case kVK_ANSI_Q: return "Q"
    case kVK_ANSI_R: return "R"
    case kVK_ANSI_S: return "S"
    case kVK_ANSI_T: return "T"
    case kVK_ANSI_U: return "U"
    case kVK_ANSI_V: return "V"
    case kVK_ANSI_W: return "W"
    case kVK_ANSI_X: return "X"
    case kVK_ANSI_Y: return "Y"
    case kVK_ANSI_Z: return "Z"
    // 記号キー
    case kVK_ANSI_Minus: return "-"
    case kVK_ANSI_Equal: return "="
    case kVK_ANSI_LeftBracket: return "["
    case kVK_ANSI_RightBracket: return "]"
    case kVK_ANSI_Backslash: return "\\"
    case kVK_ANSI_Semicolon: return ";"
    case kVK_ANSI_Quote: return "'"
    case kVK_ANSI_Comma: return ","
    case kVK_ANSI_Period: return "."
    case kVK_ANSI_Slash: return "/"
    case kVK_ANSI_Grave: return "`"
    // テンキー
    case kVK_ANSI_Keypad0: return "0"
    case kVK_ANSI_Keypad1: return "1"
    case kVK_ANSI_Keypad2: return "2"
    case kVK_ANSI_Keypad3: return "3"
    case kVK_ANSI_Keypad4: return "4"
    case kVK_ANSI_Keypad5: return "5"
    case kVK_ANSI_Keypad6: return "6"
    case kVK_ANSI_Keypad7: return "7"
    case kVK_ANSI_Keypad8: return "8"
    case kVK_ANSI_Keypad9: return "9"
    case kVK_ANSI_KeypadDecimal: return "."
    case kVK_ANSI_KeypadMultiply: return "*"
    case kVK_ANSI_KeypadPlus: return "+"
    case kVK_ANSI_KeypadMinus: return "-"
    case kVK_ANSI_KeypadDivide: return "/"
    case kVK_ANSI_KeypadEnter: return "↩"
    case kVK_ANSI_KeypadEquals: return "="
    case kVK_ANSI_KeypadClear: return "⌧"
    default: return ""
    }
}
