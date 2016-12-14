//
//  Entities.swift
//  Asteroids
//
//  Created by Sean Hickey on 12/6/16.
//  Copyright © 2016 Sean Hickey. All rights reserved.
//

import Darwin

protocol Entity {
//    static var nextId = 0
    
//    var id : Int
    
//    var hashValue : Int {
//        return id
//    }
    
    // Position and Velocity
    var p  : Vec2 { get set }
    var dP : Vec2 { get set }
    
    // Rotation and Angular Velocity
    var rot  : Float { get set }
    var dRot : Float { get set }
    
    var verts : VertexPointer? { get set }
    
//    init() {
//        id = Entity.nextId
//        Entity.nextId += 1
//        verts = nil
//    }
}

protocol EntityRef {
    associatedtype T : Entity
    var ptr : Ptr<T> { get set }
    
    var p  : Vec2 { get set }
    var dP : Vec2 { get set }
    
    // Rotation and Angular Velocity
    var rot  : Float { get set }
    var dRot : Float { get set }
    
    var verts : VertexPointer? { get set }
}

extension EntityRef {
    var p  : Vec2 { get { return ptr.pointee.p } set(val) {ptr.pointee.p = val} }
    var dP : Vec2 { get { return ptr.pointee.dP } set(val) {ptr.pointee.dP = val} }
    
    var rot  : Float { get { return ptr.pointee.rot } set(val) {ptr.pointee.rot = val} }
    var dRot : Float { get { return ptr.pointee.dRot } set(val) {ptr.pointee.dRot = val} }
    
    var verts : VertexPointer? { get { return ptr.pointee.verts } set(val) {ptr.pointee.verts = val} }
}



//func ==(lhs: Entity, rhs: Entity) -> Bool {
//    return lhs.id == rhs.id
//}

struct Ship : Entity {
    
    // Entity
    var p  : Vec2 = Vec2()
    var dP : Vec2 = Vec2()
    
    // Rotation and Angular Velocity
    var rot  : Float = 0.0
    var dRot : Float = 0.0
    
    var verts : VertexPointer?
    
    
    var alive : Bool
    
//    override init() {
//        super.init()
//        let v = VertexPointer.allocate(capacity: 8 * 3)
//        let actualVerts : [Float] = [
//            0.0,  0.7, 0.0, 1.0, 0.0, 1.0, 1.0, 1.0,
//            0.5, -0.7, 0.0, 1.0, 0.7, 1.0, 0.4, 1.0,
//            -0.5, -0.7, 0.0, 1.0, 0.7, 1.0, 0.4, 1.0,
//            ]
//        
//        memcpy(v, actualVerts, actualVerts.count * MemoryLayout<Float>.size)
//        verts = v
//    }
}

struct ShipRef : EntityRef {
    typealias T = Ship
    var ptr : Ptr<T>
    
//    var p  : Vec2 { get{ return ref.pointee.p } set(val){ ref.pointee.p = val } }
//    var dP : Vec2 { get{ return ref.pointee.dP } set(val){ ref.pointee.dP = val } }
//    var rot  : Float { get{ return ref.pointee.rot } set(val){ ref.pointee.rot = val } }
//    var dRot : Float { get{ return ref.pointee.dRot } set(val){ ref.pointee.dRot = val } }
//    var verts : VertexPointer?{ get{ return ref.pointee.verts } set(val){ ref.pointee.verts = val } }
    var alive : Bool { get{ return Ptr<Ship>(ptr).pointee.alive } set(val){ Ptr<Ship>(ptr).pointee.alive = val } }
    
}

func createWorld(_ zone: MemoryZoneRef) -> WorldRef {
    let worldPtr = allocateTypeFromZone(zone, World.self)
    return WorldRef(ptr: worldPtr)
}

func createShip(_ zone: MemoryZoneRef) -> ShipRef {
    let shipPtr = allocateTypeFromZone(zone, Ship.self)
    var ship = ShipRef(ptr: shipPtr)
    
    ship.alive = true
    
    let vertPtr = allocateFromZone(zone, 3 * 8 * MemoryLayout<Float>.size)
    let verts : [Float] = [
        0.0,  0.7, 0.0, 1.0, 0.0, 1.0, 1.0, 1.0,
        0.5, -0.7, 0.0, 1.0, 0.7, 1.0, 0.4, 1.0,
        -0.5, -0.7, 0.0, 1.0, 0.7, 1.0, 0.4, 1.0,
    ]
    vertPtr.initializeMemory(as: Float.self, from: verts)
    ship.verts = <-vertPtr
    return ship
}


//class Asteroid : Entity {
//    
//    enum AsteroidSize {
//        case small
//        case medium
//        case large
//    }
//    
//    var size : AsteroidSize
//    
//    init(_ location: Vec2, _ newSize: AsteroidSize) {
//        size = newSize
//        super.init()
//        rot = randomInRange(-FLOAT_PI, FLOAT_PI)
//        dRot = FLOAT_TWO_PI / 800.0
//        
//        p.x = location.x
//        p.y = location.y
//        
//        var velocityScale : Float = 0.02
//        if newSize == .medium {
//            velocityScale = 0.04
//        }
//        else if newSize == .small {
//            velocityScale = 0.06
//        }
//        
//        dP.x = randomInRange(-velocityScale, velocityScale)
//        dP.y = randomInRange(-velocityScale, velocityScale)
//        
//        let v = UnsafeMutablePointer<Float>.allocate(capacity: 8 * 3 * 6)
//        let actualVerts : [Float] = [
//            0.0,  0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 1.0,
//            1.0,  0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 1.0,
//            cos((FLOAT_TWO_PI) / 6.0), sin((FLOAT_TWO_PI) / 6.0), 0.0, 1.0, 0.0, 0.0, 1.0, 1.0,
//            
//            0.0,  0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 1.0,
//            cos((FLOAT_TWO_PI) / 6.0), sin((FLOAT_TWO_PI) / 6.0), 0.0, 1.0, 0.0, 0.0, 1.0, 1.0,
//            cos(2.0 * (FLOAT_TWO_PI) / 6.0), sin(2.0 * (FLOAT_TWO_PI) / 6.0), 0.0, 1.0, 0.0, 0.0, 1.0, 1.0,
//            
//            0.0,  0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 1.0,
//            cos(2.0 * (FLOAT_TWO_PI) / 6.0), sin(2.0 * (FLOAT_TWO_PI) / 6.0), 0.0, 1.0, 0.0, 0.0, 1.0, 1.0,
//            -1.0,  0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 1.0,
//            
//            0.0,  0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 1.0,
//            -1.0,  0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 1.0,
//            cos(4.0 * (FLOAT_TWO_PI) / 6.0), sin(4.0 * (FLOAT_TWO_PI) / 6.0), 0.0, 1.0, 0.0, 0.0, 1.0, 1.0,
//            
//            0.0,  0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 1.0,
//            cos(4.0 * (FLOAT_TWO_PI) / 6.0), sin(4.0 * (FLOAT_TWO_PI) / 6.0), 0.0, 1.0, 0.0, 0.0, 1.0, 1.0,
//            cos(5.0 * (FLOAT_TWO_PI) / 6.0), sin(5.0 * (FLOAT_TWO_PI) / 6.0), 0.0, 1.0, 0.0, 0.0, 1.0, 1.0,
//            
//            0.0,  0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 1.0,
//            cos(5.0 * (FLOAT_TWO_PI) / 6.0), sin(5.0 * (FLOAT_TWO_PI) / 6.0), 0.0, 1.0, 0.0, 0.0, 1.0, 1.0,
//            1.0,  0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 1.0
//        ]
//        
//        memcpy(v, actualVerts, actualVerts.count * MemoryLayout<Float>.size)
//        verts = v
//    }
//    
//    convenience init(_ world: World, _ newSize: AsteroidSize) {
//        let x = randomInRange(-world.size.w / 2.0, world.size.w / 2.0)
//        let y = randomInRange(-world.size.w / 2.0, world.size.w / 2.0)
//        self.init(Vec2(x, y), newSize)
//    }
//
//}
//
//func scaleForAsteroidSize(_ size: Asteroid.AsteroidSize) -> Float {
//    switch size {
//    case .large:
//        return 2.0
//    case .medium:
//        return 1.5
//    case .small:
//        return 1.0
//    }
//}
//
//class Laser : Entity {
//    
//    var timeAlive : Float = 0.0 // seconds
//    let lifetime  : Float = 1.0
//    
//    let scale : Float = 0.05
//    
//    init(_ ship: Ship) {
//        super.init()
//        p.x = ship.p.x
//        p.y = ship.p.y
//        
//        dP.x = sin(ship.rot) * 0.2
//        dP.y = cos(ship.rot) * 0.2
//        
//        let v = VertexPointer.allocate(capacity: 8 * 3 * 2)
//        let actualVerts : [Float] = [
//            1.0,  1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0,
//           -1.0,  1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0,
//           -1.0, -1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0,
//           
//            1.0,  1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0,
//           -1.0, -1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0,
//            1.0, -1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0
//        ]
//        
//        memcpy(v, actualVerts, actualVerts.count * MemoryLayout<Float>.size)
//        verts = v
//        
//    }
//    
//}


func rotateEntity<T : EntityRef>(_ entity: T, _ radians: Float) {
    var ref = entity
    ref.rot += radians
    ref.rot = normalizeToRange(entity.rot, Float(-M_PI), Float(M_PI))
}
