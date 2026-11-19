import Foundation

enum TimeFormat {
    static func formatRemaining(_ remaining: TimeInterval) -> String {
        let safe = max(0, remaining)
        let seconds: Int
        if safe == 0 {
            seconds = 0
        } else {
            seconds = Int(ceil(safe - 0.000001))
        }

        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, secs)
    }

    static func formatParts(hours: Int, minutes: Int, seconds: Int) -> String {
        let h = min(max(hours, 0), 99)
        let m = min(max(minutes, 0), 59)
        let s = min(max(seconds, 0), 59)
        return String(format: "%02d:%02d:%02d", h, m, s)
    }
}
