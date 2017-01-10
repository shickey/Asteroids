//
//  SharedMath.swift
//  Asteroids
//
//  Created by Sean Hickey on 1/8/17.
//  Copyright © 2017 Sean Hickey. All rights reserved.
//

import Foundation

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

// TODO: Make vectors generic
struct Vec2 {
    var x : Float = 0.0
    var y : Float = 0.0
    
    init() {}
    
    init(_ newX: Float, _ newY: Float) {
        x = newX
        y = newY
    }
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
