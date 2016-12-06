//
//  Types.swift
//  Asteroids
//
//  Created by Sean Hickey on 12/5/16.
//  Copyright © 2016 Sean Hickey. All rights reserved.
//

import Darwin

struct Point {
    var x : Float = 0.0
    var y : Float = 0.0
}

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

func norm(vec: Vec2) -> Float {
    return sqrt((vec.x * vec.x) + (vec.y * vec.y))
}

func normalize(vec: Vec2) -> Vec2 {
    let len = norm(vec)
    return Vec2(vec.x / len, vec.y / len)
}

func normalizeToRange(val: Float, _ min: Float, _ max: Float) -> Float {
    let width = max - min
    let offset = val - min
    
    return (offset - (floorf(offset / width) * width)) + min
}

func clamp(val: Float, _ min: Float, _ max: Float) -> Float {
    if val < min {
        return min
    }
    if val > max {
        return max
    }
    return val
}
