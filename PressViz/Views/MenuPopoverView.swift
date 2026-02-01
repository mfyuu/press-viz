import SwiftUI

/// メニューバーのPopoverビュー
struct MenuPopoverView: View {
    @State private var settings = AppSettings.shared
    @State private var permissionManager = AccessibilityPermissionManager.shared
    @State private var selectedTab: MenuTab = .general
    @State private var isQuitHovering = false

    private var popoverSize: NSSize {
        permissionManager.isAccessibilityEnabled
            ? NSSize(width: 380, height: 420)
            : NSSize(width: 300, height: 280)
    }

    var body: some View {
        VStack(spacing: 0) {
            // アクセシビリティ権限が無い場合
            if !permissionManager.isAccessibilityEnabled {
                permissionRequiredView
            } else {
                // タブバー
                tabBar

                Divider()

                // タブコンテンツ
                tabContent
            }
        }
        .frame(width: popoverSize.width, height: popoverSize.height)
        .onAppear {
            permissionManager.startMonitoring()
            updatePopoverSize()
        }
        .onDisappear {
            permissionManager.stopMonitoring()
        }
        .onChange(of: permissionManager.isAccessibilityEnabled) {
            updatePopoverSize()
        }
    }

    private func updatePopoverSize() {
        NotificationCenter.default.post(
            name: .popoverSizeDidChange,
            object: nil,
            userInfo: ["size": popoverSize]
        )
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(MenuTab.allCases, id: \.self) { tab in
                TabButton(tab: tab, isSelected: selectedTab == tab) {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selectedTab = tab
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.bar)
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .general:
            GeneralTabView()
        case .keystroke:
            KeystrokeTabView()
        case .click:
            ClickTabView()
        case .about:
            AboutTabView()
        }
    }

    // MARK: - Permission Required View

    private var permissionRequiredView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "lock.shield")
                .font(.system(size: 48))
                .foregroundStyle(.orange)

            VStack(spacing: 6) {
                Text("Accessibility Permission Required")
                    .font(.headline)
                    .fontWeight(.semibold)

                Text("To monitor keyboard and mouse input,\nplease grant accessibility permission.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                permissionManager.openAccessibilitySettings()
            } label: {
                Text("Open System Settings")
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
            }
            .buttonStyle(.borderedProminent)

            Divider()

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
            .padding(.bottom, 4)
        }
        .padding()
    }
}

// MARK: - Menu Tab Enum

enum MenuTab: String, CaseIterable {
    case general
    case keystroke
    case click
    case about

    var title: String {
        switch self {
        case .general: return "General"
        case .keystroke: return "Keystroke"
        case .click: return "Click"
        case .about: return "About"
        }
    }

    var iconName: String {
        switch self {
        case .general: return "gearshape"
        case .keystroke: return "keyboard"
        case .click: return "cursorarrow.click.2"
        case .about: return "info.circle"
        }
    }
}

// MARK: - Tab Button

struct TabButton: View {
    let tab: MenuTab
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: tab.iconName)
                    .font(.system(size: 18))
                Text(tab.title)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.selection)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(isSelected ? .primary : .secondary)
    }
}

#Preview {
    MenuPopoverView()
}
