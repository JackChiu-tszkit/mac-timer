import Foundation

/// A clock that never moves backwards and does not follow wall-clock changes.
protocol MonotonicClock: AnyObject {
    func timestamp() -> TimeInterval
    func elapsed(since timestamp: TimeInterval) -> TimeInterval
}

/// Matches the Windows timer: system sleep pauses the countdown.
/// `SuspendingClock` does not advance while the Mac is suspended.
final class SuspendingClockAdapter: MonotonicClock {
    private let clock = SuspendingClock()
    private let origin: SuspendingClock.Instant

    init() {
        origin = clock.now
    }

    func timestamp() -> TimeInterval {
        seconds(from: origin.duration(to: clock.now))
    }

    func elapsed(since timestamp: TimeInterval) -> TimeInterval {
        self.timestamp() - timestamp
    }

    private func seconds(from duration: Duration) -> TimeInterval {
        let parts = duration.components
        return TimeInterval(parts.seconds) + TimeInterval(parts.attoseconds) / 1e18
    }
}
