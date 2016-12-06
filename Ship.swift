//
//  Ship.swift
//  Asteroids
//
//  Created by Sean Hickey on 12/5/16.
//  Copyright © 2016 Sean Hickey. All rights reserved.
//

import Darwin

class Ship {
    var rotation : Float = 0.0
    
    var p   : Point = Point()
    var dP  : Vec2  = Vec2()
    
    let verts : UnsafeMutablePointer<Float> = ({
        var v = UnsafeMutablePointer<Float>.alloc(8 * 3)
        var actualVerts : [Float] = [
            0.0,  0.7, 0.0, 1.0, 0.0, 1.0, 1.0, 1.0,
            0.5, -0.7, 0.0, 1.0, 0.7, 1.0, 0.4, 1.0,
           -0.5, -0.7, 0.0, 1.0, 0.7, 1.0, 0.4, 1.0,
        ]
        
        memcpy(v, actualVerts, actualVerts.count * sizeof(Float))
        
        return v
    })()
}

func rotateShip(ship: Ship, _ radians: Float) {
    ship.rotation += radians
    ship.rotation = normalizeToRange(ship.rotation, Float(-M_PI), Float(M_PI))
}
