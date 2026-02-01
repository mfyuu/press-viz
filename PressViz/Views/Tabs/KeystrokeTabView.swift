import SwiftUI

/// Keystroke settings tab
struct KeystrokeTabView: View {
    @State private var settings = AppSettings.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                displayPositionSection

                Divider()

                displayModeSection

                Divider()

                displayScaleSection
            }
            .padding()
        }
    }

    // MARK: - Sections

    private var displayPositionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Position")
                .font(.headline)

            Text("Key display position on screen")
                .font(.caption)
                .foregroundStyle(.secondary)

            PositionGridPicker(selectedPosition: $settings.displayPosition)
        }
    }

    private var displayModeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Display Mode")
                .font(.headline)

            Picker("", selection: $settings.keyDisplayMode) {
                ForEach(KeyDisplayMode.allCases, id: \.self) { mode in
                    VStack(alignment: .leading, spacing: 2) {
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

    private var displayScaleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Size")
                    .font(.headline)

                Spacer()

                Text("\(Int(settings.displayScale * 100))%")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            Text("Adjust overall scale of key display")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                Text("50%")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Slider(value: $settings.displayScale, in: 0.5...1.5, step: 0.05)

                Text("150%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Spacer()
                Button("Reset") {
                    settings.displayScale = 1.0
                }
                .buttonStyle(.borderless)
                .disabled(settings.displayScale == 1.0)
            }
        }
    }
}

#Preview {
    KeystrokeTabView()
        .frame(width: 340, height: 350)
}
