import XCTest
@testable import MacTimer

final class SettingsStoreTests: XCTestCase {
    func testSaveAndLoadRoundTripsSettings() throws {
        let folder = temporaryFolder()
        let url = folder.appendingPathComponent("settings.json")
        let store = SettingsStore(settingsURL: url)
        var settings = AppSettings()
        settings.theme = .dark
        settings.alertSound = .soft
        settings.volume = 0.35
        settings.mute = true
        settings.repeatUntilDismissed = true
        settings.alwaysOnTop = true
        settings.closeBehavior = .hideToMenuBar
        settings.launchOnStartup = true
        settings.hasSeenMenuBarHint = true
        settings.lastHours = 1
        settings.lastMinutes = 5
        settings.lastSeconds = 9

        try store.save(settings)
        let loaded = store.load()

        XCTAssertEqual(loaded.theme, .dark)
        XCTAssertEqual(loaded.alertSound, .soft)
        XCTAssertEqual(loaded.volume, 0.35, accuracy: 0.001)
        XCTAssertTrue(loaded.mute)
        XCTAssertTrue(loaded.repeatUntilDismissed)
        XCTAssertTrue(loaded.alwaysOnTop)
        XCTAssertEqual(loaded.closeBehavior, .hideToMenuBar)
        XCTAssertTrue(loaded.launchOnStartup)
        XCTAssertTrue(loaded.hasSeenMenuBarHint)
        XCTAssertEqual(loaded.lastHours, 1)
        XCTAssertEqual(loaded.lastMinutes, 5)
        XCTAssertEqual(loaded.lastSeconds, 9)
        let json = try String(contentsOf: url, encoding: .utf8)
        XCTAssertTrue(json.contains("Dark"))
        XCTAssertTrue(json.contains("theme"))
    }

    func testMissingFileReturnsDefaults() {
        let url = temporaryFolder().appendingPathComponent("missing.json")
        let settings = SettingsStore(settingsURL: url).load()

        XCTAssertEqual(settings.theme, .system)
        XCTAssertEqual(settings.alertSound, .bell)
        XCTAssertEqual(settings.volume, 0.4, accuracy: 0.001)
        XCTAssertFalse(settings.mute)
        XCTAssertEqual(settings.closeBehavior, .quit)
        XCTAssertEqual(settings.lastMinutes, 25)
    }

    func testCorruptFileReturnsDefaults() throws {
        let url = temporaryFolder().appendingPathComponent("settings.json")
        try "{ this is not json".write(to: url, atomically: true, encoding: .utf8)

        let settings = SettingsStore(settingsURL: url).load()

        XCTAssertEqual(settings.theme, .system)
        XCTAssertEqual(settings.lastMinutes, 25)
    }

    func testOutOfRangeValuesAreClamped() throws {
        let url = temporaryFolder().appendingPathComponent("settings.json")
        let json = """
        {
          "volume": 9,
          "lastHours": 400,
          "lastMinutes": -5,
          "lastSeconds": 80,
          "theme": "Dark"
        }
        """
        try json.write(to: url, atomically: true, encoding: .utf8)

        let settings = SettingsStore(settingsURL: url).load()

        XCTAssertEqual(settings.volume, 1, accuracy: 0.001)
        XCTAssertEqual(settings.lastHours, 99)
        XCTAssertEqual(settings.lastMinutes, 0)
        XCTAssertEqual(settings.lastSeconds, 59)
        XCTAssertEqual(settings.theme, .dark)
    }

    private func temporaryFolder() -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacTimerTests", isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}

final class TimeFormatTests: XCTestCase {
    func testFormatRemainingRoundsUpPartialSeconds() {
        XCTAssertEqual(TimeFormat.formatRemaining(0), "00:00:00")
        XCTAssertEqual(TimeFormat.formatRemaining(0.1), "00:00:01")
        XCTAssertEqual(TimeFormat.formatRemaining(1), "00:00:01")
        XCTAssertEqual(TimeFormat.formatRemaining(61), "00:01:01")
        XCTAssertEqual(TimeFormat.formatRemaining(3600), "01:00:00")
        XCTAssertEqual(TimeFormat.formatRemaining(26 * 3600), "26:00:00")
    }
}

final class ToneLibraryTests: XCTestCase {
    func testCreateWavProducesLocalAudio() {
        for id in [AlertSoundId.bell, .chime, .soft] {
            let wav = ToneLibrary.createWav(id: id, volume: 0.4)
            XCTAssertGreaterThan(wav.count, 44)
            XCTAssertEqual(wav[0], UInt8(ascii: "R"))
            XCTAssertEqual(wav[1], UInt8(ascii: "I"))
            XCTAssertEqual(wav[2], UInt8(ascii: "F"))
            XCTAssertEqual(wav[3], UInt8(ascii: "F"))
            XCTAssertTrue(wav.dropFirst(44).contains { $0 != 0 })
        }
    }

    func testSoundsAreDistinctAndSilenceStaysSilent() {
        let bell = ToneLibrary.createWav(id: .bell, volume: 0.4)
        let chime = ToneLibrary.createWav(id: .chime, volume: 0.4)
        let silent = ToneLibrary.createWav(id: .bell, volume: 0)

        XCTAssertNotEqual(bell.count, chime.count)
        XCTAssertTrue(silent.dropFirst(44).allSatisfy { $0 == 0 })
    }
}

final class SleepPolicyTests: XCTestCase {
    func testWallClockGapIsNotCounted() {
        let counted = SleepPolicy.countedElapsed(SleepPolicy.SleepGap(
            monotonicElapsed: 0,
            wallClockElapsed: 2 * 3600
        ))

        XCTAssertEqual(counted, 0)
        XCTAssertEqual(
            SleepPolicy.remainingAfterResume(remainingBeforeSleep: 20 * 60, monotonicElapsedDuringSleep: counted),
            20 * 60
        )
    }

    func testMonotonicElapsedDuringSleepStillCounts() {
        let remaining = SleepPolicy.remainingAfterResume(remainingBeforeSleep: 10 * 60, monotonicElapsedDuringSleep: 3 * 60)
        XCTAssertEqual(remaining, 7 * 60)
    }
}
