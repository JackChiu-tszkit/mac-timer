import Foundation

enum AppPaths {
    static var supportDirectory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        return base.appendingPathComponent("Timer", isDirectory: true)
    }

    static var settingsURL: URL {
        supportDirectory.appendingPathComponent("settings.json")
    }

    static var logURL: URL {
        supportDirectory.appendingPathComponent("logs", isDirectory: true).appendingPathComponent("timer.log")
    }
}

enum AppLog {
    static func warn(_ message: String) {
        let url = AppPaths.logURL
        let folder = url.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let stamp = ISO8601DateFormatter().string(from: Date())
        let line = "\(stamp) WARN \(message)\n"
        if let existing = try? String(contentsOf: url, encoding: .utf8) {
            try? (existing + line).write(to: url, atomically: true, encoding: .utf8)
        } else {
            try? line.write(to: url, atomically: true, encoding: .utf8)
        }
    }
}

final class SettingsStore {
    private let settingsURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(settingsURL: URL? = nil) {
        self.settingsURL = settingsURL ?? AppPaths.settingsURL
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder = encoder
        let decoder = JSONDecoder()
        self.decoder = decoder
    }

    func load() -> AppSettings {
        do {
            guard FileManager.default.fileExists(atPath: settingsURL.path) else {
                return AppSettings()
            }
            let data = try Data(contentsOf: settingsURL)
            if data.isEmpty {
                return AppSettings()
            }
            let settings = try decoder.decode(AppSettings.self, from: data)
            return Self.normalize(settings)
        } catch {
            AppLog.warn("Settings could not be read. Defaults will be used. \(type(of: error))")
            return AppSettings()
        }
    }

    func save(_ settings: AppSettings) throws {
        let normalized = Self.normalize(settings)
        let folder = settingsURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let data = try encoder.encode(normalized)
        let temporary = settingsURL.appendingPathExtension("tmp")
        try data.write(to: temporary, options: .atomic)
        if FileManager.default.fileExists(atPath: settingsURL.path) {
            _ = try FileManager.default.replaceItemAt(settingsURL, withItemAt: temporary)
        } else {
            try FileManager.default.moveItem(at: temporary, to: settingsURL)
        }
    }

    static func normalize(_ settings: AppSettings) -> AppSettings {
        var copy = settings
        if copy.volume.isFinite {
            copy.volume = min(max(copy.volume, 0), 1)
        } else {
            copy.volume = 0.4
        }
        copy.lastHours = min(max(copy.lastHours, 0), 99)
        copy.lastMinutes = min(max(copy.lastMinutes, 0), 59)
        copy.lastSeconds = min(max(copy.lastSeconds, 0), 59)
        return copy
    }
}
