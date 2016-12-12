//
//  Entities.swift
//  Asteroids
//
//  Created by Sean Hickey on 12/6/16.
//  Copyright © 2016 Sean Hickey. All rights reserved.
//

import Darwin

class Entity : Hashable {
    static var nextId = 0
    
    var id : Int
    
    var hashValue : Int {
        return id
    }
    
    // Position and Velocity
    var p  : Vec2 = Vec2()
    var dP : Vec2 = Vec2()
    
    // Rotation and Angular Velocity
    var rot  : Float = 0.0
    var dRot : Float = 0.0
    
    var verts : VertexPointer
    
    init() {
        id = Entity.nextId
        Entity.nextId += 1
        verts = nil
    }
}

func ==(lhs: Entity, rhs: Entity) -> Bool {
    return lhs.id == rhs.id
}

class Ship : Entity {
    
    var alive = true
    
    override init() {
        super.init()
        let v = VertexPointer.alloc(8 * 3)
        let actualVerts : [Float] = [
            0.0,  0.7, 0.0, 1.0, 0.0, 1.0, 1.0, 1.0,
            0.5, -0.7, 0.0, 1.0, 0.7, 1.0, 0.4, 1.0,
            -0.5, -0.7, 0.0, 1.0, 0.7, 1.0, 0.4, 1.0,
            ]
        
        memcpy(v, actualVerts, actualVerts.count * sizeof(Float))
        verts = v
    }
}



class Asteroid : Entity {
    
    enum AsteroidSize {
        case Small
        case Medium
        case Large
    }
    
    var size : AsteroidSize
    
    init(_ location: Vec2, _ newSize: AsteroidSize) {
        size = newSize
        super.init()
        rot = randomInRange(-FLOAT_PI, FLOAT_PI)
        dRot = FLOAT_TWO_PI / 800.0
        
        p.x = location.x
        p.y = location.y
        
        var velocityScale : Float = 0.02
        if newSize == .Medium {
            velocityScale = 0.04
        }
        else if newSize == .Small {
            velocityScale = 0.06
        }
        
        dP.x = randomInRange(-velocityScale, velocityScale)
        dP.y = randomInRange(-velocityScale, velocityScale)
        
        let v = UnsafeMutablePointer<Float>.alloc(8 * 3 * 6)
        let actualVerts : [Float] = [
            0.0,  0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 1.0,
            1.0,  0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 1.0,
            cos((FLOAT_TWO_PI) / 6.0), sin((FLOAT_TWO_PI) / 6.0), 0.0, 1.0, 0.0, 0.0, 1.0, 1.0,
            
            0.0,  0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 1.0,
            cos((FLOAT_TWO_PI) / 6.0), sin((FLOAT_TWO_PI) / 6.0), 0.0, 1.0, 0.0, 0.0, 1.0, 1.0,
            cos(2.0 * (FLOAT_TWO_PI) / 6.0), sin(2.0 * (FLOAT_TWO_PI) / 6.0), 0.0, 1.0, 0.0, 0.0, 1.0, 1.0,
            
            0.0,  0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 1.0,
            cos(2.0 * (FLOAT_TWO_PI) / 6.0), sin(2.0 * (FLOAT_TWO_PI) / 6.0), 0.0, 1.0, 0.0, 0.0, 1.0, 1.0,
            -1.0,  0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 1.0,
            
            0.0,  0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 1.0,
            -1.0,  0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 1.0,
            cos(4.0 * (FLOAT_TWO_PI) / 6.0), sin(4.0 * (FLOAT_TWO_PI) / 6.0), 0.0, 1.0, 0.0, 0.0, 1.0, 1.0,
            
            0.0,  0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 1.0,
            cos(4.0 * (FLOAT_TWO_PI) / 6.0), sin(4.0 * (FLOAT_TWO_PI) / 6.0), 0.0, 1.0, 0.0, 0.0, 1.0, 1.0,
            cos(5.0 * (FLOAT_TWO_PI) / 6.0), sin(5.0 * (FLOAT_TWO_PI) / 6.0), 0.0, 1.0, 0.0, 0.0, 1.0, 1.0,
            
            0.0,  0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 1.0,
            cos(5.0 * (FLOAT_TWO_PI) / 6.0), sin(5.0 * (FLOAT_TWO_PI) / 6.0), 0.0, 1.0, 0.0, 0.0, 1.0, 1.0,
            1.0,  0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 1.0
        ]
        
        memcpy(v, actualVerts, actualVerts.count * sizeof(Float))
        verts = v
    }
    
    convenience init(_ world: World, _ newSize: AsteroidSize) {
        let x = randomInRange(-world.size.w / 2.0, world.size.w / 2.0)
        let y = randomInRange(-world.size.w / 2.0, world.size.w / 2.0)
        self.init(Vec2(x, y), newSize)
    }

}

func scaleForAsteroidSize(size: Asteroid.AsteroidSize) -> Float {
    switch size {
    case .Large:
        return 2.0
    case .Medium:
        return 1.5
    case .Small:
        return 1.0
    }
}

class Laser : Entity {
    
    var timeAlive : Float = 0.0 // seconds
    let lifetime  : Float = 1.0
    
    let scale : Float = 0.05
    
    init(_ ship: Ship) {
        super.init()
        p.x = ship.p.x
        p.y = ship.p.y
        
        dP.x = sin(ship.rot) * 0.2
        dP.y = cos(ship.rot) * 0.2
        
        let v = VertexPointer.alloc(8 * 3 * 2)
        let actualVerts : [Float] = [
            1.0,  1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0,
           -1.0,  1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0,
           -1.0, -1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0,
           
            1.0,  1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0,
           -1.0, -1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0,
            1.0, -1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0
        ]
        
        memcpy(v, actualVerts, actualVerts.count * sizeof(Float))
        verts = v
        
    }
    
}


func rotateEntity(entity: Entity, _ radians: Float) {
    entity.rot += radians
    entity.rot = normalizeToRange(entity.rot, Float(-M_PI), Float(M_PI))
}