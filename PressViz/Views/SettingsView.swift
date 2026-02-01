import Carbon.HIToolbox
import SwiftUI

/// 設定画面
struct SettingsView: View {
    @State private var settings = AppSettings.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 表示位置
                displayPositionSection

                Divider()

                // 表示モード
                displayModeSection

                Divider()

                // グローバルショートカット
                shortcutSection

                Divider()

                // その他の設定
                otherSettingsSection
            }
            .padding()
        }
        .frame(maxHeight: 350)
    }

    // MARK: - Sections

    private var displayPositionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("表示位置")
                .font(.headline)

            PositionGridPicker(selectedPosition: $settings.displayPosition)
        }
    }

    private var displayModeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("表示モード")
                .font(.headline)

            Picker("", selection: $settings.keyDisplayMode) {
                ForEach(KeyDisplayMode.allCases, id: \.self) { mode in
                    VStack(alignment: .leading) {
                        Text(mode.displayName)
                        Text(mode.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .tag(mode)
                }
            }
            .pickerStyle(.radioGroup)
            .labelsHidden()
        }
    }

    private var shortcutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("グローバルショートカット")
                .font(.headline)

            Text("ON/OFF切り替え用のショートカットキー")
                .font(.caption)
                .foregroundStyle(.secondary)

            ShortcutRecorderView(shortcut: $settings.globalShortcut)
        }
    }

    private var otherSettingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("その他")
                .font(.headline)

            Toggle("クリックエフェクトを表示", isOn: $settings.showClickEffect)
        }
    }
}

/// 表示位置を選択するグリッドピッカー
struct PositionGridPicker: View {
    @Binding var selectedPosition: DisplayPosition

    private let positions: [[DisplayPosition]] = [
        [.topLeft, .topCenter, .topRight],
        [.middleLeft, .center, .middleRight],
        [.bottomLeft, .bottomCenter, .bottomRight]
    ]

    var body: some View {
        VStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { row in
                HStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { column in
                        let position = positions[row][column]
                        PositionButton(
                            position: position,
                            isSelected: selectedPosition == position
                        ) {
                            selectedPosition = position
                        }
                    }
                }
            }
        }
        .padding(8)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(.quaternary)
        }
    }
}

/// 位置選択ボタン
struct PositionButton: View {
    let position: DisplayPosition
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            RoundedRectangle(cornerRadius: 4)
                .fill(isSelected ? Color.accentColor : Color.secondary.opacity(0.3))
                .frame(width: 50, height: 30)
                .overlay {
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.caption)
                            .foregroundStyle(.white)
                    }
                }
        }
        .buttonStyle(.plain)
        .help(position.displayName)
    }
}

/// ショートカット記録ビュー
struct ShortcutRecorderView: View {
    @Binding var shortcut: GlobalShortcut
    @State private var isRecording = false
    @State private var keyMonitor: Any?
    @State private var clickMonitor: Any?

    private let fieldHeight: CGFloat = 28

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            if isRecording {
                // Recording 中
                Text("Press keys...")
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 12)
                    .frame(minWidth: 100)
                    .frame(height: fieldHeight)
                    .background {
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.accentColor, lineWidth: 1)
                    }
            } else if shortcut.isSet {
                // 設定済み
                Text(shortcut.displayString)
                    .font(.system(.body, design: .rounded))
                    .tracking(2)
                    .padding(.horizontal, 12)
                    .frame(height: fieldHeight)
                    .background {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(.quaternary)
                    }
                    .onTapGesture {
                        startRecording()
                    }

                Button {
                    shortcut = .none
                    GlobalShortcutManager.shared.unregister()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.secondary)
                        .frame(height: fieldHeight)
                }
                .buttonStyle(.plain)
            } else {
                // 未設定
                Text("Not set")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .frame(minWidth: 100)
                    .frame(height: fieldHeight)
                    .background {
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    }
                    .onTapGesture {
                        startRecording()
                    }
            }
        }
        .onDisappear {
            stopRecording()
        }
    }

    private func startRecording() {
        isRecording = true
        print("[ShortcutRecorder] Started recording")

        // キーイベントを監視
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            print("[ShortcutRecorder] Key event received")
            print("[ShortcutRecorder] keyCode: \(event.keyCode)")
            print("[ShortcutRecorder] modifierFlags: \(event.modifierFlags.rawValue)")

            // Escape キーでキャンセル
            if event.keyCode == 53 {
                print("[ShortcutRecorder] Escape pressed, cancelling")
                stopRecording()
                return nil
            }

            // 修飾キーが押されているか確認
            let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            let hasModifier = modifiers.contains(.command) ||
                              modifiers.contains(.option) ||
                              modifiers.contains(.control) ||
                              modifiers.contains(.shift)

            guard hasModifier else {
                print("[ShortcutRecorder] No modifier keys, ignoring")
                return event
            }

            // Carbon 形式の修飾キーに変換
            var carbonMods: UInt32 = 0
            if modifiers.contains(.command) { carbonMods |= UInt32(cmdKey) }
            if modifiers.contains(.option) { carbonMods |= UInt32(optionKey) }
            if modifiers.contains(.control) { carbonMods |= UInt32(controlKey) }
            if modifiers.contains(.shift) { carbonMods |= UInt32(shiftKey) }

            let newShortcut = GlobalShortcut(keyCode: UInt32(event.keyCode), modifiers: carbonMods)
            print("[ShortcutRecorder] Setting shortcut: \(newShortcut.displayString)")

            shortcut = newShortcut
            GlobalShortcutManager.shared.updateShortcut(newShortcut)
            stopRecording()

            return nil // イベントを消費
        }

        // クリックで recording をキャンセル
        clickMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { event in
            print("[ShortcutRecorder] Click detected, cancelling recording")
            stopRecording()
            return event
        }
    }

    private func stopRecording() {
        isRecording = false
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
        }
        if let monitor = clickMonitor {
            NSEvent.removeMonitor(monitor)
            clickMonitor = nil
        }
        print("[ShortcutRecorder] Stopped recording")
    }
}

#Preview {
    SettingsView()
        .frame(width: 320)
}
