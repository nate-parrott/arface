//
//  PageSwiperScrollView.swift
//  ARFace
//
//  Created by Nate Parrott on 12/3/17.
//  Copyright © 2017 Nate Parrott. All rights reserved.
//

import UIKit

class PageSwiperScrollView : UIScrollView, UIScrollViewDelegate {
    var callback: ((Int, CGFloat) -> ())? // page, offset
    
    override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        setup()
    }
    
    func setup() {
        self.delegate = self
        self.isPagingEnabled = true
    }
    
    var nPages: Int = 1 {
        didSet {
            setNeedsLayout()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        contentSize = CGSize(width: bounds.width * CGFloat(nPages), height: 1)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        var page = Int(round(scrollView.contentOffset.x / scrollView.bounds.width))
        page = max(0, min(nPages-1, page))
        var offset = -(scrollView.contentOffset.x - CGFloat(page) * scrollView.bounds.width) / (scrollView.bounds.width * 0.3)
        offset = min(1, max(-1, offset))
        if let cb = callback {
            cb(page, offset)
        }
    }
}
