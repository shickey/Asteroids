//
//  Entities.swift
//  Asteroids
//
//  Created by Sean Hickey on 12/6/16.
//  Copyright © 2016 Sean Hickey. All rights reserved.
//

import Darwin


/****************************************
 * Entity Base
 ****************************************/

protocol Entity {
    // Position and Velocity
    var p  : Vec2 { get set }
    var dP : Vec2 { get set }
    
    // Rotation and Angular Velocity
    var rot  : Float { get set }
    var dRot : Float { get set }
    
    var verts : VertexPointer? { get set }
}

protocol EntityRef : Ref {
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


/****************************************
 * Ship
 ****************************************/

/*= BEGIN_REFSTRUCT =*/
struct Ship : Entity {
    // Entity
    var p  : Vec2 = Vec2()
    var dP : Vec2 = Vec2()
    var rot  : Float
    var dRot : Float
    var verts : VertexPointer?
    
    // Ship
    var alive : Bool /*= GETSET =*/
}
/*= END_REFSTRUCT =*/

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


/****************************************
 * World
 ****************************************/

func createWorld(_ zone: MemoryZoneRef) -> WorldRef {
    let worldPtr = allocateTypeFromZone(zone, World.self)
    return WorldRef(ptr: worldPtr)
}


/****************************************
 * Asteroid
 ****************************************/

/*= BEGIN_REFSTRUCT =*/
struct Asteroid : Entity {
    // Entity
    var p  : Vec2 = Vec2()
    var dP : Vec2 = Vec2()
    var rot  : Float
    var dRot : Float
    var verts : VertexPointer?
    
    // Asteroid
    enum AsteroidSize {
        case small
        case medium
        case large
    }
    var size : Asteroid.AsteroidSize /*= GETSET =*/
    var alive : Bool /*= GETSET =*/
}
/*= END_REFSTRUCT =*/

func createAsteroid(_ zone: MemoryZoneRef, _ size: Asteroid.AsteroidSize) -> AsteroidRef {
    let asteroidPtr = allocateTypeFromZone(zone, Asteroid.self)
    var asteroid = AsteroidRef(ptr: asteroidPtr)
    asteroid.alive = true
    asteroid.size = size
    
    let vertPtr = allocateFromZone(zone, 8 * 3 * 6 * MemoryLayout<Float>.size)
    let verts : [Float] = [
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
    vertPtr.initializeMemory(as: Float.self, from: verts)
    asteroid.verts = <-vertPtr
    
    return asteroid
}

func scaleForAsteroidSize(_ size: Asteroid.AsteroidSize) -> Float {
    switch size {
    case .large:
        return 2.0
    case .medium:
        return 1.5
    case .small:
        return 1.0
    }
}

func randomizeAsteroidLocationInWorld(_ asteroidRef: AsteroidRef, _ world: WorldRef) {
    var asteroid = asteroidRef
    
    var location = Vec2()
    repeat {
        location.x = randomInRange(-world.size.w / 2.0, world.size.w / 2.0)
        location.y = randomInRange(-world.size.w / 2.0, world.size.w / 2.0)
    } while distance(location, world.ship.p) < (scaleForAsteroidSize(.large) * 2.0) // Prevent an asteroid from spawning right on top of the ship
    asteroid.p = location
}

func randomizeAsteroidRotationAndVelocity(_ asteroidRef: AsteroidRef) {
    var asteroid = asteroidRef
    asteroid.rot = randomInRange(-FLOAT_PI, FLOAT_PI)
    asteroid.dRot = randomInRange(FLOAT_TWO_PI / 900.0, FLOAT_TWO_PI / 700.0)
    var velocityScale : Float = 0.02
    if asteroid.size == .medium {
        velocityScale = 0.04
    }
    else if asteroid.size == .small {
        velocityScale = 0.06
    }
    asteroid.dP.x = randomInRange(-velocityScale, velocityScale)
    asteroid.dP.y = randomInRange(-velocityScale, velocityScale)
}


/****************************************
 * Laser
 ****************************************/

/*= BEGIN_REFSTRUCT =*/
struct Laser : Entity {
    // Entity
    var p  : Vec2 = Vec2()
    var dP : Vec2 = Vec2()
    var rot  : Float
    var dRot : Float
    var verts : VertexPointer?
    
    // Laser
    var timeAlive : Float /*= GETSET =*/
    var lifetime : Float /*= GETSET =*/
    var alive : Bool /*= GETSET =*/
    
}
/*= END_REFSTRUCT =*/

func createLaser(_ zone: MemoryZoneRef, _ ship: ShipRef) -> LaserRef {
    let laserPtr = allocateTypeFromZone(zone, Laser.self)
    var laser = LaserRef(ptr: laserPtr)
    
    laser.p = ship.p

    laser.dP.x = sin(ship.rot) * 0.2
    laser.dP.y = cos(ship.rot) * 0.2
    
    laser.timeAlive = 0.0
    laser.lifetime = 1.0
    laser.alive = true
    
    let vertPtr = allocateFromZone(zone, 8 * 3 * 2 * MemoryLayout<Float>.size)
    let verts : [Float] = [
        1.0,  1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0,
       -1.0,  1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0,
       -1.0, -1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0,

        1.0,  1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0,
       -1.0, -1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0,
        1.0, -1.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0
    ]
    vertPtr.initializeMemory(as: Float.self, from: verts)
    laser.verts = <-vertPtr
    return laser
}



func rotateEntity<T : EntityRef>(_ entity: T, _ radians: Float) {
    var ref = entity
    ref.rot += radians
    ref.rot = normalizeToRange(entity.rot, Float(-M_PI), Float(M_PI))
}
