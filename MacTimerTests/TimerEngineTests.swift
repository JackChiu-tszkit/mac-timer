import XCTest
@testable import MacTimer

final class TimerEngineTests: XCTestCase {
    func testNewTimerUsesInitialDurationAndIdleState() throws {
        let engine = try TimerEngine(clock: FakeClock(), duration: 25 * 60)

        XCTAssertEqual(engine.currentStatus(), .idle)
        XCTAssertEqual(engine.currentDuration(), 25 * 60)
        XCTAssertEqual(engine.currentRemaining(), 25 * 60)
        XCTAssertEqual(engine.currentElapsed(), 0)
    }

    func testStartPauseResumeTracksOnlyRunningTime() throws {
        let clock = FakeClock()
        let engine = try TimerEngine(clock: clock, duration: 60)

        XCTAssertTrue(engine.tryStart())
        clock.advance(10)
        engine.pause()
        clock.advance(30)

        XCTAssertEqual(engine.currentStatus(), .paused)
        near(50, engine.currentRemaining())

        XCTAssertTrue(engine.tryStart())
        clock.advance(5)

        XCTAssertEqual(engine.currentStatus(), .running)
        near(45, engine.currentRemaining())
    }

    func testResetClearsElapsedWithoutChangingDuration() throws {
        let clock = FakeClock()
        let engine = try TimerEngine(clock: clock, duration: 10 * 60)
        engine.tryStart()
        clock.advance(3 * 60)

        engine.reset()
        clock.advance(4 * 60)

        XCTAssertEqual(engine.currentStatus(), .idle)
        XCTAssertEqual(engine.currentRemaining(), 10 * 60)
        XCTAssertEqual(engine.currentElapsed(), 0)
    }

    func testCancelMatchesReset() throws {
        let clock = FakeClock()
        let engine = try TimerEngine(clock: clock, duration: 30)
        engine.tryStart()
        clock.advance(8)

        engine.cancel()

        XCTAssertEqual(engine.currentStatus(), .idle)
        XCTAssertEqual(engine.currentRemaining(), 30)
    }

    func testZeroDurationDoesNotStartOrComplete() throws {
        let engine = try TimerEngine(clock: FakeClock(), duration: 0)
        var completions = 0
        engine.onCompleted = { completions += 1 }

        XCTAssertFalse(engine.tryStart())
        engine.tick()

        XCTAssertEqual(engine.currentStatus(), .idle)
        XCTAssertEqual(completions, 0)
        XCTAssertFalse(try engine.startDuration(0))
        XCTAssertEqual(completions, 0)
    }

    func testCompletionFiresExactlyOnce() throws {
        let clock = FakeClock()
        let engine = try TimerEngine(clock: clock, duration: 5)
        var completions = 0
        engine.onCompleted = { completions += 1 }

        engine.tryStart()
        clock.advance(5)
        engine.tick()
        clock.advance(10)
        for _ in 0..<20 {
            engine.tick()
        }

        XCTAssertEqual(completions, 1)
        XCTAssertEqual(engine.currentStatus(), .completed)
        XCTAssertEqual(engine.currentRemaining(), 0)
    }

    func testRepeatedStartDoesNotResetProgress() throws {
        let clock = FakeClock()
        let engine = try TimerEngine(clock: clock, duration: 30)
        var completions = 0
        engine.onCompleted = { completions += 1 }

        XCTAssertTrue(engine.tryStart())
        clock.advance(4)
        XCTAssertTrue(engine.tryStart())
        XCTAssertTrue(engine.tryStart())
        clock.advance(4)

        XCTAssertEqual(engine.currentStatus(), .running)
        near(8, engine.currentElapsed())
        XCTAssertEqual(completions, 0)
    }

    func testRepeatedPauseAndResetAreStable() throws {
        let engine = try TimerEngine(clock: FakeClock(), duration: 15)
        engine.pause()
        engine.pause()
        engine.reset()
        engine.reset()
        engine.cancel()

        XCTAssertEqual(engine.currentStatus(), .idle)
        XCTAssertEqual(engine.currentRemaining(), 15)
    }

    func testLongCountdownUsesElapsedTime() throws {
        let clock = FakeClock()
        let engine = try TimerEngine(clock: clock, duration: 99 * 3600)
        engine.tryStart()
        clock.advance(2 * 3600)

        near(97 * 3600, engine.currentRemaining())
    }

    func testVeryShortDurationCompletesOnce() throws {
        let clock = FakeClock()
        let engine = try TimerEngine(clock: clock, duration: 0.001)
        var completions = 0
        engine.onCompleted = { completions += 1 }

        engine.tryStart()
        clock.advance(0.002)
        engine.tick()
        engine.tick()

        XCTAssertEqual(completions, 1)
        XCTAssertEqual(engine.currentStatus(), .completed)
    }

    func testPauseAtExactEndCompletesOnce() throws {
        let clock = FakeClock()
        let engine = try TimerEngine(clock: clock, duration: 3)
        var completions = 0
        engine.onCompleted = { completions += 1 }
        engine.tryStart()
        clock.advance(3)

        engine.pause()
        engine.pause()
        engine.tick()

        XCTAssertEqual(completions, 1)
        XCTAssertEqual(engine.currentStatus(), .completed)
    }

    func testNegativeDurationIsRejected() throws {
        let engine = try TimerEngine(clock: FakeClock())
        XCTAssertThrowsError(try engine.setDuration(-1))
    }

    func testSetDurationWhileRunningDoesNotChangeTheActiveTimer() throws {
        let clock = FakeClock()
        let engine = try TimerEngine(clock: clock, duration: 10 * 60)
        engine.tryStart()
        clock.advance(60)

        XCTAssertFalse(try engine.setDuration(2 * 60))
        XCTAssertEqual(engine.currentStatus(), .running)
        XCTAssertEqual(engine.currentDuration(), 10 * 60)
    }

    func testDurationAboveMaximumIsClamped() throws {
        let engine = try TimerEngine(clock: FakeClock())
        XCTAssertTrue(try engine.setDuration(200 * 3600))
        XCTAssertEqual(engine.currentDuration(), TimerEngine.maxDuration)
    }

    func testSleepDoesNotConsumeRemainingTime() throws {
        let clock = FakeClock()
        let engine = try TimerEngine(clock: clock, duration: 25 * 60)
        engine.tryStart()
        clock.advance(5 * 60)
        let beforeSleep = engine.currentRemaining()

        let counted = SleepPolicy.countedElapsed(SleepPolicy.SleepGap(
            monotonicElapsed: 0,
            wallClockElapsed: 30 * 60
        ))

        XCTAssertEqual(counted, 0)
        XCTAssertEqual(beforeSleep, engine.currentRemaining())
        XCTAssertEqual(beforeSleep, SleepPolicy.remainingAfterResume(
            remainingBeforeSleep: beforeSleep,
            monotonicElapsedDuringSleep: counted
        ))
    }

    func testRestartAfterCompletionRunsAgain() throws {
        let clock = FakeClock()
        let engine = try TimerEngine(clock: clock, duration: 2)
        var completions = 0
        engine.onCompleted = { completions += 1 }
        engine.tryStart()
        clock.advance(2)
        engine.tick()

        XCTAssertTrue(engine.tryStart())
        XCTAssertEqual(engine.currentStatus(), .running)
        near(2, engine.currentRemaining())

        clock.advance(2)
        engine.tick()

        XCTAssertEqual(completions, 2)
    }

    func testSuspendingClockStartsAtZero() {
        let clock = SuspendingClockAdapter()
        XCTAssertGreaterThanOrEqual(clock.timestamp(), 0)
        XCTAssertLessThan(clock.timestamp(), 5)
    }

    private func near(_ expected: TimeInterval, _ actual: TimeInterval, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertLessThanOrEqual(abs(expected - actual), 0.02, "Expected \(expected) but was \(actual).", file: file, line: line)
    }
}

private final class FakeClock: MonotonicClock {
    private var now: TimeInterval = 0

    func advance(_ interval: TimeInterval) {
        now += interval
    }

    func timestamp() -> TimeInterval {
        now
    }

    func elapsed(since timestamp: TimeInterval) -> TimeInterval {
        now - timestamp
    }
}
