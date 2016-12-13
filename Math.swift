//
//  Types.swift
//  Asteroids
//
//  Created by Sean Hickey on 12/5/16.
//  Copyright © 2016 Sean Hickey. All rights reserved.
//

import Darwin

let FLOAT_PI = Float(M_PI)
let FLOAT_TWO_PI = Float(2.0 * M_PI)

struct Size {
    var width : Float = 1.0
    var height : Float = 1.0
    
    var w : Float {
        get {
            return width
        }
        set(newW) {
            width = newW
        }
    }
    
    var h : Float {
        get {
            return height
        }
        set(newH) {
            height = newH
        }
    }
    
    init(_ newWidth: Float, _ newHeight: Float) {
        width = newWidth
        height = newHeight
    }
}


struct Vec2 {
    var x : Float = 0.0
    var y : Float = 0.0
    
    init() {}
    
    init(_ newX: Float, _ newY: Float) {
        x = newX
        y = newY
    }
}

func +(lhs: Vec2, rhs: Vec2) -> Vec2 {
    return Vec2(lhs.x + rhs.x, lhs.y + rhs.y)
}

func +=(lhs: inout Vec2, rhs: Vec2) {
    lhs = lhs + rhs
}

func norm(_ vec: Vec2) -> Float {
    return sqrt((vec.x * vec.x) + (vec.y * vec.y))
}

func normalize(_ vec: Vec2) -> Vec2 {
    let len = norm(vec)
    return Vec2(vec.x / len, vec.y / len)
}

func normalizeToRange(_ val: Float, _ min: Float, _ max: Float) -> Float {
    let width = max - min
    let offset = val - min
    
    return (offset - (floorf(offset / width) * width)) + min
}

func distanceSquared(_ v1: Vec2, _ v2: Vec2) -> Float {
    return ((v1.x - v2.x) * (v1.x - v2.x)) + ((v1.y - v2.y) * (v1.y - v2.y))
}

func distance(_ v1: Vec2, _ v2: Vec2) -> Float {
    return sqrt(distanceSquared(v1, v2))
}

func clamp(_ val: Float, _ min: Float, _ max: Float) -> Float {
    if val < min {
        return min
    }
    if val > max {
        return max
    }
    return val
}

// Random Numbers

var seeded = false

func randomZeroToOne() -> Float {
    if !seeded {
        srand48(Int(arc4random()))
        seeded = true
    }
    return Float(drand48())
}

func randomInRange(_ min: Float, _ max: Float) -> Float {
    return (randomZeroToOne() * (max - min)) + min
}
