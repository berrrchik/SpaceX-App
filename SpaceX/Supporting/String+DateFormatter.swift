import Foundation

extension String {
    func formatDate() -> String? {
        let dateFormatterGet = DateFormatter()
        dateFormatterGet.dateFormat = "yyyy-MM-dd"
        dateFormatterGet.timeZone = TimeZone(secondsFromGMT: 0)
        
        let dateFormatterPrint = DateFormatter()
        dateFormatterPrint.dateFormat = "dd MMMM, yyyy"
        dateFormatterPrint.locale = Locale(identifier: "ru_RU")
        
        let dateOnlyString = String(self.prefix(10))
        
        if let date = dateFormatterGet.date(from: dateOnlyString) {
            return dateFormatterPrint.string(from: date)
        } else {
            return nil
        }
    }
}
