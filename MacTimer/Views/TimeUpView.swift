import AppKit
import SwiftUI

struct TimeUpView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismissWindow) private var dismissWindow

    private var palette: Palette { model.palette(for: colorScheme) }

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "bell.fill")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(palette.accent)
                .accessibilityHidden(true)
            Text("Time's Up")
                .font(.system(size: 28, weight: .semibold))
            Text("Your countdown has finished.")
                .font(.body)
                .foregroundStyle(palette.secondary)
                .multilineTextAlignment(.center)
            Button(action: dismiss) {
                Text("Dismiss")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.plain)
            .foregroundStyle(palette.onAccent)
            .background(palette.accent, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .keyboardShortcut(.defaultAction)
            .padding(.top, 8)
        }
        .padding(28)
        .frame(width: 360, height: 280)
        .background(palette.background)
        .foregroundStyle(palette.text)
        .preferredColorScheme(model.colorScheme())
        .background(
            Button("Dismiss") { dismiss() }
                .keyboardShortcut(.cancelAction)
                .labelsHidden()
                .frame(width: 0, height: 0)
                .accessibilityHidden(true)
        )
        .background(
            WindowConfigurator(
                role: .timeUp,
                background: palette.background,
                alwaysOnTop: true,
                hideInsteadOfQuit: false,
                placeBottomTrailing: false,
                onHidden: {},
                onDismiss: finish
            )
            .frame(width: 0, height: 0)
        )
    }

    private func dismiss() {
        finish()
        dismissWindow(id: "timeup")
    }

    private func finish() {
        model.dismissAlert()
    }
}
