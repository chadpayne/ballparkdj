//
//  BallparkButton.swift
//  
//
//  Created by Kurt Niemi on 9/11/16.
//
//

import UIKit

class BallparkButton: FUIButton {

    let mininumWidth:CGFloat = 90.0
    let mininumHeight:CGFloat = 40.0
    
    override func intrinsicContentSize() -> CGSize {
        var size = super.intrinsicContentSize()
        
        if (size.width < mininumWidth)
        {
            size.width = mininumWidth
        }
        
        if (size.height < mininumHeight)
        {
            size.height = mininumHeight
        }
        
        return size
    }
}
