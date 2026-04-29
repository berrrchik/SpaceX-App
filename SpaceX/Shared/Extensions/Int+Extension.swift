import Foundation

extension Int {
    
    var roundedWithAbbreviations: String {
        let number = Double(self)
        let million = number / 1000000
        
        if million >= 1.0 {
            return "$\(Int(round(million*10)/10)) млн"
        } else {
            return "\(self)"
        }
    }
}
