import Foundation

extension TimeInterval {
    /// `H:MM:SS` (hours are not zero-padded so long walks stay readable).
    var formattedHMS: String {
        let total = Int(self.rounded())
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        return String(format: "%d:%02d:%02d", hours, minutes, seconds)
    }

    /// Readable duration, e.g. "1 hour 23 minutes".
    var formattedTime: String {
        let total = Int(self.rounded())
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60

        var parts: [String] = []
        if hours > 0 {
            parts.append("\(hours) hour" + (hours == 1 ? "" : "s"))
        }
        if minutes > 0 {
            parts.append("\(minutes) minute" + (minutes == 1 ? "" : "s"))
        }
        if parts.isEmpty || (hours == 0 && minutes == 0) {
            parts.append("\(seconds) second" + (seconds == 1 ? "" : "s"))
        }
        return parts.joined(separator: " ")
    }
}
