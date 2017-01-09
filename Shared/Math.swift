//
//  Math.swift
//  Asteroids
//
//  Created by Sean Hickey on 12/5/16.
//  Copyright © 2016 Sean Hickey. All rights reserved.
//

import Darwin
import simd

typealias Transform = float4x4

let FLOAT_PI = Float(M_PI)
let FLOAT_TWO_PI = Float(2.0 * M_PI)

struct Rect {
    var x : Float = 0.0
    var y : Float = 0.0
    var w : Float = 0.0
    var h : Float = 0.0
}

func +(lhs: Vec2, rhs: Vec2) -> Vec2 {
    return Vec2(lhs.x + rhs.x, lhs.y + rhs.y)
}

func +=(lhs: inout Vec2, rhs: Vec2) {
    lhs = lhs + rhs
}

func -(lhs: Vec2, rhs: Vec2) -> Vec2 {
    return Vec2(lhs.x - rhs.x, lhs.y - rhs.y)
}

func -=(lhs: inout Vec2, rhs: Vec2) {
    lhs = lhs - rhs
}

func *(lhs: Vec2, rhs: Float) -> Vec2 {
    return Vec2(rhs * lhs.x, rhs * lhs.y)
}

func *(lhs: Float, rhs: Vec2) -> Vec2 {
    return Vec2(lhs * rhs.x, lhs * rhs.y)
}

func norm(_ vec: Vec2) -> Float {
    return sqrt((vec.x * vec.x) + (vec.y * vec.y))
}

func normalize(_ vec: Vec2) -> Vec2 {
    let len = norm(vec)
    return Vec2(vec.x / len, vec.y / len)
}


func distanceSquared(_ v1: Vec2, _ v2: Vec2) -> Float {
    return ((v1.x - v2.x) * (v1.x - v2.x)) + ((v1.y - v2.y) * (v1.y - v2.y))
}

func distance(_ v1: Vec2, _ v2: Vec2) -> Float {
    return sqrt(distanceSquared(v1, v2))
}

func torusDistance(_ torusSize: Size, _ v1: Vec2, _ v2: Vec2) -> Float {
    var xDiff = abs(v1.x - v2.x)
    if xDiff > (torusSize.width / 2.0) {
        xDiff = torusSize.width - xDiff
    }
    var yDiff = abs(v1.y - v2.y)
    if yDiff > (torusSize.height / 2.0) {
        yDiff = torusSize.height - yDiff
    }
    return sqrt((xDiff * xDiff) + (yDiff * yDiff))
}

func normalizeToRange(_ val: Float, _ min: Float, _ max: Float) -> Float {
    let width = max - min
    let offset = val - min
    
    return (offset - (floorf(offset / width) * width)) + min
}

// Transforms

func translateTransform(_ x: Float, _ y: Float) -> Transform {
    var transform = Transform(1)
    transform[3][0] = x
    transform[3][1] = y
    return transform
}

func rotateTransform(_ theta: Float) -> Transform {
    var transform = Transform(1)
    transform[0][0] =  cos(theta)
    transform[0][1] = -sin(theta)
    transform[1][0] =  sin(theta)
    transform[1][1] =  cos(theta)
    return transform
}

func scaleTransform(_ x: Float, _ y: Float) -> Transform {
    var transform = Transform(1)
    transform[0][0] = x
    transform[1][1] = y
    return transform
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
