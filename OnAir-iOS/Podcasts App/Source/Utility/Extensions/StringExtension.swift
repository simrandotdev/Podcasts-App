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
    
    /// Readable plain text from show-notes HTML: keeps paragraph and line breaks, turns list items
    /// into bullets, decodes common entities, and collapses runs of whitespace.
    func htmlToPlainText() -> String {
        var text = self
        func replace(_ pattern: String, with template: String) {
            text = text.replacingOccurrences(of: pattern, with: template, options: [.regularExpression, .caseInsensitive])
        }
        // In HTML, source line breaks are just formatting; in plain-text notes they are the paragraphs.
        let isHTML = range(of: "<(p|br|div|li|ul|ol|h[1-6])[\\s>/]", options: [.regularExpression, .caseInsensitive]) != nil
        if isHTML { replace("\\s*\\n\\s*", with: " ") }
        replace("<br\\s*/?>", with: "\n")
        replace("<li[^>]*>", with: "\n• ")
        replace("</(p|div|h[1-6]|ul|ol|blockquote)>", with: "\n\n")
        replace("<[^>]+>", with: "")
        text = Self.decodingEntities(in: text)
        replace("[ \\t\u{00A0}]+", with: " ")
        replace(" *\n *", with: "\n")
        replace("\n{3,}", with: "\n\n")
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func decodingEntities(in text: String) -> String {
        var result = text
        // Numeric entities: &#8217; and &#x2019;
        let numeric = try! NSRegularExpression(pattern: "&#(x[0-9a-f]+|[0-9]+);", options: .caseInsensitive)
        for match in numeric.matches(in: result, range: NSRange(result.startIndex..., in: result)).reversed() {
            guard let range = Range(match.range, in: result),
                  let valueRange = Range(match.range(at: 1), in: result) else { continue }
            let value = result[valueRange]
            let code = value.lowercased().hasPrefix("x") ? UInt32(value.dropFirst(), radix: 16) : UInt32(value)
            if let code, let scalar = Unicode.Scalar(code) {
                result.replaceSubrange(range, with: String(Character(scalar)))
            }
        }
        let named = ["&nbsp;": " ", "&lt;": "<", "&gt;": ">", "&quot;": "\"", "&#39;": "'", "&apos;": "'",
                     "&rsquo;": "\u{2019}", "&lsquo;": "\u{2018}", "&rdquo;": "\u{201D}", "&ldquo;": "\u{201C}",
                     "&ndash;": "\u{2013}", "&mdash;": "\u{2014}", "&hellip;": "\u{2026}"]
        for (entity, character) in named {
            result = result.replacingOccurrences(of: entity, with: character, options: .caseInsensitive)
        }
        // Last, so "&amp;lt;" becomes the literal text "&lt;" rather than "<".
        return result.replacingOccurrences(of: "&amp;", with: "&", options: .caseInsensitive)
    }

    func trimingLeadingSpaces(using characterSet: CharacterSet = .whitespacesAndNewlines) -> String {
        guard let index = firstIndex(where: { !CharacterSet(charactersIn: String($0)).isSubset(of: characterSet) }) else {
            return self
        }
        
        return String(self[index...])
    }
}
