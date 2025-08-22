import Foundation

struct LaunchElement: Codable {
    let name: String
    let dateUtc: String
    let success: Bool?
    let rocket: String
    
    var getDateUTC: String {
        let dateFormatterGet = DateFormatter()
        dateFormatterGet.dateFormat = "yyyy-MM-dd"
        
        let dateFormatterPrint = DateFormatter()
        dateFormatterPrint.dateFormat = "dd MMM, yyyy"
        
        if let date = dateFormatterGet.date(from: String(dateUtc.prefix(10))) {
            return dateFormatterPrint.string(from: date)
        } else {
            return "-"
        }
    }
}
