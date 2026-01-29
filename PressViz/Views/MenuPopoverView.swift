import SwiftUI

/// メニューバーのPopoverビュー
struct MenuPopoverView: View {
    @State private var settings = AppSettings.shared
    @State private var permissionManager = AccessibilityPermissionManager.shared
    @State private var showingSettings = false

    var body: some View {
        VStack(spacing: 0) {
            // ヘッダー
            headerSection

            Divider()

            // コンテンツ
            if !permissionManager.isAccessibilityEnabled {
                permissionRequiredSection
            } else if showingSettings {
                settingsSection
            } else {
                mainSection
            }

            Divider()

            // フッター
            footerSection
        }
        .frame(width: 320)
        .onAppear {
            permissionManager.startMonitoring()
        }
        .onDisappear {
            permissionManager.stopMonitoring()
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        HStack {
            Image(systemName: "keyboard")
                .font(.title2)
                .foregroundStyle(.secondary)

            Text("PressViz")
                .font(.headline)

            Spacer()

            if permissionManager.isAccessibilityEnabled {
                Toggle("", isOn: $settings.isEnabled)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }
        }
        .padding()
    }

    private var permissionRequiredSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.shield")
                .font(.system(size: 40))
                .foregroundStyle(.orange)

            Text("アクセシビリティ権限が必要です")
                .font(.headline)

            Text("キーボードとマウスの入力を監視するために、アクセシビリティ権限を許可してください。")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("システム環境設定を開く") {
                permissionManager.openAccessibilitySettings()
            }
            .buttonStyle(.borderedProminent)

            Button("権限を確認") {
                permissionManager.checkAccessibility()
                if permissionManager.isAccessibilityEnabled {
                    settings.hasCompletedOnboarding = true
                    settings.isEnabled = true
                    AppDelegate.shared?.startVisualization()
                }
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }

    private var mainSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // ステータス表示
            HStack {
                Circle()
                    .fill(settings.isEnabled ? .green : .gray)
                    .frame(width: 8, height: 8)

                Text(settings.isEnabled ? "有効" : "無効")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()
            }

            // クイック設定
            HStack {
                Text("表示位置")
                    .font(.subheadline)

                Spacer()

                Text(settings.displayPosition.displayName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text("表示モード")
                    .font(.subheadline)

                Spacer()

                Text(settings.keyDisplayMode.displayName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Toggle("クリックエフェクト", isOn: $settings.showClickEffect)
                .font(.subheadline)
        }
        .padding()
    }

    private var settingsSection: some View {
        SettingsView()
    }

    private var footerSection: some View {
        HStack {
            Button(showingSettings ? "戻る" : "設定") {
                withAnimation {
                    showingSettings.toggle()
                }
            }
            .buttonStyle(.borderless)

            Spacer()

            Button("終了") {
                NSApp.terminate(nil)
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.red)
        }
        .padding()
    }
}

#Preview {
    MenuPopoverView()
}
