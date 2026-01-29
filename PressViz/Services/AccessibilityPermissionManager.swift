import ApplicationServices
import Cocoa
import Foundation

/// アクセシビリティ権限を管理
@Observable
@MainActor
final class AccessibilityPermissionManager {
    // MARK: - Singleton

    static let shared = AccessibilityPermissionManager()

    // MARK: - Properties

    /// 権限が付与されているか
    private(set) var isAccessibilityEnabled: Bool = false

    /// 権限チェック用タイマー
    private var checkTimer: Timer?

    // MARK: - Initialization

    private init() {
        checkAccessibility()
    }

    // MARK: - Public Methods

    /// アクセシビリティ権限をチェック
    func checkAccessibility() {
        let wasEnabled = isAccessibilityEnabled
        isAccessibilityEnabled = AXIsProcessTrusted()

        // 権限が新たに付与された場合、監視を開始
        if !wasEnabled && isAccessibilityEnabled {
            AppSettings.shared.hasCompletedOnboarding = true
            AppSettings.shared.isEnabled = true
            AppDelegate.shared?.startVisualization()
            stopMonitoring() // 権限が付与されたら監視を停止
        }
    }

    /// アクセシビリティ権限をリクエスト（システム環境設定を開く）
    func requestAccessibility() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    /// システム環境設定のアクセシビリティ設定を開く
    func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }

    /// 権限チェックの監視を開始
    func startMonitoring() {
        stopMonitoring()
        checkAccessibility()

        checkTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkAccessibility()
            }
        }
    }

    /// 権限チェックの監視を停止
    func stopMonitoring() {
        checkTimer?.invalidate()
        checkTimer = nil
    }
}
