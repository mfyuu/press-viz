import SwiftUI

/// Click settings tab
struct ClickTabView: View {
    @State private var settings = AppSettings.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            clickEffectSection

            Divider()

            futureSection

            Spacer()
        }
        .padding()
    }

    // MARK: - Sections

    private var clickEffectSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Click Effect")
                    .font(.headline)

                Text("Show effect on mouse click")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Toggle("", isOn: $settings.showClickEffect)
                .toggleStyle(.switch)
                .labelsHidden()
                .controlSize(.small)
        }
    }

    private var futureSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(.secondary)
                Text("More Options")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Text("More customization options coming in future updates.")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }
}

#Preview {
    ClickTabView()
        .frame(width: 340, height: 350)
}
