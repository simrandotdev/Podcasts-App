//
//  EmptyView.swift
//  Podcasts App
//
//  Created by Simran Preet Narang on 4/11/21.
//  Copyright © 2021 Simran App. All rights reserved.
//

import UIKit

class EmptyView: UIView {
    override func draw(_ rect: CGRect) {
        super.draw(rect)
    }
}

extension UIView {
    class func fromNib<T: UIView>() -> T {
        return Bundle(for: T.self).loadNibNamed(String(describing: T.self), owner: nil, options: nil)![0] as! T
    }
}
