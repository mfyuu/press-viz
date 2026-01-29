import Foundation
import SwiftUI

/// アプリケーション設定を管理
@Observable
@MainActor
final class AppSettings {
    // MARK: - Singleton

    static let shared = AppSettings()

    // MARK: - UserDefaults Keys

    private enum Keys {
        static let isEnabled = "isEnabled"
        static let displayPosition = "displayPosition"
        static let keyDisplayMode = "keyDisplayMode"
        static let globalShortcut = "globalShortcut"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let showClickEffect = "showClickEffect"
    }

    // MARK: - Properties

    /// 可視化のON/OFF
    var isEnabled: Bool {
        didSet { UserDefaults.standard.set(isEnabled, forKey: Keys.isEnabled) }
    }

    /// 表示位置
    var displayPosition: DisplayPosition {
        didSet { saveDisplayPosition() }
    }

    /// キー表示モード
    var keyDisplayMode: KeyDisplayMode {
        didSet { saveKeyDisplayMode() }
    }

    /// グローバルショートカット
    var globalShortcut: GlobalShortcut {
        didSet { saveGlobalShortcut() }
    }

    /// オンボーディング完了フラグ
    var hasCompletedOnboarding: Bool {
        didSet { UserDefaults.standard.set(hasCompletedOnboarding, forKey: Keys.hasCompletedOnboarding) }
    }

    /// クリックエフェクト表示
    var showClickEffect: Bool {
        didSet { UserDefaults.standard.set(showClickEffect, forKey: Keys.showClickEffect) }
    }

    // MARK: - Initialization

    private init() {
        let defaults = UserDefaults.standard

        // 初回起動時はtrueにする
        self.isEnabled = defaults.object(forKey: Keys.isEnabled) as? Bool ?? true
        self.hasCompletedOnboarding = defaults.bool(forKey: Keys.hasCompletedOnboarding)
        self.showClickEffect = defaults.object(forKey: Keys.showClickEffect) as? Bool ?? true

        // DisplayPosition
        if let positionString = defaults.string(forKey: Keys.displayPosition),
           let position = DisplayPosition(rawValue: positionString) {
            self.displayPosition = position
        } else {
            self.displayPosition = .bottomCenter
        }

        // KeyDisplayMode
        if let modeString = defaults.string(forKey: Keys.keyDisplayMode),
           let mode = KeyDisplayMode(rawValue: modeString) {
            self.keyDisplayMode = mode
        } else {
            self.keyDisplayMode = .modifierPlusKey
        }

        // GlobalShortcut
        if let data = defaults.data(forKey: Keys.globalShortcut),
           let shortcut = try? JSONDecoder().decode(GlobalShortcut.self, from: data) {
            self.globalShortcut = shortcut
        } else {
            self.globalShortcut = .none
        }
    }

    // MARK: - Private Methods

    private func saveDisplayPosition() {
        UserDefaults.standard.set(displayPosition.rawValue, forKey: Keys.displayPosition)
    }

    private func saveKeyDisplayMode() {
        UserDefaults.standard.set(keyDisplayMode.rawValue, forKey: Keys.keyDisplayMode)
    }

    private func saveGlobalShortcut() {
        if let data = try? JSONEncoder().encode(globalShortcut) {
            UserDefaults.standard.set(data, forKey: Keys.globalShortcut)
        }
    }

    // MARK: - Public Methods

    func toggleEnabled() {
        isEnabled.toggle()
    }
}
