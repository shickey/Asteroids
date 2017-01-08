//
//  DebugSystem.swift
//  Asteroids
//
//  Created by Sean Hickey on 1/4/17.
//  Copyright © 2017 Sean Hickey. All rights reserved.
//

import simd

func hitTest(_ gameState: GameStateRef, _ location : Vec2, _ entity: Entity, _ windowSize: Size) -> Bool {
    let renderable = gameState.renderables[entity.renderableId]!
    
    if location.x < 0 || location.y < 0 || location.x > windowSize.w || location.y > windowSize.h {
        return false
    }
    let worldLocation = windowToWorldCoordinates(location, windowSize, gameState)
    
    // Only test entities that are within a resonable range
    if torusDistance(gameState.world.size, entity.p, worldLocation) <= (entity.scale * 2.0) {
    
        // See if the location is within the entities bounding box by
        // testing a line extending from worldLocation to a point in the +x direction offscreen
        //
        // TODO: This doesn't take toroidal topology into account
        let testLineEnd = worldLocation + Vec2(gameState.world.size.width, 0)
        
        let transform = entityTransform(entity)
        let boundingBox = renderable.boundingBox
        let bb1 = transform * float4(boundingBox.x, boundingBox.y, 0.0, 1.0)
        let bb2 = transform * float4(boundingBox.x, boundingBox.y + boundingBox.h, 0.0, 1.0)
        let bb3 = transform * float4(boundingBox.x + boundingBox.w, boundingBox.y + boundingBox.h, 0.0, 1.0)
        let bb4 = transform * float4(boundingBox.x + boundingBox.w, boundingBox.y, 0.0, 1.0)
        
        var crossings = 0
        // First line
        let line1Start = Vec2(bb1.x, bb1.y)
        let line1End = Vec2(bb2.x, bb2.y)
        if intersect(worldLocation, testLineEnd, line1Start, line1End) {
            crossings += 1
        }
        // Second line
        let line2Start = Vec2(bb2.x, bb2.y)
        let line2End = Vec2(bb3.x, bb3.y)
        if intersect(worldLocation, testLineEnd, line2Start, line2End) {
            crossings += 1
        }
        // Third line
        let line3Start = Vec2(bb3.x, bb3.y)
        let line3End = Vec2(bb4.x, bb4.y)
        if intersect(worldLocation, testLineEnd, line3Start, line3End) {
            crossings += 1
        }
        // Fourth line
        let line4Start = Vec2(bb4.x, bb4.y)
        let line4End = Vec2(bb1.x, bb1.y)
        if intersect(worldLocation, testLineEnd, line4Start, line4End) {
            crossings += 1
        }
        
        if crossings % 2 == 1 {
            return true
        }
        
    }

    return false
}

func windowToWorldCoordinates(_ location: Vec2, _ windowSize: Size, _ gameState: GameStateRef) -> Vec2 {
    var worldSize = gameState.world.size
    
    var result = Vec2()
    result.x = ((location.x - (windowSize.w / 2.0)) / (windowSize.w / 2.0)) * (worldSize.w / 2.0)
    result.y = ((location.y - (windowSize.h / 2.0)) / (windowSize.h / 2.0)) * (worldSize.h / 2.0)
    return result
}

func intersect(_ line1Start: Vec2, _ line1End: Vec2, _ line2Start: Vec2, _ line2End: Vec2) -> Bool {
    
    func simple2dCross(_ a: Vec2, _ b: Vec2) -> Float {
        return (a.x * b.y) - (a.y * b.x)
    }
    
    let r = line1End - line1Start
    let s = line2End - line2Start
    let rXs = simple2dCross(r, s)
    
    if rXs == 0 {
        return false
    }
    
    let t = simple2dCross((line2Start - line1Start), s) / rXs
    let u = simple2dCross((line2Start - line1Start), r) / rXs
    
    if t >= 0 && t <= 1 && u >= 0 && u <= 1 {
        return true
    }
    
    return false
}



struct DebugStruct {
    typealias Entry = (String, Any)
    var name : String
    var entries : [Entry]
}

func debugEntity(_ entity: Entity) -> DebugStruct? {
    if let ship = entity as? ShipRef {
        return debugEntityRef(ship)
    }
    else if let asteroid = entity as? AsteroidRef {
        return debugEntityRef(asteroid)
    }
    else if let laser = entity as? LaserRef {
        return debugEntityRef(laser)
    }
    else {
        print("Unsupported Entity")
    }
    return nil
}

func debugEntityRef<T>(_ entity: EntityRef<T>) -> DebugStruct {
    var entries : [DebugStruct.Entry] = []
    
    let entityBaseMirror = Mirror(reflecting: ^entity.base)
    for (nameOpt, value) in entityBaseMirror.children {
        if let name = nameOpt {
            entries.append((name, value))
        }
    }
    
    let entityMirror = Mirror(reflecting: ^entity)
    for (nameOpt, value) in entityMirror.children {
        if let name = nameOpt {
            entries.append((name, value))
        }
    }
    return DebugStruct(name: String(describing: entityMirror.subjectType), entries: entries)
}







