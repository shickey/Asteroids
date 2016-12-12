//
//  AsteroidsApplication.swift
//  Asteroids
//
//  Created by Sean Hickey on 12/6/16.
//  Copyright © 2016 Sean Hickey. All rights reserved.
//

import Cocoa

@objc(AsteroidsApplication)
class AsteroidsApplication: NSApplication {
    
    override func sendEvent(theEvent: NSEvent) {
        
        // Suppress keyboard events since we're handling them through IOKit
        if theEvent.type == .KeyDown || theEvent.type == .KeyUp {
            return
        }
        super.sendEvent(theEvent)
    }

}
