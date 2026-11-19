import AppKit
import SwiftUI

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var status: TimerStatus = .idle
    @Published private(set) var displayTime = "00:25:00"
    @Published private(set) var ringProgress = 1.0
    @Published var hoursText = "00"
    @Published var minutesText = "25"
    @Published var secondsText = "00"
    @Published var settings: AppSettings
    @Published var presentTimeUp = false
    @Published var miniOpen = false
    @Published var editingTime = false

    let presets = [1, 5, 10, 15, 25, 30, 60]

    private let engine: TimerEngine
    private let settingsStore: SettingsStore
    private let alarm = AlarmPlayer()
    private let notifications = NotificationService()
    private var ticker: Timer?
    private var wakeObserver: NSObjectProtocol?
    private var didApplyLoginItem = false

    init(clock: any MonotonicClock = SuspendingClockAdapter(), settingsStore: SettingsStore = SettingsStore()) {
        self.settingsStore = settingsStore
        let loaded = settingsStore.load()
        settings = loaded
        let seconds = loaded.lastHours * 3600 + loaded.lastMinutes * 60 + loaded.lastSeconds
        let engine = try! TimerEngine(clock: clock, duration: TimeInterval(seconds))
        self.engine = engine
        engine.onCompleted = { [weak self] in
            Task { @MainActor in
                self?.handleCompleted()
            }
        }
        syncFieldsFromEngine()
        refresh()
        if !Self.isRunningTests {
            notifications.prepare()
            if loaded.launchOnStartup {
                LoginItemService.apply(true)
            }
        }
        didApplyLoginItem = true
        ensureTicker()
        observeWake()
    }

    var primaryTitle: String {
        switch status {
        case .running:
            return "Pause"
        case .paused:
            return "Resume"
        case .idle, .completed:
            return "Start"
        }
    }

    var statusTitle: String {
        switch status {
        case .idle:
            return "Ready"
        case .running:
            return "Running"
        case .paused:
            return "Paused"
        case .completed:
            return "Time's up"
        }
    }

    var menuBarTitle: String {
        status == .idle ? "Timer" : displayTime
    }

    var showsEditableTime: Bool {
        status == .idle || status == .completed
    }

    var canPrimary: Bool {
        status == .running || status == .paused || typedDuration > 0
    }

    var typedDuration: TimeInterval {
        let hours = min(max(Int(hoursText) ?? 0, 0), 99)
        let minutes = min(max(Int(minutesText) ?? 0, 0), 59)
        let seconds = min(max(Int(secondsText) ?? 0, 0), 59)
        return TimeInterval(hours * 3600 + minutes * 60 + seconds)
    }

    func colorScheme() -> ColorScheme? {
        switch settings.theme {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }

    func palette(for scheme: ColorScheme) -> Palette {
        switch settings.theme {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return scheme == .dark ? .dark : .light
        }
    }

    func toggle() {
        switch engine.currentStatus() {
        case .running:
            engine.pause()
        case .paused:
            _ = engine.tryStart()
        case .idle, .completed:
            normalizeFields()
            let duration = typedDuration
            guard duration > 0 else { return }
            _ = try? engine.setDuration(duration)
            guard engine.tryStart() else { return }
            rememberDuration()
        }
        refresh()
    }

    func startPreset(_ minutes: Int) {
        let hours = minutes / 60
        let remainder = minutes % 60
        hoursText = String(format: "%02d", hours)
        minutesText = String(format: "%02d", remainder)
        secondsText = "00"
        _ = try? engine.startDuration(TimeInterval(minutes * 60))
        rememberDuration()
        refresh()
    }

    func reset() {
        engine.reset()
        alarm.stop()
        presentTimeUp = false
        syncFieldsFromEngine()
        refresh()
    }

    func dismissAlert() {
        presentTimeUp = false
        alarm.stop()
    }

    func normalizeFields() {
        let hours = min(max(Int(hoursText.filter(\.isNumber)) ?? 0, 0), 99)
        let minutes = min(max(Int(minutesText.filter(\.isNumber)) ?? 0, 0), 59)
        let seconds = min(max(Int(secondsText.filter(\.isNumber)) ?? 0, 0), 59)
        hoursText = String(format: "%02d", hours)
        minutesText = String(format: "%02d", minutes)
        secondsText = String(format: "%02d", seconds)
    }

    func updateSettings(_ body: (inout AppSettings) -> Void) {
        let previousLaunch = settings.launchOnStartup
        var next = settings
        body(&next)
        settings = SettingsStore.normalize(next)
        do {
            try settingsStore.save(settings)
        } catch {
            AppLog.warn("Settings could not be saved. \(type(of: error))")
        }
        if didApplyLoginItem && settings.launchOnStartup != previousLaunch {
            LoginItemService.apply(settings.launchOnStartup)
        }
    }

    func previewSound() {
        alarm.preview(sound: settings.alertSound, volume: settings.volume)
    }

    func noteHiddenToMenuBar() {
        guard !settings.hasSeenMenuBarHint else { return }
        updateSettings { $0.hasSeenMenuBarHint = true }
        notifications.notifyMenuBarHint()
    }

    func reveal(role: WindowRole) {
        NSApp.activate()
        let window = NSApp.windows.first { candidate in
            if candidate.identifier?.rawValue == role.rawValue {
                return true
            }
            switch role {
            case .main:
                return candidate.title.hasPrefix("Timer")
            case .mini:
                return candidate.title == "Mini Timer"
            case .timeUp:
                return candidate.title == "Time's Up"
            }
        }
        window?.makeKeyAndOrderFront(nil)
    }

    private func handleCompleted() {
        refresh()
        presentTimeUp = true
        alarm.play(
            sound: settings.alertSound,
            volume: settings.volume,
            muted: settings.mute,
            repeating: settings.repeatUntilDismissed
        )
        notifications.notifyTimeUp()
    }

    private func refresh() {
        let remaining = engine.currentRemaining()
        let duration = engine.currentDuration()
        status = engine.currentStatus()
        displayTime = TimeFormat.formatRemaining(remaining)
        ringProgress = duration <= 0 ? 0 : remaining / duration
        let title = status == .idle ? "Timer" : "Timer \(displayTime)"
        if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == WindowRole.main.rawValue }) {
            window.title = title
        }
    }

    private func syncFieldsFromEngine() {
        let total = Int(engine.currentDuration().rounded(.down))
        hoursText = String(format: "%02d", total / 3600)
        minutesText = String(format: "%02d", (total % 3600) / 60)
        secondsText = String(format: "%02d", total % 60)
    }

    private func rememberDuration() {
        let total = Int(engine.currentDuration().rounded(.down))
        updateSettings {
            $0.lastHours = total / 3600
            $0.lastMinutes = (total % 3600) / 60
            $0.lastSeconds = total % 60
        }
    }

    private static var isRunningTests: Bool {
        let environment = ProcessInfo.processInfo.environment
        if environment["XCTestConfigurationFilePath"] != nil || environment["XCTestSessionIdentifier"] != nil {
            return true
        }
        return ProcessInfo.processInfo.arguments.contains { $0.contains("XCTest") }
    }

    private func ensureTicker() {
        guard ticker == nil else { return }
        let timer = Timer(timeInterval: 0.1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.engine.tick()
                self?.refresh()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        ticker = timer
    }

    private func observeWake() {
        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.engine.tick()
                self?.refresh()
            }
        }
    }
}

enum WindowRole: String {
    case main
    case mini
    case timeUp
}
