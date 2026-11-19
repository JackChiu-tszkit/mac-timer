import AppKit
import SwiftUI

struct MiniTimerView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismissWindow) private var dismissWindow

    private var palette: Palette { model.palette(for: colorScheme) }

    var body: some View {
        HStack(spacing: 16) {
            Text(model.displayTime)
                .font(.system(size: 28, weight: .semibold, design: .rounded).monospacedDigit())
                .accessibilityLabel("Time remaining \(model.displayTime)")
            Spacer(minLength: 8)
            Button(action: model.toggle) {
                Image(systemName: model.status == .running ? "pause.fill" : "play.fill")
                    .frame(width: 36, height: 36)
                    .foregroundStyle(palette.onAccent)
                    .background(palette.accent, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(model.primaryTitle)
            Button(action: expand) {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .frame(width: 32, height: 32)
                    .foregroundStyle(palette.text)
                    .background(palette.surface, in: Circle())
            }
            .buttonStyle(.plain)
            .help("Expand")
            .accessibilityLabel("Expand")
        }
        .padding(.horizontal, 18)
        .frame(width: 286, height: 84)
        .background(palette.background)
        .foregroundStyle(palette.text)
        .preferredColorScheme(model.colorScheme())
        .background(configurator)
    }

    private var configurator: some View {
        WindowConfigurator(
            role: .mini,
            background: palette.background,
            alwaysOnTop: true,
            hideInsteadOfQuit: false,
            placeBottomTrailing: true,
            handlesKeys: true,
            onHidden: {},
            onDismiss: leaveMini,
            onToggle: { model.toggle() },
            onReset: { model.reset() }
        )
        .frame(width: 0, height: 0)
    }

    private func expand() {
        leaveMini()
        dismissWindow(id: "mini")
    }

    private func leaveMini() {
        model.miniOpen = false
        model.reveal(role: .main)
    }
}
