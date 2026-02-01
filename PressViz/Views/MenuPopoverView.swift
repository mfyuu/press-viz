import SwiftUI

/// メニューバーのPopoverビュー
struct MenuPopoverView: View {
    @State private var settings = AppSettings.shared
    @State private var permissionManager = AccessibilityPermissionManager.shared
    @State private var selectedTab: MenuTab = .general

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
        .frame(width: 380, height: 420)
        .onAppear {
            permissionManager.startMonitoring()
        }
        .onDisappear {
            permissionManager.stopMonitoring()
        }
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
        VStack(spacing: 20) {
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

            Button("Open System Settings") {
                permissionManager.openAccessibilitySettings()
            }
            .buttonStyle(.borderedProminent)

            Spacer()

            Button("Quit") {
                NSApp.terminate(nil)
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
        }
        .padding(24)
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
