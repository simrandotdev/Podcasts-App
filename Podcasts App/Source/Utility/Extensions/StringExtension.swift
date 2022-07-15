import Foundation

extension String {
    // Converts the JSON string to specified Model object
    func fromJsonString<T : Decodable>(to type: T.Type) throws -> T {
        guard let jsonData = self.data(using: .utf8) else { return T.self as! T }
        return try JSONDecoder().decode(T.self, from: jsonData)
    }
    
    func removeHtmlTags() -> String {
        let str = self.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
        return str
    }
    
    func trimingLeadingSpaces(using characterSet: CharacterSet = .whitespacesAndNewlines) -> String {
        guard let index = firstIndex(where: { !CharacterSet(charactersIn: String($0)).isSubset(of: characterSet) }) else {
            return self
        }
        
        return String(self[index...])
    }
}
