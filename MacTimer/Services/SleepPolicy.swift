import Foundation

/// Sleep and resume policy for the countdown.
/// The timer measures progress with a monotonic clock that stops while the
/// Mac is suspended. On wake, the countdown continues from the remaining time
/// at the moment sleep began. Wall-clock time spent asleep is not subtracted
/// and is not added.
enum SleepPolicy {
    static let description = "System sleep pauses the countdown. The timer uses a monotonic clock that does not advance while the Mac is suspended, then continues from the remaining time on resume."

    struct SleepGap {
        var monotonicElapsed: TimeInterval
        var wallClockElapsed: TimeInterval
    }

    static func countedElapsed(_ gap: SleepGap) -> TimeInterval {
        max(0, gap.monotonicElapsed)
    }

    static func remainingAfterResume(remainingBeforeSleep: TimeInterval, monotonicElapsedDuringSleep: TimeInterval) -> TimeInterval {
        let elapsed = max(0, monotonicElapsedDuringSleep)
        return max(0, remainingBeforeSleep - elapsed)
    }
}
