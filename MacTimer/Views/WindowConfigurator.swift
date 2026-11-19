import AppKit
import SwiftUI

struct WindowConfigurator: NSViewRepresentable {
    var role: WindowRole
    var background: Color
    var alwaysOnTop: Bool
    var hideInsteadOfQuit: Bool
    var placeBottomTrailing: Bool
    var isEditing: Bool = false
    var handlesKeys: Bool = false
    var onHidden: () -> Void
    var onDismiss: () -> Void
    var onToggle: () -> Void = {}
    var onReset: () -> Void = {}

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeNSView(context: Context) -> NSView {
        let view = ConfigView()
        view.onWindow = { window in
            context.coordinator.attach(window)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.parent = self
        if let window = nsView.window {
            context.coordinator.apply(window)
        }
    }

    final class Coordinator: NSObject, NSWindowDelegate {
        var parent: WindowConfigurator
        private var didPlace = false
        private var keyMonitor: Any?
        private static var didRequestTerminate = false

        init(parent: WindowConfigurator) {
            self.parent = parent
        }

        deinit {
            if let keyMonitor {
                NSEvent.removeMonitor(keyMonitor)
            }
        }

        func attach(_ window: NSWindow) {
            window.delegate = self
            apply(window)
            installKeys(for: window)
        }

        private func installKeys(for window: NSWindow) {
            guard parent.handlesKeys, keyMonitor == nil else { return }
            keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self, weak window] event in
                guard let self, let window else { return event }
                guard event.window === window else { return event }
                let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
                let blocked: NSEvent.ModifierFlags = [.command, .option, .control]
                if !flags.intersection(blocked).isEmpty {
                    return event
                }
                if event.keyCode == 49 {
                    if self.parent.isEditing {
                        return event
                    }
                    self.parent.onToggle()
                    return nil
                }
                if event.charactersIgnoringModifiers?.lowercased() == "r" {
                    if self.parent.isEditing {
                        return event
                    }
                    self.parent.onReset()
                    return nil
                }
                return event
            }
        }

        func apply(_ window: NSWindow) {
            window.identifier = NSUserInterfaceItemIdentifier(parent.role.rawValue)
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.isMovableByWindowBackground = true
            window.backgroundColor = NSColor(parent.background)
            let floating = parent.alwaysOnTop || parent.role != .main
            window.level = floating ? .floating : .normal
            if floating {
                window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            }
            if parent.placeBottomTrailing && !didPlace {
                didPlace = true
                if let screen = window.screen ?? NSScreen.main {
                    let visible = screen.visibleFrame
                    let size = window.frame.size
                    window.setFrameOrigin(NSPoint(
                        x: visible.maxX - size.width - 24,
                        y: visible.minY + 24
                    ))
                }
            }
        }

        func windowShouldClose(_ sender: NSWindow) -> Bool {
            switch parent.role {
            case .main:
                if parent.hideInsteadOfQuit {
                    sender.orderOut(nil)
                    parent.onHidden()
                    return false
                }
                if !Self.didRequestTerminate {
                    Self.didRequestTerminate = true
                    NSApp.terminate(nil)
                }
                return true
            case .mini, .timeUp:
                parent.onDismiss()
                return true
            }
        }

        func windowShouldMiniaturize(_ window: NSWindow) -> Bool {
            window.orderOut(nil)
            if parent.role == .main {
                parent.onHidden()
            } else {
                parent.onDismiss()
            }
            return false
        }
    }
}

private final class ConfigView: NSView {
    var onWindow: ((NSWindow) -> Void)?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if let window {
            onWindow?(window)
        }
    }
}
