import Foundation

enum TimerStatus: String, Equatable {
    case idle
    case running
    case paused
    case completed
}

enum ThemePreference: String, Codable, CaseIterable, Equatable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"

    var title: String { rawValue }
}

enum AlertSoundId: String, Codable, CaseIterable, Equatable {
    case bell = "Bell"
    case chime = "Chime"
    case soft = "Soft"

    var title: String { rawValue }
}

enum CloseBehavior: String, Codable, CaseIterable, Equatable {
    case quit = "Quit"
    case hideToMenuBar = "HideToMenuBar"

    var title: String {
        switch self {
        case .quit:
            return "Quit"
        case .hideToMenuBar:
            return "Hide in Menu Bar"
        }
    }
}

struct AppSettings: Codable, Equatable {
    var theme: ThemePreference = .system
    var alertSound: AlertSoundId = .bell
    var volume: Double = 0.4
    var mute: Bool = false
    var repeatUntilDismissed: Bool = false
    var alwaysOnTop: Bool = false
    var closeBehavior: CloseBehavior = .quit
    var launchOnStartup: Bool = false
    var hasSeenMenuBarHint: Bool = false
    var lastHours: Int = 0
    var lastMinutes: Int = 25
    var lastSeconds: Int = 0

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        theme = try container.decodeIfPresent(ThemePreference.self, forKey: .theme) ?? .system
        alertSound = try container.decodeIfPresent(AlertSoundId.self, forKey: .alertSound) ?? .bell
        volume = try container.decodeIfPresent(Double.self, forKey: .volume) ?? 0.4
        mute = try container.decodeIfPresent(Bool.self, forKey: .mute) ?? false
        repeatUntilDismissed = try container.decodeIfPresent(Bool.self, forKey: .repeatUntilDismissed) ?? false
        alwaysOnTop = try container.decodeIfPresent(Bool.self, forKey: .alwaysOnTop) ?? false
        closeBehavior = try container.decodeIfPresent(CloseBehavior.self, forKey: .closeBehavior) ?? .quit
        launchOnStartup = try container.decodeIfPresent(Bool.self, forKey: .launchOnStartup) ?? false
        hasSeenMenuBarHint = try container.decodeIfPresent(Bool.self, forKey: .hasSeenMenuBarHint) ?? false
        lastHours = try container.decodeIfPresent(Int.self, forKey: .lastHours) ?? 0
        lastMinutes = try container.decodeIfPresent(Int.self, forKey: .lastMinutes) ?? 25
        lastSeconds = try container.decodeIfPresent(Int.self, forKey: .lastSeconds) ?? 0
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(theme, forKey: .theme)
        try container.encode(alertSound, forKey: .alertSound)
        try container.encode(volume, forKey: .volume)
        try container.encode(mute, forKey: .mute)
        try container.encode(repeatUntilDismissed, forKey: .repeatUntilDismissed)
        try container.encode(alwaysOnTop, forKey: .alwaysOnTop)
        try container.encode(closeBehavior, forKey: .closeBehavior)
        try container.encode(launchOnStartup, forKey: .launchOnStartup)
        try container.encode(hasSeenMenuBarHint, forKey: .hasSeenMenuBarHint)
        try container.encode(lastHours, forKey: .lastHours)
        try container.encode(lastMinutes, forKey: .lastMinutes)
        try container.encode(lastSeconds, forKey: .lastSeconds)
    }

    private enum CodingKeys: String, CodingKey {
        case theme
        case alertSound
        case volume
        case mute
        case repeatUntilDismissed
        case alwaysOnTop
        case closeBehavior
        case launchOnStartup
        case hasSeenMenuBarHint
        case lastHours
        case lastMinutes
        case lastSeconds
    }
}
