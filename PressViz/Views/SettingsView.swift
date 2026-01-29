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

    var body: some View {
        HStack {
            if shortcut.isSet {
                Text(shortcut.displayString)
                    .font(.system(.body, design: .monospaced))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(.quaternary)
                    }

                Button("クリア") {
                    shortcut = .none
                    GlobalShortcutManager.shared.unregister()
                }
                .buttonStyle(.borderless)
            } else {
                Text(isRecording ? "キーを入力..." : "未設定")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background {
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(isRecording ? Color.accentColor : Color.secondary.opacity(0.3), lineWidth: 1)
                    }
            }

            Spacer()

            Button(isRecording ? "キャンセル" : "記録") {
                isRecording.toggle()
            }
            .buttonStyle(.bordered)
        }
        .onKeyPress { keyPress in
            guard isRecording else { return .ignored }

            // 修飾キーのみの場合は無視
            if keyPress.modifiers.isEmpty { return .ignored }

            let keyCode = keyCodeFromKeyEquivalent(keyPress.key)
            let modifiers = carbonModifiersFromSwiftUI(keyPress.modifiers)

            shortcut = GlobalShortcut(keyCode: UInt32(keyCode), modifiers: UInt32(modifiers))
            GlobalShortcutManager.shared.updateShortcut(shortcut)
            isRecording = false

            return .handled
        }
    }

    private func keyCodeFromKeyEquivalent(_ key: KeyEquivalent) -> Int {
        // 簡易実装：実際にはより詳細なマッピングが必要
        switch key.character {
        case "a": return 0
        case "s": return 1
        case "d": return 2
        case "f": return 3
        case "h": return 4
        case "g": return 5
        case "z": return 6
        case "x": return 7
        case "c": return 8
        case "v": return 9
        case "b": return 11
        case "q": return 12
        case "w": return 13
        case "e": return 14
        case "r": return 15
        case "y": return 16
        case "t": return 17
        case "1": return 18
        case "2": return 19
        case "3": return 20
        case "4": return 21
        case "6": return 22
        case "5": return 23
        case "9": return 25
        case "7": return 26
        case "8": return 28
        case "0": return 29
        case "o": return 31
        case "u": return 32
        case "i": return 34
        case "p": return 35
        case "l": return 37
        case "j": return 38
        case "k": return 40
        case "n": return 45
        case "m": return 46
        default: return 0
        }
    }

    private func carbonModifiersFromSwiftUI(_ modifiers: SwiftUI.EventModifiers) -> Int {
        var carbonMods = 0
        if modifiers.contains(.command) { carbonMods |= cmdKey }
        if modifiers.contains(.option) { carbonMods |= optionKey }
        if modifiers.contains(.control) { carbonMods |= controlKey }
        if modifiers.contains(.shift) { carbonMods |= shiftKey }
        return carbonMods
    }
}

#Preview {
    SettingsView()
        .frame(width: 320)
}
