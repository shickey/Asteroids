//
//  Renderer.swift
//  Asteroids
//
//  Created by Sean Hickey on 12/5/16.
//  Copyright © 2016 Sean Hickey. All rights reserved.
//

import Darwin
import simd

prefix operator ^
prefix func ^<T : Ref>(_ ref : T) -> T.T {
        return ref.ptr.pointee
}

struct DEBUG_STRUCT {
    let ZOOM_OUT = false
    let BACKGROUND = false
}

let DEBUG = DEBUG_STRUCT()

let NUM_ASTEROIDS = 3

/*= BEGIN_REFSTRUCT =*/
struct GameState {
    var gameInitialized : Bool /*= GETSET =*/
    var world : WorldRef /*= GETSET =*/

    var zoneZone : MemoryZone /*= GETSET =*/
    var entityZone : MemoryZoneRef /*= GETSET =*/
    var assetZone : MemoryZoneRef /*= GETSET =*/
    
    var vertexBuffers : HashTableRef<RenderableId, RawPtr> /*= GETSET =*/
}
/*= END_REFSTRUCT =*/


/*= BEGIN_REFSTRUCT =*/
struct World : Renderable {
    var size : Size /*= GETSET =*/
    var ship : ShipRef /*= GETSET =*/
    var asteroids : PoolRef<AsteroidRef> /*= GETSET =*/
    var lasers : CircularBufferRef<LaserRef> /*= GETSET =*/
}
/*= END_REFSTRUCT =*/


var firstRun = true // This feels wrong, but is useful for doing things on game code reload boundaries

var restarting = false

var font : BitmapFontRef! = nil

@_silgen_name("updateAndRender")
public func updateAndRender(_ gameMemoryPtr: UnsafeMutablePointer<GameMemory>, inputsPtr: UnsafeMutablePointer<Inputs>, renderCommandHeaderPtr: UnsafeMutablePointer<RenderCommandBufferHeader>) {
    
    let gameMemory = gameMemoryPtr.pointee
    let inputs = inputsPtr.pointee
    
    let gameStatePtr : Ptr<GameState> = <-gameMemory.permanent
    var gameState = GameStateRef(ptr: gameStatePtr)
    
    if !gameState.gameInitialized {

        gameState.zoneZone.base = gameMemory.permanent + MemoryLayout<GameState>.size
        gameState.zoneZone.size = 1.megabytes
        
        let entityZoneBase = gameState.zoneZone.base + gameState.zoneZone.size
        let entityZoneSize = 32.megabytes
        
        gameState.entityZone = createZone(&gameState.zoneZone, entityZoneBase, entityZoneSize)
        
        let assetZoneBase = entityZoneBase + entityZoneSize
        let assetZoneSize = gameMemory.permanentSize - (MemoryLayout<GameState>.size + gameState.zoneZone.size + entityZoneSize)
        
        gameState.assetZone = createZone(&gameState.zoneZone, assetZoneBase, assetZoneSize)
        
        font = loadBitmapFont(gameState.assetZone, "source-sans-pro-16-white-shadow.txt")
        
        gameState.vertexBuffers = createHashTable(gameState.entityZone, 37) // Use a large-enough prime to help hash distribution
        
        let ship = createShip(gameMemory, gameState.entityZone, gameState)
        
        var world = createWorld(gameState.entityZone)
        world.size = Size(20.0, 20.0)
        world.ship = ship

        let MAX_ASTEROIDS = 7 * NUM_ASTEROIDS // Every asteroid can split twice so x + 2x + 4x = 7x
        let asteroids = createPool(gameState.entityZone, type: AsteroidRef.self, count: MAX_ASTEROIDS)
        for _ in 0..<NUM_ASTEROIDS {
            let asteroid = createAsteroid(gameMemory, gameState.entityZone, gameState, .large)
            randomizeAsteroidLocationInWorld(asteroid, world)
            randomizeAsteroidRotationAndVelocity(asteroid)
            poolAdd(asteroids, asteroid)
        }
        
        let MAX_LASERS = 12
        world.lasers = createCircularBuffer(gameState.entityZone, type: LaserRef.self, count: MAX_LASERS) 
        
        world.asteroids = asteroids
        
        gameState.world = world
        
        gameState.gameInitialized = true
    }
    
    if !restarting && inputs.restart {
        restarting = true
        restartGame(gameMemory, gameState)
    }
    else if restarting && !inputs.restart {
        restarting = false
    }
    
    
    // Simulate
    simulate(gameMemory, gameState, inputs.dt, inputs)
    
    // Render
    let renderBuffer = Ptr(renderCommandHeaderPtr)

    var options = RenderCommandOptions()
    options.fillMode = .fill
    pushCommand(renderBuffer, options)
    
    
    let scaleFactor = max(gameState.world.size.width, gameState.world.size.height)
    var worldTransform = float4x4(1)
    worldTransform[0][0] = 1.0 / (scaleFactor / 2.0)
    worldTransform[1][1] = 1.0 / (scaleFactor / 2.0)
    
    if DEBUG.ZOOM_OUT {
        worldTransform[0][0] = 1.0 / scaleFactor
        worldTransform[1][1] = 1.0 / scaleFactor
    }
    
    var uniforms = RenderCommandUniforms()
    uniforms.transform = worldTransform
    pushCommand(renderBuffer, uniforms)
    
    
    if DEBUG.BACKGROUND {
        renderTerribleBackground(gameMemory, gameState, renderBuffer)
    }
    else {
        renderBlackBackground(gameMemory, gameState, renderBuffer)
    }
    renderAsteroids(gameState, renderBuffer)
    renderShip(gameState, renderBuffer)
    renderLasers(gameState, renderBuffer)
    
//    let command = renderText(renderBuffer, "[Hello world!]?", font)
//    pushCommand(renderBuffer, command)
    
    firstRun = false
}

func restartGame(_ gameMemory: GameMemory, _ gameState: GameStateRef) {
    var game = gameState
    
    // Reset ship
    game.world.ship = createShip(gameMemory, game.entityZone, game)
    
    // Reset asteroids
    let asteroids = game.world.asteroids
    clearPool(asteroids)
    for _ in 0..<NUM_ASTEROIDS {
        let asteroid = createAsteroid(gameMemory, game.entityZone, game, .large)
        randomizeAsteroidLocationInWorld(asteroid, game.world)
        randomizeAsteroidRotationAndVelocity(asteroid)
        poolAdd(asteroids, asteroid)
    }
}

func pushCommand<T: RenderCommand>(_ renderBufferBase: RawPtr, _ command: T) {
    
    // Get the buffer header
    var header : RenderCommandBufferHeader = <<-renderBufferBase
    
    var pushCommandPtr = renderBufferBase
    if header.commandCount == 0 {
        
        // Find the first open memory, align, and store the pointer in the header
        pushCommandPtr = renderBufferBase + MemoryLayout.stride(ofValue: header)
        if Int(bitPattern: pushCommandPtr) % MemoryLayout.alignment(ofValue: command) != 0 {
            pushCommandPtr += MemoryLayout.alignment(ofValue: command) - (Int(bitPattern: pushCommandPtr) % MemoryLayout.alignment(ofValue: command))
        }
        
        header.firstCommandBase = pushCommandPtr
    }
    else {
        
        // Get the top of the queue, align to alignment of pushing command
        pushCommandPtr = header.lastCommandHead!
        if Int(bitPattern: pushCommandPtr) % MemoryLayout.alignment(ofValue: command) != 0 {
            pushCommandPtr += MemoryLayout.alignment(ofValue: command) - (Int(bitPattern: pushCommandPtr) % MemoryLayout.alignment(ofValue: command))
        }
        
        // View the last command as a header structure,
        // set the `next` pointer, and store it back in the buffer
        var commandHeader : RenderCommandHeader = <<-header.lastCommandBase!
        commandHeader.next = pushCommandPtr
        header.lastCommandBase! <<= commandHeader
        
    }
    
    // Push the new command
    pushCommandPtr <<= command
    
    // Update pointers
    header.lastCommandBase = pushCommandPtr
    header.lastCommandHead = pushCommandPtr + MemoryLayout.stride(ofValue: command)

    header.commandCount += 1
    renderBufferBase <<= header
    
}


var laserTimeToWait : Float = 0.0


// TODO: Rewrite completely. Needs to be dependent on dt otherwise will change speed depending on framerate
func simulate(_ gameMemory: GameMemory, _ game: GameStateRef, _ dt: Float, _ inputs: Inputs) {
    
    var world = game.world
    var ship = game.world.ship
    
    // Simulate Ship
    rotateEntity(ship, 0.1 * inputs.rotate)
    
    let accelFactor : Float = 0.005
    let maxVelocity : Float = 0.5
    
    if inputs.thrust {
        ship.dP.x += sin(ship.rot) * accelFactor
        ship.dP.y += cos(ship.rot) * accelFactor
        
        ship.dP.x = clamp(ship.dP.x, -maxVelocity, maxVelocity)
        ship.dP.y = clamp(ship.dP.y, -maxVelocity, maxVelocity)
    }
    
    ship.p += ship.dP
    
    ship.p.x = normalizeToRange(ship.p.x, -world.size.w / 2.0, world.size.w / 2.0)
    ship.p.y = normalizeToRange(ship.p.y, -world.size.h / 2.0, world.size.h / 2.0)
    
    
    // Simulate Asteroids
    for asteroidRef in game.world.asteroids {
        var asteroid = asteroidRef
        asteroid.rot += asteroid.dRot
        asteroid.rot = normalizeToRange(asteroid.rot, -FLOAT_PI, FLOAT_PI)
        
        asteroid.p += asteroid.dP
        
        asteroid.p.x = normalizeToRange(asteroid.p.x, -world.size.w / 2.0, world.size.w / 2.0)
        asteroid.p.y = normalizeToRange(asteroid.p.y, -world.size.h / 2.0, world.size.h / 2.0)
    }
    
    // Simulate Lasers
    let lasers = game.world.lasers
    laserTimeToWait -= dt
    if laserTimeToWait < 0.0 {
        laserTimeToWait = 0.0
    }
    
    if inputs.fire && ship.alive {
        if laserTimeToWait <= 0.0 {
            let laser = createLaser(gameMemory, game.entityZone, game, game.world.ship)
            circularBufferPush(lasers, laser)
            laserTimeToWait = 0.25
        }
    }
    
    
    for laserRef in game.world.lasers {
        var laser = laserRef
        if !laser.alive {
            continue
        }
        laser.timeAlive += dt
        if laser.timeAlive > laser.lifetime {
            laser.alive = false
            continue
        }
        laser.p += laser.dP
        laser.p.x = normalizeToRange(laser.p.x, -world.size.w / 2.0, world.size.w / 2.0)
        laser.p.y = normalizeToRange(laser.p.y, -world.size.h / 2.0, world.size.h / 2.0)
    }
    
    // Collision Detection - Laser to Asteroid
    asteroidLaserCollision: for (poolSlot, asteroidRef) in game.world.asteroids.enumeratedWithSlot() {
        var asteroid = asteroidRef
        
        for laserRef in lasers {
            var laser = laserRef
            
            if !laser.alive {
                continue
            }
            
            if torusDistance(game.world.size, laser.p, asteroid.p) < scaleForAsteroidSize(asteroid.size)  {
                poolRemoveAtIndex(game.world.asteroids, poolSlot)
                if asteroid.size != .small {
                    var newSize : Asteroid.AsteroidSize = .large
                    if asteroid.size == .large {
                        newSize = .medium
                    }
                    else if asteroid.size == .medium {
                        newSize = .small
                    }
                    
                    for _ in 0..<2 {
                        var newAsteroid = createAsteroid(gameMemory, game.entityZone, game, newSize)
                        newAsteroid.p = asteroid.p
                        
                        var velocityScale : Float = 0.02
                        if newSize == .medium {
                            velocityScale = 0.04
                        }
                        else if newSize == .small {
                            velocityScale = 0.06
                        }
                        
                        newAsteroid.dP.x = randomInRange(-velocityScale, velocityScale)
                        newAsteroid.dP.y = randomInRange(-velocityScale, velocityScale)
                        
                        randomizeAsteroidRotationAndVelocity(newAsteroid)
                        
                        poolAdd(game.world.asteroids, newAsteroid)
                    }
                }
                
                
                laser.alive = false
                
                break asteroidLaserCollision
            }
        }
    }
    
    // Collision Detection - Ship to Asteroid
    let p1 = ship.p + Vec2(0.0, 0.7)
    let p2 = ship.p + Vec2(0.5, -0.7)
    let p3 = ship.p + Vec2(-0.5, -0.7)
    
    for asteroid in game.world.asteroids {
        if torusDistance(game.world.size, asteroid.p, p1) < scaleForAsteroidSize(asteroid.size)
        || torusDistance(game.world.size, asteroid.p, p2) < scaleForAsteroidSize(asteroid.size)
        || torusDistance(game.world.size, asteroid.p, p3) < scaleForAsteroidSize(asteroid.size) {
            ship.alive = false
            break
        }
    }
    
}

func renderBlackBackground(_ gameMemory: GameMemory, _ gameRef: GameStateRef, _ renderBuffer: RawPtr) {
    var game = gameRef
    var command = RenderCommandTriangles()
    
    let world = game.world
    if game.vertexBuffers[World.renderableId] == nil || firstRun == true {
        let verts = [
            -(world.size.w / 2.0),  (world.size.height / 2.0), 0.0, 1.0, 0.0, 0.0, 0.0, 1.0,
             (world.size.w / 2.0),  (world.size.height / 2.0), 0.0, 1.0, 0.0, 0.0, 0.0, 1.0,
             (world.size.w / 2.0), -(world.size.height / 2.0), 0.0, 1.0, 0.0, 0.0, 0.0, 1.0,
            -(world.size.w / 2.0),  (world.size.height / 2.0), 0.0, 1.0, 0.0, 0.0, 0.0, 1.0,
             (world.size.w / 2.0), -(world.size.height / 2.0), 0.0, 1.0, 0.0, 0.0, 0.0, 1.0,
            -(world.size.w / 2.0), -(world.size.height / 2.0), 0.0, 1.0, 0.0, 0.0, 0.0, 1.0,
        ]
        game.vertexBuffers[World.renderableId] = gameMemory.platformCreateVertexBuffer(verts)
    }
    
    
    command.vertexBuffer = game.vertexBuffers[World.renderableId]
    command.transform = float4x4(1)
    command.vertexCount = 6
    
    pushCommand(renderBuffer, command)
}

func renderTerribleBackground(_ gameMemory: GameMemory, _ gameRef: GameStateRef, _ renderBuffer: RawPtr) {
    var game = gameRef
    var command = RenderCommandTriangles()
    
    let world = game.world
    if game.vertexBuffers[World.renderableId] == nil || firstRun == true {
        let verts = [
            -(world.size.w / 2.0),  (world.size.height / 2.0), 0.0, 1.0, 1.0, 0.0, 0.0, 1.0,
             (world.size.w / 2.0),  (world.size.height / 2.0), 0.0, 1.0, 0.0, 1.0, 0.0, 1.0,
             (world.size.w / 2.0), -(world.size.height / 2.0), 0.0, 1.0, 0.0, 0.0, 1.0, 1.0,
            -(world.size.w / 2.0),  (world.size.height / 2.0), 0.0, 1.0, 1.0, 0.0, 0.0, 1.0,
             (world.size.w / 2.0), -(world.size.height / 2.0), 0.0, 1.0, 0.0, 0.0, 1.0, 1.0,
            -(world.size.w / 2.0), -(world.size.height / 2.0), 0.0, 1.0, 0.0, 1.0, 0.0, 1.0,
        ]
        game.vertexBuffers[World.renderableId] = gameMemory.platformCreateVertexBuffer(verts)
    }
    
    command.vertexBuffer = game.vertexBuffers[World.renderableId]
    command.transform = float4x4(1)
    command.vertexCount = 6
    
    pushCommand(renderBuffer, command)
}

func renderShip(_ game: GameStateRef, _ renderBuffer: RawPtr) {
    let ship = game.world.ship
    if !ship.alive {
        return
    }
    
    let shipInstanceThreshold : Float = 1.0
    
    let shipX = ship.p.x
    let shipY = ship.p.y
    
    var command = RenderCommandTriangles()
    command.vertexBuffer = game.vertexBuffers[Ship.renderableId]
    command.transform = translateTransform(ship.p.x, ship.p.y) * rotateTransform(ship.rot)
    command.vertexCount = 3
    pushCommand(renderBuffer, command)
    
    let worldWidth = game.world.size.width
    let worldHeight = game.world.size.height
    
    if shipX < (-worldWidth / 2.0) + shipInstanceThreshold {
        
        command.transform = translateTransform(shipX + worldWidth, shipY) * rotateTransform(ship.rot)
        pushCommand(renderBuffer, command)
        
        if shipY < (-worldHeight / 2.0) + shipInstanceThreshold {
            command.transform = translateTransform(shipX + worldWidth, shipY + worldHeight) * rotateTransform(ship.rot)
            pushCommand(renderBuffer, command)
        }
        else if shipY > (worldHeight / 2.0) - shipInstanceThreshold {
            command.transform = translateTransform(shipX + worldWidth, shipY - worldHeight) * rotateTransform(ship.rot)
            pushCommand(renderBuffer, command)
        }
        
    }
    else if shipX > (worldWidth / 2.0) - shipInstanceThreshold {
        command.transform = translateTransform(shipX - worldWidth, shipY) * rotateTransform(ship.rot)
        pushCommand(renderBuffer, command)
        
        if shipY < (-worldHeight / 2.0) + shipInstanceThreshold {
            command.transform = translateTransform(shipX - worldWidth, shipY + worldHeight) * rotateTransform(ship.rot)
            pushCommand(renderBuffer, command)
        }
        else if shipY > (worldHeight / 2.0) - shipInstanceThreshold {
            command.transform = translateTransform(shipX - worldWidth, shipY - worldHeight) * rotateTransform(ship.rot)
            pushCommand(renderBuffer, command)
        }
        
    }
    
    if shipY < (-worldHeight / 2.0) + shipInstanceThreshold {
        command.transform = translateTransform(shipX, shipY + worldHeight) * rotateTransform(ship.rot)
        pushCommand(renderBuffer, command)
    }
    else if shipY > (worldHeight / 2.0) - shipInstanceThreshold {
        command.transform = translateTransform(shipX, shipY - worldHeight) * rotateTransform(ship.rot)
        pushCommand(renderBuffer, command)
    }
}

func renderAsteroids(_ game: GameStateRef, _ renderBuffer: RawPtr) {
    let asteroids = game.world.asteroids
    for asteroid in asteroids {
        
        let scale : Float = scaleForAsteroidSize(asteroid.size)
        
        let asteroidX = asteroid.p.x
        let asteroidY = asteroid.p.y
        
        var command = RenderCommandTriangles()
        command.vertexBuffer = game.vertexBuffers[Asteroid.renderableId]
        command.transform = translateTransform(asteroidX, asteroidY) * rotateTransform(asteroid.rot) * scaleTransform(scale, scale)
        command.vertexCount = 3 * 6
        pushCommand(renderBuffer, command)
        
        let worldWidth = game.world.size.width
        let worldHeight = game.world.size.height
        
        if asteroidX < (-worldWidth / 2.0) + scale {
            
            command.transform = translateTransform(asteroidX + worldWidth, asteroidY) * rotateTransform(asteroid.rot) * scaleTransform(scale, scale)
            pushCommand(renderBuffer, command)
            
            if asteroidY < (-worldHeight / 2.0) + scale {
                command.transform = translateTransform(asteroidX + worldWidth, asteroidY + worldHeight) * rotateTransform(asteroid.rot) * scaleTransform(scale, scale)
                pushCommand(renderBuffer, command)
            }
            else if asteroidY > (worldHeight / 2.0) - scale {
                command.transform = translateTransform(asteroidX + worldWidth, asteroidY - worldHeight) * rotateTransform(asteroid.rot) * scaleTransform(scale, scale)
                pushCommand(renderBuffer, command)
            }
            
        }
        else if asteroidX > (worldWidth / 2.0) - scale {
            
            command.transform = translateTransform(asteroidX - worldWidth, asteroidY) * rotateTransform(asteroid.rot) * scaleTransform(scale, scale)
            pushCommand(renderBuffer, command)
            
            if asteroidY < (-worldHeight / 2.0) + scale {
                command.transform = translateTransform(asteroidX - worldWidth, asteroidY + worldHeight) * rotateTransform(asteroid.rot) * scaleTransform(scale, scale)
                pushCommand(renderBuffer, command)
            }
            else if asteroidY > (worldHeight / 2.0) - scale {
                command.transform = translateTransform(asteroidX - worldWidth, asteroidY - worldHeight) * rotateTransform(asteroid.rot) * scaleTransform(scale, scale)
                pushCommand(renderBuffer, command)
            }
            
        }
        
        if asteroidY < (-worldHeight / 2.0) + scale {
            command.transform = translateTransform(asteroidX, asteroidY + worldHeight) * rotateTransform(asteroid.rot) * scaleTransform(scale, scale)
            pushCommand(renderBuffer, command)
        }
        else if asteroidY > (worldHeight / 2.0) - scale {
            command.transform = translateTransform(asteroidX, asteroidY - worldHeight) * rotateTransform(asteroid.rot) * scaleTransform(scale, scale)
            pushCommand(renderBuffer, command)
        }
        
    }
}

func renderLasers(_ game: GameStateRef, _ renderBuffer: RawPtr) {
    let lasers = game.world.lasers
    for laser in lasers {
        if !laser.alive {
            continue
        }
        
        var command = RenderCommandTriangles()
        command.vertexBuffer = game.vertexBuffers[Laser.renderableId]
        command.transform = translateTransform(laser.p.x, laser.p.y) * scaleTransform(0.03, 0.03)
        command.vertexCount = 3 * 2
        
        pushCommand(renderBuffer, command)
    }
    
}

func translateTransform(_ x: Float, _ y: Float) -> float4x4 {
    var transform = float4x4(1)
    transform[3][0] = x
    transform[3][1] = y
    return transform
}

func rotateTransform(_ theta: Float) -> float4x4 {
    var transform = float4x4(1)
    transform[0][0] =  cos(theta)
    transform[0][1] = -sin(theta)
    transform[1][0] =  sin(theta)
    transform[1][1] =  cos(theta)
    return transform
}

func scaleTransform(_ x: Float, _ y: Float) -> float4x4 {
    var transform = float4x4(1)
    transform[0][0] = x
    transform[1][1] = y
    return transform
}
