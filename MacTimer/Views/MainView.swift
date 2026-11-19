import AppKit
import SwiftUI

struct MainView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.openWindow) private var openWindow
    @FocusState private var focusedField: TimeField?

    private var palette: Palette { model.palette(for: colorScheme) }

    var body: some View {
        VStack(spacing: 22) {
            header
            ring
            statusLine
            controls
            presets
            footer
        }
        .padding(.horizontal, 28)
        .padding(.top, 36)
        .padding(.bottom, 24)
        .frame(width: 420, height: 600)
        .background(palette.background)
        .foregroundStyle(palette.text)
        .preferredColorScheme(model.colorScheme())
        .background(configurator)
        .onChange(of: focusedField) { _, field in
            if field == nil {
                model.normalizeFields()
            }
            model.editingTime = field != nil
        }
        .onChange(of: model.presentTimeUp) { _, show in
            if show {
                openWindow(id: "timeup")
                Task { @MainActor in
                    model.reveal(role: .timeUp)
                }
            }
        }
        .onChange(of: model.miniOpen) { _, open in
            if open {
                openWindow(id: "mini")
                Task { @MainActor in
                    model.reveal(role: .mini)
                }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Timer")
                    .font(.title2.weight(.semibold))
                Text("Countdown")
                    .font(.subheadline)
                    .foregroundStyle(palette.secondary)
            }
            Spacer()
            iconButton(
                systemName: model.settings.alwaysOnTop ? "pin.fill" : "pin",
                help: "Always on top",
                label: "Always on top"
            ) {
                model.updateSettings { $0.alwaysOnTop.toggle() }
            }
            .accessibilityValue(model.settings.alwaysOnTop ? "On" : "Off")
            iconButton(systemName: "gearshape", help: "Settings", label: "Settings") {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            }
            iconButton(systemName: "rectangle.compress.vertical", help: "Mini timer", label: "Mini timer") {
                model.miniOpen = true
                NSApp.windows.first { $0.identifier?.rawValue == WindowRole.main.rawValue }?.orderOut(nil)
            }
        }
    }

    private var ring: some View {
        ZStack {
            RingProgress(progress: model.ringProgress, accent: palette.accent, track: palette.track)
                .frame(width: 220, height: 220)
            if model.showsEditableTime {
                timeFields
            } else {
                Text(model.displayTime)
                    .font(.system(size: 40, weight: .semibold, design: .rounded).monospacedDigit())
                    .accessibilityLabel("Time remaining \(model.displayTime)")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    private var timeFields: some View {
        HStack(spacing: 4) {
            timeField(text: hoursBinding, field: .hours, label: "Hours")
            Text(":")
                .font(.system(size: 32, weight: .semibold, design: .rounded))
                .foregroundStyle(palette.secondary)
            timeField(text: minutesBinding, field: .minutes, label: "Minutes")
            Text(":")
                .font(.system(size: 32, weight: .semibold, design: .rounded))
                .foregroundStyle(palette.secondary)
            timeField(text: secondsBinding, field: .seconds, label: "Seconds")
        }
    }

    private var statusLine: some View {
        Text(model.statusTitle)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(palette.secondary)
            .frame(maxWidth: .infinity)
    }

    private var controls: some View {
        VStack(spacing: 10) {
            Button(action: model.toggle) {
                Text(model.primaryTitle)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
            .foregroundStyle(palette.onAccent)
            .background(palette.accent, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .opacity(model.canPrimary ? 1 : 0.45)
            .accessibilityLabel(model.primaryTitle)

            Button(action: model.reset) {
                Text("Reset")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.plain)
            .foregroundStyle(palette.text)
            .background(palette.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .accessibilityLabel("Reset")
        }
    }

    private var presets: some View {
        HStack(spacing: 8) {
            ForEach(model.presets, id: \.self) { minutes in
                Button("\(minutes)m") {
                    model.startPreset(minutes)
                }
                .buttonStyle(.plain)
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .foregroundStyle(palette.text)
                .background(palette.surface, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .help("Start a \(minutes) minute timer")
                .accessibilityLabel("Start \(minutes) minute timer")
            }
        }
    }

    private var footer: some View {
        Text("Space starts or pauses. R resets.")
            .font(.caption)
            .foregroundStyle(palette.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var configurator: some View {
        WindowConfigurator(
            role: .main,
            background: palette.background,
            alwaysOnTop: model.settings.alwaysOnTop,
            hideInsteadOfQuit: model.settings.closeBehavior == .hideToMenuBar,
            placeBottomTrailing: false,
            isEditing: model.editingTime,
            handlesKeys: true,
            onHidden: { model.noteHiddenToMenuBar() },
            onDismiss: {},
            onToggle: { model.toggle() },
            onReset: { model.reset() }
        )
        .frame(width: 0, height: 0)
    }

    private var hoursBinding: Binding<String> { digitBinding(\.hoursText) }
    private var minutesBinding: Binding<String> { digitBinding(\.minutesText) }
    private var secondsBinding: Binding<String> { digitBinding(\.secondsText) }

    private func digitBinding(_ keyPath: ReferenceWritableKeyPath<AppModel, String>) -> Binding<String> {
        Binding(
            get: { model[keyPath: keyPath] },
            set: { newValue in
                let digits = newValue.filter(\.isNumber)
                model[keyPath: keyPath] = String(digits.prefix(2))
            }
        )
    }

    private func timeField(text: Binding<String>, field: TimeField, label: String) -> some View {
        TextField("", text: text)
            .focused($focusedField, equals: field)
            .multilineTextAlignment(.center)
            .font(.system(size: 32, weight: .semibold, design: .rounded).monospacedDigit())
            .textFieldStyle(.plain)
            .frame(width: 58)
            .accessibilityLabel(label)
    }

    private func iconButton(systemName: String, help: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .semibold))
                .frame(width: 32, height: 32)
                .foregroundStyle(palette.text)
                .background(palette.surface, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .help(help)
        .accessibilityLabel(label)
    }
}

private enum TimeField: Hashable {
    case hours
    case minutes
    case seconds
}
