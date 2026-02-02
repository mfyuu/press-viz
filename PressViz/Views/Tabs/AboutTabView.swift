import SwiftUI

/// About tab
struct AboutTabView: View {
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 72, height: 72)

            VStack(spacing: 4) {
                Text("PressViz")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Version \(appVersion) (\(buildNumber))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button {
                if let url = URL(string: "https://github.com/mfyuu/press-viz") {
                    NSWorkspace.shared.open(url)
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "link")
                    Text("GitHub")
                }
            }
            .buttonStyle(.link)

            Text("© 2026 mfyuu")
                .font(.caption2)
                .foregroundStyle(.tertiary)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    AboutTabView()
        .frame(width: 340, height: 350)
}
