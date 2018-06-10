import UIKit

extension UIColor {
    // MOCK THEME
    static let navigationBarColor = UIColor.rgb(red: 184, green: 188, blue: 191)
    static let majorTextColor = UIColor.rgb(red: 89, green: 89, blue: 89)
    static let secondaryTextColor = UIColor.rgb(red: 127, green: 127, blue: 127)
    static let hightLightColor = UIColor.rgb(red: 242, green: 101, blue: 50)
    static let veryLightGray = UIColor.rgb(red: 235, green: 235, blue: 235)
    
    static func rgb(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat = 1.0) -> UIColor
    {
        return UIColor(red: red/255, green: green/255, blue: blue/255, alpha: alpha)
    }
    
    public convenience init?(hexString: String)
    {
        let r, g, b, a: CGFloat
        
        if hexString.hasPrefix("#") {
            let start = hexString.index(hexString.startIndex, offsetBy: 1)
            let hexColor = String(hexString[start...])
            
            if hexColor.count == 8 {
                let scanner = Scanner(string: hexColor)
                var hexNumber: UInt64 = 0
                
                if scanner.scanHexInt64(&hexNumber) {
                    r = CGFloat((hexNumber & 0xff000000) >> 24) / 255
                    g = CGFloat((hexNumber & 0x00ff0000) >> 16) / 255
                    b = CGFloat((hexNumber & 0x0000ff00) >> 8) / 255
                    a = CGFloat(hexNumber & 0x000000ff) / 255
                    
                    self.init(red: r, green: g, blue: b, alpha: a)
                    return
                }
            }
        }
        
        return nil
    }
}
