import Foundation

extension String {
    // Converts the JSON string to specified Model object
    func fromJsonString<T : Decodable>(to type: T.Type) throws -> T {
        guard let jsonData = self.data(using: .utf8) else { return T.self as! T }
        return try JSONDecoder().decode(T.self, from: jsonData)
    }
}
