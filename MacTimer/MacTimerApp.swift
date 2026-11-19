import AppKit
import SwiftUI

@main
struct MacTimerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var model = AppModel()

    var body: some Scene {
        Window("Timer", id: "main") {
            MainView()
                .environmentObject(model)
        }
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }

        Window("Mini Timer", id: "mini") {
            MiniTimerView()
                .environmentObject(model)
        }
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
        .defaultLaunchBehavior(.suppressed)

        Window("Time's Up", id: "timeup") {
            TimeUpView()
                .environmentObject(model)
        }
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
        .defaultLaunchBehavior(.suppressed)

        MenuBarExtra {
            MenuBarMenu()
                .environmentObject(model)
        } label: {
            MenuBarLabel()
                .environmentObject(model)
        }

        Settings {
            SettingsView()
                .environmentObject(model)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}

private struct MenuBarLabel: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "timer")
            if model.status != .idle {
                Text(model.displayTime)
                    .monospacedDigit()
            }
        }
        .accessibilityLabel(model.menuBarTitle)
    }
}

private struct MenuBarMenu: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button("Open Timer") {
            openMain()
        }
        Button(model.primaryTitle) {
            model.toggle()
        }
        Button("Reset") {
            model.reset()
        }
        Divider()
        Button("Quit Timer") {
            NSApp.terminate(nil)
        }
    }

    private func openMain() {
        model.miniOpen = false
        NSApp.activate()
        if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == WindowRole.main.rawValue }) {
            window.makeKeyAndOrderFront(nil)
        } else {
            openWindow(id: "main")
        }
    }
}
