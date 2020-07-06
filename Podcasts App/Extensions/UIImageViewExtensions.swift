import UIKit

extension UIImageView {
    static func imageFromFirstCharacter(ofString inputString: String,
                                        withPlaceholderImage placeHolder: UIImage) -> UIImage {
        if let firstChacter = inputString.lowercased().first {
            return UIImage(named: "\(firstChacter)") ?? placeHolder
        }
        return placeHolder
    }
}
