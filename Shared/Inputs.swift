//
//  Input.swift
//  Asteroids
//
//  Created by Sean Hickey on 12/7/16.
//  Copyright © 2016 Sean Hickey. All rights reserved.
//

open class Inputs {
    var dt : Float = 0.0
    
    var rotate  : Float = 0.0  // Normalized between -1.0 and 1.0
    var thrust  : Bool = false
    var fire    : Bool = false
    
    // Debugging Purposes
    var restart : Bool = false
    var mouse : Vec2 = Vec2()
}
