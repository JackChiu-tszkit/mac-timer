import AppKit
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.colorScheme) private var colorScheme

    private var palette: Palette { model.palette(for: colorScheme) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("Settings")
                    .font(.title2.weight(.semibold))

                section("Theme") {
                    chipRow(ThemePreference.allCases, title: \.title, isSelected: { $0 == model.settings.theme }) { theme in
                        model.updateSettings { $0.theme = theme }
                    }
                }

                section("Alert sound") {
                    chipRow(AlertSoundId.allCases, title: \.title, isSelected: { $0 == model.settings.alertSound }) { sound in
                        model.updateSettings { $0.alertSound = sound }
                    }
                    Button("Preview") {
                        model.previewSound()
                    }
                    .buttonStyle(.plain)
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .foregroundStyle(palette.onAccent)
                    .background(palette.accent, in: Capsule())
                    .accessibilityLabel("Preview alert sound")
                }

                section("Volume") {
                    HStack {
                        Slider(value: volumeBinding, in: 0...1)
                            .accessibilityLabel("Volume")
                        Text("\(Int((model.settings.volume * 100).rounded()))%")
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(palette.secondary)
                            .frame(width: 44, alignment: .trailing)
                    }
                }

                toggle("Mute", isOn: binding(\.mute))
                toggle("Repeat until dismissed", isOn: binding(\.repeatUntilDismissed))
                toggle("Always on top", isOn: binding(\.alwaysOnTop))
                toggle("Launch at login", isOn: binding(\.launchOnStartup))

                section("When the window closes") {
                    chipRow(CloseBehavior.allCases, title: \.title, isSelected: { $0 == model.settings.closeBehavior }) { behavior in
                        model.updateSettings { $0.closeBehavior = behavior }
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(width: 480, height: 560)
        .background(palette.background)
        .foregroundStyle(palette.text)
        .preferredColorScheme(model.colorScheme())
        .background(closeShortcut)
    }

    private var volumeBinding: Binding<Double> {
        Binding(
            get: { model.settings.volume },
            set: { value in
                model.updateSettings { $0.volume = value }
            }
        )
    }

    private var closeShortcut: some View {
        Button("Close") {
            NSApp.keyWindow?.performClose(nil)
        }
        .keyboardShortcut(.cancelAction)
        .labelsHidden()
        .frame(width: 0, height: 0)
        .accessibilityHidden(true)
    }

    private func binding(_ keyPath: WritableKeyPath<AppSettings, Bool>) -> Binding<Bool> {
        Binding(
            get: { model.settings[keyPath: keyPath] },
            set: { value in
                model.updateSettings { $0[keyPath: keyPath] = value }
            }
        )
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
            content()
        }
    }

    private func toggle(_ title: String, isOn: Binding<Bool>) -> some View {
        Toggle(title, isOn: isOn)
            .toggleStyle(.switch)
            .font(.body)
    }

    private func chipRow<Item: Hashable>(
        _ items: [Item],
        title: KeyPath<Item, String>,
        isSelected: @escaping (Item) -> Bool,
        action: @escaping (Item) -> Void
    ) -> some View {
        HStack(spacing: 8) {
            ForEach(items, id: \.self) { item in
                let selected = isSelected(item)
                Button(item[keyPath: title]) {
                    action(item)
                }
                .buttonStyle(.plain)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .foregroundStyle(selected ? palette.onAccent : palette.text)
                .background(selected ? palette.accent : palette.surface, in: Capsule())
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
    }
}
