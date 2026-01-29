import Foundation

/// キー表示モード
enum KeyDisplayMode: String, CaseIterable, Codable, Sendable {
    /// 修飾キー + 通常キー (⌘+C など)
    case modifierPlusKey = "modifierPlusKey"
    /// 修飾キーのみ (⌘, ⌥, ⇧ など)
    case modifierOnly = "modifierOnly"
    /// 全キー入力
    case allKeys = "allKeys"

    var displayName: String {
        switch self {
        case .modifierPlusKey: "修飾キー + 通常キー"
        case .modifierOnly: "修飾キーのみ"
        case .allKeys: "全キー入力"
        }
    }

    var description: String {
        switch self {
        case .modifierPlusKey: "⌘+C, ⌥+Tab など"
        case .modifierOnly: "⌘, ⌥, ⇧ など"
        case .allKeys: "すべてのキー入力を表示"
        }
    }
}
