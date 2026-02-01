import LaunchAtLogin
import SwiftUI

/// General settings tab
struct GeneralTabView: View {
    @State private var settings = AppSettings.shared
    @State private var permissionManager = AccessibilityPermissionManager.shared
    @State private var isQuitHovering = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                enabledSection

                Divider()

                startupSection

                Divider()

                shortcutSection

                Divider()

                accessibilitySection

                Divider()

                quitSection
            }
            .padding()
        }
    }

    // MARK: - Sections

    private var enabledSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("PressViz")
                    .font(.headline)

                HStack(spacing: 6) {
                    Circle()
                        .fill(settings.isEnabled ? .green : .gray)
                        .frame(width: 8, height: 8)
                    Text(settings.isEnabled ? "Enabled" : "Disabled")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Toggle("", isOn: $settings.isEnabled)
                .toggleStyle(.switch)
                .labelsHidden()
                .controlSize(.small)
                .disabled(!permissionManager.isAccessibilityEnabled)
        }
    }

    private var startupSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Launch at Login")
                    .font(.subheadline)
                Text("Automatically start when Mac starts")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            LaunchAtLogin.Toggle("")
                .toggleStyle(.switch)
                .labelsHidden()
                .controlSize(.small)
        }
    }

    private var shortcutSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Global Shortcut")
                .font(.subheadline)

            Text("Shortcut key to toggle ON/OFF")
                .font(.caption)
                .foregroundStyle(.secondary)

            ShortcutRecorderView(shortcut: $settings.globalShortcut)
        }
    }

    private var accessibilitySection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: permissionManager.isAccessibilityEnabled ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                        .foregroundStyle(permissionManager.isAccessibilityEnabled ? .green : .orange)
                    Text("Accessibility")
                        .font(.subheadline)
                }

                Text(permissionManager.isAccessibilityEnabled ? "Permission granted" : "Permission required")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button("Open Settings") {
                permissionManager.openAccessibilitySettings()
            }
            .buttonStyle(.bordered)
        }
    }

    private var quitSection: some View {
        Button {
            NSApp.terminate(nil)
        } label: {
            Text("Quit PressViz")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .contentShape(Rectangle())
                .background {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isQuitHovering ? Color.primary.opacity(0.1) : Color.clear)
                }
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isQuitHovering = hovering
        }
    }
}

#Preview {
    GeneralTabView()
        .frame(width: 340, height: 350)
}
