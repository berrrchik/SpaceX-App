import Foundation

extension String {
    private static let inputFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()

    private static let outputFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMMM, yyyy"
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter
    }()

    func formatDate() -> String? {
        let dateOnlyString = String(self.prefix(10))
        
        if let date = Self.inputFormatter.date(from: dateOnlyString) {
            return Self.outputFormatter.string(from: date)
        } else {
            return nil
        }
    }
}
