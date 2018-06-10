import Foundation

extension Date {
    
    static func utcDate(fromString dateString: String) -> Date?
    {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY-MM-dd'T'HH:mm:ss.SZ"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        return dateFormatter.date(from: dateString)
    }
    
    func toFormat(format: String) -> String?
    {
        
        let inputDF = DateFormatter()
        inputDF.dateFormat = "YYYY-MM-dd'T'HH:mm:ss.SZ"
        
        if let dateString = self.toString(),
            let date = inputDF.date(from: dateString) {
            let outputDF = DateFormatter()
            outputDF.dateFormat = format
            
            return outputDF.string(from: date)
        }
        
        return nil
    }
    
    static func from(date: String) -> Date
    {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        let date = dateFormatter.date(from: date)! // create   date from string
        return date
    }
    
    
    static func from(date dateStr: String, inFormat format: String) -> Date
    {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        dateFormatter.timeZone = TimeZone.current
        return dateFormatter.date(from: dateStr)!
    }
    
    func toString() -> String?
    {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY-MM-dd'T'HH:mm:ss.S"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        return dateFormatter.string(from: self) + "Z"
    }
    
    
    func toLocalDate() -> Date?
    {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY-MM-dd'T'HH:mm:ss.S"
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        let dateString = dateFormatter.string(from: self)
        return dateFormatter.date(from: dateString)
    }
    
    func isLesserThan(date: Date)  -> Bool
    {
        let result = self.compare(date)
        
        return result == .orderedAscending
    }
    
    func isGreaterThan(date: Date)  -> Bool
    {
        let result = self.compare(date)
        
        return result == .orderedDescending
    }
    
    func isEqual(date: Date) -> Bool
    {
        let result = self.compare(date)
        
        return result == .orderedSame
    }
    
    var millisecondsSince1970:Int
    {
        return Int((self.timeIntervalSince1970 * 1000.0).rounded())
    }
}
