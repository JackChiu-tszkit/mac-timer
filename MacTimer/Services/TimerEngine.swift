import Foundation

enum TimerInputError: Error, Equatable {
    case negativeDuration
}

/// Countdown engine. Remaining time is derived from a monotonic clock,
/// not from counting UI ticks. Completion is raised at most once per run.
final class TimerEngine {
    static let maxDuration: TimeInterval = 99 * 3600 + 59 * 60 + 59

    private let lock = NSLock()
    private let clock: any MonotonicClock
    private var duration: TimeInterval
    private var elapsedBeforeSegment: TimeInterval = 0
    private var segmentStart: TimeInterval = 0
    private var status: TimerStatus = .idle
    private var completionRaised = false

    var onCompleted: (() -> Void)?
    var onStateChanged: (() -> Void)?

    init(clock: any MonotonicClock, duration: TimeInterval = 25 * 60) throws {
        if duration < 0 {
            throw TimerInputError.negativeDuration
        }
        self.clock = clock
        self.duration = min(duration, Self.maxDuration)
    }

    func currentStatus() -> TimerStatus {
        lock.lock()
        defer { lock.unlock() }
        return status
    }

    func currentDuration() -> TimeInterval {
        lock.lock()
        defer { lock.unlock() }
        return duration
    }

    func currentElapsed() -> TimeInterval {
        lock.lock()
        defer { lock.unlock() }
        return elapsedUnlocked()
    }

    func currentRemaining() -> TimeInterval {
        lock.lock()
        defer { lock.unlock() }
        return remainingUnlocked()
    }

    @discardableResult
    func setDuration(_ duration: TimeInterval) throws -> Bool {
        try validate(duration)
        lock.lock()
        if status == .running {
            lock.unlock()
            return false
        }
        self.duration = min(duration, Self.maxDuration)
        elapsedBeforeSegment = 0
        completionRaised = false
        status = .idle
        lock.unlock()
        onStateChanged?()
        return true
    }

    @discardableResult
    func tryStart() -> Bool {
        lock.lock()
        if status == .running {
            lock.unlock()
            return true
        }
        if duration <= 0 {
            lock.unlock()
            return false
        }
        if status == .idle || status == .completed {
            elapsedBeforeSegment = 0
            completionRaised = false
        }
        segmentStart = clock.timestamp()
        status = .running
        lock.unlock()
        onStateChanged?()
        return true
    }

    @discardableResult
    func startDuration(_ duration: TimeInterval) throws -> Bool {
        try validate(duration)
        if duration <= 0 {
            lock.lock()
            self.duration = 0
            elapsedBeforeSegment = 0
            completionRaised = false
            status = .idle
            lock.unlock()
            onStateChanged?()
            return false
        }

        lock.lock()
        self.duration = min(duration, Self.maxDuration)
        elapsedBeforeSegment = 0
        completionRaised = false
        segmentStart = clock.timestamp()
        status = .running
        lock.unlock()
        onStateChanged?()
        return true
    }

    func pause() {
        var completed = false
        var changed = false
        lock.lock()
        if status != .running {
            lock.unlock()
            return
        }
        elapsedBeforeSegment += clock.elapsed(since: segmentStart)
        if elapsedBeforeSegment >= duration {
            completed = completeUnlocked()
        } else {
            status = .paused
            changed = true
        }
        lock.unlock()

        if completed {
            notifyCompleted()
        } else if changed {
            onStateChanged?()
        }
    }

    func reset() {
        lock.lock()
        elapsedBeforeSegment = 0
        completionRaised = false
        status = .idle
        lock.unlock()
        onStateChanged?()
    }

    func cancel() {
        reset()
    }

    func tick() {
        lock.lock()
        let completed = status == .running && elapsedUnlocked() >= duration ? completeUnlocked() : false
        lock.unlock()
        if completed {
            notifyCompleted()
        }
    }

    private func validate(_ duration: TimeInterval) throws {
        if duration < 0 {
            throw TimerInputError.negativeDuration
        }
    }

    private func elapsedUnlocked() -> TimeInterval {
        var elapsed = elapsedBeforeSegment
        if status == .running {
            elapsed += clock.elapsed(since: segmentStart)
        }
        if elapsed < 0 {
            return 0
        }
        if elapsed > duration {
            return duration
        }
        return elapsed
    }

    private func remainingUnlocked() -> TimeInterval {
        max(0, duration - elapsedUnlocked())
    }

    private func completeUnlocked() -> Bool {
        if completionRaised {
            return false
        }
        elapsedBeforeSegment = duration
        status = .completed
        completionRaised = true
        return true
    }

    private func notifyCompleted() {
        onStateChanged?()
        onCompleted?()
    }
}
