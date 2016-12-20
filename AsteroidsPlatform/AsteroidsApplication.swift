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
    
    override func sendEvent(_ theEvent: NSEvent) {
        
        // Suppress keyboard events since we're handling them through IOKit
        if theEvent.type == .keyDown || theEvent.type == .keyUp {
            return
        }
        super.sendEvent(theEvent)
    }

}
