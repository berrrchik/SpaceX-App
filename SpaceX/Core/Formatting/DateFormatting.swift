import Foundation

protocol DateFormatting {
    func format(_ dateString: String) -> String
}

final class DefaultDateFormatter: DateFormatting {
    private let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
    
    private let displayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM, yyyy"
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter
    }()
    
    func format(_ dateString: String) -> String {
        if let date = formatter.date(from: dateString) {
            return displayFormatter.string(from: date)
        }

        // Backward compatibility: domain may already contain formatted date.
        let trimmed = dateString.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "-" : trimmed
    }
}
