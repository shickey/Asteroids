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
prefix func ^<T>(_ ref : Ref<T>) -> T {
    return ref.ptr.pointee
}

let NUM_ASTEROIDS = 3

/*= BEGIN_REFSTRUCT =*/
struct GameState {
    var gameInitialized : Bool /*= GETSET =*/
    var world : WorldRef /*= GETSET =*/

    var zoneZone : MemoryZone /*= GETSET =*/
    var entityZone : MemoryZoneRef /*= GETSET =*/
    var assetZone : MemoryZoneRef /*= GETSET =*/
    
    var renderables : HashTableRef<RenderableId, RenderableRef> /*= GETSET =*/
}
/*= END_REFSTRUCT =*/


/*= BEGIN_REFSTRUCT =*/
struct World {
    static var renderableId : RenderableId = 0x01
    var size : Size /*= GETSET =*/
    var entities : BucketArrayRef<EntityBase> /*= GETSET =*/
    var ship : ShipRef /*= GETSET =*/
    var asteroids : BucketArrayRef<Asteroid> /*= GETSET =*/
    var lasers : CircularBufferRef<LaserRef> /*= GETSET =*/
}
/*= END_REFSTRUCT =*/


/*= BEGIN_REFSTRUCT =*/
struct DebugState {
    var initialized : Bool /*= GETSET =*/
    var simulating : Bool /*= GETSET =*/
    var simulationTimeFactor : Float /*= GETSET =*/
    var zoom : Float /*= GETSET =*/
    
    var font : BitmapFontRef /*= GETSET =*/
    var selectedEntityId : EntityId /*= GETSET =*/
}
/*= END_REFSTRUCT =*/


var firstRun = true // This feels wrong, but is useful for doing things on game code reload boundaries

var restarting = false

@_silgen_name("updateAndRender")
public func updateAndRender(_ gameMemoryPtr: UnsafeMutablePointer<GameMemory>, inputsPtr: UnsafeMutablePointer<Inputs>, renderCommandHeaderPtr: UnsafeMutablePointer<RenderCommandBufferHeader>) {
    
    let gameMemory = gameMemoryPtr.pointee
    let inputs = inputsPtr.pointee
    
    let gameStatePtr : Ptr<GameState> = <-gameMemory.permanentStorage
    let gameState = GameStateRef(gameStatePtr)
    
    if !gameState.gameInitialized {
        /*= TIMED_BLOCK =*/ TIMED_BLOCK_BEGIN(1); defer { TIMED_BLOCK_END(1) };

        gameState.zoneZone.base = gameMemory.permanentStorage + MemoryLayout<GameState>.size
        gameState.zoneZone.size = 1.megabytes
        
        let entityZoneBase = gameState.zoneZone.base + gameState.zoneZone.size
        let entityZoneSize = 32.megabytes
        
        gameState.entityZone = createZone(&gameState.zoneZone, entityZoneBase, entityZoneSize)
        
        let assetZoneBase = entityZoneBase + entityZoneSize
        let assetZoneSize = gameMemory.permanentStorageSize - (MemoryLayout<GameState>.size + gameState.zoneZone.size + entityZoneSize)
        
        gameState.assetZone = createZone(&gameState.zoneZone, assetZoneBase, assetZoneSize)
        
        gameState.renderables = createHashTable(gameState.entityZone, 37) // Use a large-enough prime to help hash distribution
        
        let world = createWorld(gameState.entityZone)
        gameState.world = world
        
        world.size = Size(20.0, 20.0)
        world.entities = createBucketArray(gameState.entityZone, EntityBase.self, 64)
        
        let ship = createShip(gameMemory, gameState.entityZone, gameState)
        world.ship = ship

        world.asteroids = createBucketArray(gameState.entityZone, Asteroid.self, U64(NUM_ASTEROIDS))
        for _ in 0..<NUM_ASTEROIDS {
            let asteroid = createAsteroid(gameMemory, gameState.entityZone, gameState, .large)
            randomizeAsteroidLocationInWorld(asteroid, world)
            randomizeAsteroidRotationAndVelocity(asteroid)
        }
        
        let MAX_LASERS = 12
        world.lasers = createCircularBuffer(gameState.entityZone, type: LaserRef.self, count: MAX_LASERS)
        
        
        gameState.gameInitialized = true
    }
    
    let debugStatePtr : Ptr<DebugState> = <-gameMemory.debugStorage
    let debugState = DebugStateRef(debugStatePtr)
    
    if !debugState.initialized {
        debugState.simulating = true
        debugState.simulationTimeFactor = 1.0
        debugState.zoom = 1.0
        debugState.selectedEntityId = InvalidEntityId
        
        debugState.font = loadBitmapFont(gameState.assetZone, "arial-12-white-blackstroke.txt")
        
        debugState.initialized = true
    }
    
    if !restarting && inputs.restart {
        restarting = true
        restartGame(gameMemory, gameState, debugState)
    }
    else if restarting && !inputs.restart {
        restarting = false
    }
    
    // Simulate
    if debugState.simulating {
        simulate(gameMemory, gameState, inputs.dt, inputs, debugState)
    }
    
    // Render
    let renderBuffer = Ptr(renderCommandHeaderPtr)
    let renderBufferHeader = renderCommandHeaderPtr.pointee
    
    var options = RenderCommandOptions()
    options.fillMode = .fill
    pushCommand(renderBuffer, options)
    
    let scaleFactor = max(gameState.world.size.width, gameState.world.size.height) * debugState.zoom
    var worldTransform = Transform(1)
    worldTransform[0][0] = 1.0 / (scaleFactor / 2.0)
    worldTransform[1][1] = 1.0 / (scaleFactor / 2.0)
    
    var uniforms = RenderCommandUniforms()
    uniforms.transform = worldTransform
    pushCommand(renderBuffer, uniforms)
    
    renderBlackBackground(gameMemory, gameState, renderBuffer)
    
    renderAsteroids(gameState, renderBuffer)
    renderShip(gameState, renderBuffer)
    renderLasers(gameState, renderBuffer)
    
    
    
    // Check for entity selection
    // TODO: Can we generalize this and just iterate over all the entity bases?
    //       If so, how do we access the "derived" entity from its base?
    let mouseWorldLocation = windowToWorldCoordinates(inputs.mouse, renderBufferHeader.windowSize, gameState, debugState)
    for entityPtr in gameState.world.entities {
        let entity = EntityBaseRef(entityPtr)
        if hitTest(gameState, mouseWorldLocation, entity) {
            renderBoundingBoxOnTorus(entity, gameState, renderBuffer)
            if inputs.mouseClicked {
                debugState.selectedEntityId = entity.id
            }
        }
    }
    
    
    let selectedId = debugState.selectedEntityId
    if selectedId != InvalidEntityId {
        /*= TIMED_BLOCK =*/ TIMED_BLOCK_BEGIN(2); defer { TIMED_BLOCK_END(2) };
        
        let locator : BucketLocator = (selectedId / 64, selectedId % 64)
        if let selectedPtr = gameState.world.entities[locator] {
            let selected = EntityBaseRef(selectedPtr)
            
            
            var debugInfoOpt : DebugStruct? = nil
            if gameState.world.ship.id == selectedId {
                debugInfoOpt = debugEntity(gameState.world.ship)
            }
            else {
                for asteroidPtr in gameState.world.asteroids {
                    let asteroid = AsteroidRef(asteroidPtr)
                    if asteroid.id == selectedId {
                        debugInfoOpt = debugEntity(asteroid)
                        break
                    }
                }
                if debugInfoOpt == nil {
                    for laser in gameState.world.lasers {
                        if laser.id == selectedId {
                            debugInfoOpt = debugEntity(laser)
                            break
                        }
                    }
                }
            }
            
            
            if let debugInfo = debugInfoOpt {
                renderBoundingBoxOnTorus(selected, gameState, renderBuffer)
                
                var textOrigin = Vec2(0.0, renderBufferHeader.windowSize.h - debugState.font.lineHeight)
                pushCommand(renderBuffer, renderText(debugInfo.name, renderBufferHeader.windowSize, textOrigin, debugState.font, renderBuffer))
                textOrigin.y -= debugState.font.lineHeight
                for (name, value) in debugInfo.entries {
                    pushCommand(renderBuffer, renderText("  \(name): \(value)", renderBufferHeader.windowSize, textOrigin, debugState.font, renderBuffer))
                    textOrigin.y -= debugState.font.lineHeight
                }
            }
            else {
                print("Unable to get debug info for selected entity")
            }
        }
        else {
            debugState.selectedEntityId = InvalidEntityId
        }
        
        
        
    }
    
    // Debug print number of live entities
    pushCommand(renderBuffer, renderText("Live Entities: \(gameState.world.entities.used)", renderBufferHeader.windowSize, Vec2(renderBufferHeader.windowSize.w / 2.0, renderBufferHeader.windowSize.h - debugState.font.lineHeight), debugState.font, renderBuffer))
    
    firstRun = false
}

func restartGame(_ gameMemory: GameMemory, _ gameState: GameStateRef, _ debugState: DebugStateRef) {
    /*= TIMED_BLOCK =*/ TIMED_BLOCK_BEGIN(3); defer { TIMED_BLOCK_END(3) };
    bucketArrayClear(gameState.world.asteroids)
    bucketArrayClear(gameState.world.entities)
    clearCircularBuffer(gameState.world.lasers)
    
    // Reset ship
    gameState.world.ship = createShip(gameMemory, gameState.entityZone, gameState)
    
    // Reset asteroids
    for _ in 0..<NUM_ASTEROIDS {
        let asteroid = createAsteroid(gameMemory, gameState.entityZone, gameState, .large)
        randomizeAsteroidLocationInWorld(asteroid, gameState.world)
        randomizeAsteroidRotationAndVelocity(asteroid)
        
    }
    
    // Reset debug state
    debugState.selectedEntityId = InvalidEntityId
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

func simulate(_ gameMemory: GameMemory, _ gameState: GameStateRef, _ dt: Float, _ inputs: Inputs, _ debugState: DebugStateRef) {
    
    /*= TIMED_BLOCK =*/ TIMED_BLOCK_BEGIN(4); defer { TIMED_BLOCK_END(4) };

    let dt = dt * Float(debugState.simulationTimeFactor)
    
    let world = gameState.world
    var ship = gameState.world.ship
    
    // Simulate Ship
    rotateEntity(ship, 6.0 * inputs.rotate * dt)
    
    let accelFactor : Float = 10.0
    let maxVelocity : Float = 60.0
    
    if inputs.thrust {
        ship.dP.x += sin(ship.rot) * accelFactor * dt
        ship.dP.y += cos(ship.rot) * accelFactor * dt
        
        ship.dP.x = clamp(ship.dP.x, -maxVelocity, maxVelocity)
        ship.dP.y = clamp(ship.dP.y, -maxVelocity, maxVelocity)
    }
    
    ship.p += ship.dP * dt
    
    ship.p.x = normalizeToRange(ship.p.x, -world.size.w / 2.0, world.size.w / 2.0)
    ship.p.y = normalizeToRange(ship.p.y, -world.size.h / 2.0, world.size.h / 2.0)
    
    
    // Simulate Asteroids
    for asteroidPtr in gameState.world.asteroids {
        var asteroid = AsteroidRef(asteroidPtr)
        asteroid.rot += asteroid.dRot * dt
        asteroid.rot = normalizeToRange(asteroid.rot, -FLOAT_PI, FLOAT_PI)
        
        asteroid.p += asteroid.dP * dt
        
        asteroid.p.x = normalizeToRange(asteroid.p.x, -world.size.w / 2.0, world.size.w / 2.0)
        asteroid.p.y = normalizeToRange(asteroid.p.y, -world.size.h / 2.0, world.size.h / 2.0)
    }
    
    // Simulate Lasers
    let lasers = gameState.world.lasers
    laserTimeToWait -= dt
    if laserTimeToWait < 0.0 {
        laserTimeToWait = 0.0
    }
    
    if inputs.fire && ship.alive {
        if laserTimeToWait <= 0.0 {
            let laser = createLaser(gameMemory, gameState.entityZone, gameState, gameState.world.ship)
            circularBufferPush(lasers, laser)
            laserTimeToWait = 0.25
        }
    }
    
    
    for laserRef in gameState.world.lasers {
        var laser = laserRef
        if !laser.alive {
            continue
        }
        laser.timeAlive += dt
        if laser.timeAlive > laser.lifetime {
            laser.alive = false
            destroyEntity(gameState, laser)
            continue
        }
        laser.p += laser.dP * dt
        laser.p.x = normalizeToRange(laser.p.x, -world.size.w / 2.0, world.size.w / 2.0)
        laser.p.y = normalizeToRange(laser.p.y, -world.size.h / 2.0, world.size.h / 2.0)
    }
    
    // Collision Detection - Laser to Asteroid
    asteroidLaserCollision: for asteroidPtr in gameState.world.asteroids {
        let asteroid = AsteroidRef(asteroidPtr)
        for laser in lasers {
            if !laser.alive {
                continue
            }
            
            if torusDistance(gameState.world.size, laser.p, asteroid.p) < scaleForAsteroidSize(asteroid.size)  {
                if asteroid.size != .small {
                    var newSize : Asteroid.AsteroidSize = .large
                    if asteroid.size == .large {
                        newSize = .medium
                    }
                    else if asteroid.size == .medium {
                        newSize = .small
                    }
                    
                    for _ in 0..<2 {
                        var newAsteroid = createAsteroid(gameMemory, gameState.entityZone, gameState, newSize)
                        newAsteroid.p = asteroid.p
                        
                        randomizeAsteroidRotationAndVelocity(newAsteroid)
                    }
                }
                bucketArrayRemove(gameState.world.asteroids, asteroid.asteroidLocator)
                destroyEntity(gameState, asteroid)
                
                laser.alive = false
                destroyEntity(gameState, laser)
                
                break asteroidLaserCollision
            }
        }
    }
    
    // Collision Detection - Ship to Asteroid
    let p1 = ship.p + Vec2(0.0, 0.7)
    let p2 = ship.p + Vec2(0.5, -0.7)
    let p3 = ship.p + Vec2(-0.5, -0.7)
    
    for asteroidPtr in gameState.world.asteroids {
        let asteroid = AsteroidRef(asteroidPtr)
        if torusDistance(gameState.world.size, asteroid.p, p1) < scaleForAsteroidSize(asteroid.size)
        || torusDistance(gameState.world.size, asteroid.p, p2) < scaleForAsteroidSize(asteroid.size)
        || torusDistance(gameState.world.size, asteroid.p, p3) < scaleForAsteroidSize(asteroid.size) {
            ship.alive = false
            break
        }
    }
    
}

func renderBlackBackground(_ gameMemory: GameMemory, _ gameState: GameStateRef, _ renderBuffer: RawPtr) {
    var command = RenderCommandTriangles()
    
    let world = gameState.world
    if gameState.renderables[World.renderableId] == nil || firstRun == true {
        let verts = [
            -(world.size.w / 2.0),  (world.size.height / 2.0), 0.0, 1.0, 0.0, 0.0, 0.0, 1.0,
             (world.size.w / 2.0),  (world.size.height / 2.0), 0.0, 1.0, 0.0, 0.0, 0.0, 1.0,
             (world.size.w / 2.0), -(world.size.height / 2.0), 0.0, 1.0, 0.0, 0.0, 0.0, 1.0,
            -(world.size.w / 2.0),  (world.size.height / 2.0), 0.0, 1.0, 0.0, 0.0, 0.0, 1.0,
             (world.size.w / 2.0), -(world.size.height / 2.0), 0.0, 1.0, 0.0, 0.0, 0.0, 1.0,
            -(world.size.w / 2.0), -(world.size.height / 2.0), 0.0, 1.0, 0.0, 0.0, 0.0, 1.0,
        ]
        let renderable = createRenderable(gameState.entityZone, gameState, gameMemory, verts)
        gameState.renderables[World.renderableId] = renderable
    }
    
    
    command.vertexBuffer = gameState.renderables[World.renderableId]!.vertexBuffer
    command.transform = Transform(1)
    command.vertexCount = 6
    
    pushCommand(renderBuffer, command)
}

func renderTerribleBackground(_ gameMemory: GameMemory, _ gameState: GameStateRef, _ renderBuffer: RawPtr) {
    var command = RenderCommandTriangles()
    
    let world = gameState.world
    if gameState.renderables[World.renderableId] == nil || firstRun == true {
        let verts = [
            -(world.size.w / 2.0),  (world.size.height / 2.0), 0.0, 1.0, 1.0, 0.0, 0.0, 1.0,
             (world.size.w / 2.0),  (world.size.height / 2.0), 0.0, 1.0, 0.0, 1.0, 0.0, 1.0,
             (world.size.w / 2.0), -(world.size.height / 2.0), 0.0, 1.0, 0.0, 0.0, 1.0, 1.0,
            -(world.size.w / 2.0),  (world.size.height / 2.0), 0.0, 1.0, 1.0, 0.0, 0.0, 1.0,
             (world.size.w / 2.0), -(world.size.height / 2.0), 0.0, 1.0, 0.0, 0.0, 1.0, 1.0,
            -(world.size.w / 2.0), -(world.size.height / 2.0), 0.0, 1.0, 0.0, 1.0, 0.0, 1.0,
        ]
        let renderable = createRenderable(gameState.entityZone, gameState, gameMemory, verts)
        gameState.renderables[World.renderableId] = renderable
    }
    
    command.vertexBuffer = gameState.renderables[World.renderableId]!.vertexBuffer
    command.transform = Transform(1)
    command.vertexCount = 6
    
    pushCommand(renderBuffer, command)
}

func renderBoundingBoxOnTorus(_ entity: EntityBaseRef, _ gameState: GameStateRef, _ renderBuffer: RawPtr) {
    let pX = entity.p.x
    let pY = entity.p.y
    let rot = entity.rot
    let scale = entity.scale
    
    let renderable = gameState.renderables[entity.renderableId]!
    
    var boundingBoxCommand = RenderCommandPolyline()
    boundingBoxCommand.vertexBuffer = renderable.boundingBoxBuffer
    boundingBoxCommand.transform = translateTransform(pX, pY) * rotateTransform(rot) * scaleTransform(scale, scale)
    boundingBoxCommand.vertexCount = 5 // Always 5 vertices for a polyline bounding box
    pushCommand(renderBuffer, boundingBoxCommand)
    
    let worldWidth = gameState.world.size.width
    let worldHeight = gameState.world.size.height
    
    if pX < (-worldWidth / 2.0) + scale {
        
        let transform = translateTransform(pX + worldWidth, pY) * rotateTransform(rot) * scaleTransform(scale, scale)
        boundingBoxCommand.transform = transform
        pushCommand(renderBuffer, boundingBoxCommand)
        
        if pY < (-worldHeight / 2.0) + scale {
            let transform = translateTransform(pX + worldWidth, pY + worldHeight) * rotateTransform(rot) * scaleTransform(scale, scale)
            boundingBoxCommand.transform = transform
            pushCommand(renderBuffer, boundingBoxCommand)
        }
        else if pY > (worldHeight / 2.0) - scale {
            let transform = translateTransform(pX + worldWidth, pY - worldHeight) * rotateTransform(rot) * scaleTransform(scale, scale)
            boundingBoxCommand.transform = transform
            pushCommand(renderBuffer, boundingBoxCommand)
        }
        
    }
    else if pX > (worldWidth / 2.0) - scale {
        
        let transform = translateTransform(pX - worldWidth, pY) * rotateTransform(rot) * scaleTransform(scale, scale)
        boundingBoxCommand.transform = transform
        pushCommand(renderBuffer, boundingBoxCommand)
        
        if pY < (-worldHeight / 2.0) + scale {
            let transform = translateTransform(pX - worldWidth, pY + worldHeight) * rotateTransform(rot) * scaleTransform(scale, scale)
            boundingBoxCommand.transform = transform
            pushCommand(renderBuffer, boundingBoxCommand)
        }
        else if pY > (worldHeight / 2.0) - scale {
            let transform = translateTransform(pX - worldWidth, pY - worldHeight) * rotateTransform(rot) * scaleTransform(scale, scale)
            boundingBoxCommand.transform = transform
            pushCommand(renderBuffer, boundingBoxCommand)
        }
        
    }
    
    if pY < (-worldHeight / 2.0) + scale {
        let transform = translateTransform(pX, pY + worldHeight) * rotateTransform(rot) * scaleTransform(scale, scale)
        boundingBoxCommand.transform = transform
        pushCommand(renderBuffer, boundingBoxCommand)
    }
    else if pY > (worldHeight / 2.0) - scale {
        let transform = translateTransform(pX, pY - worldHeight) * rotateTransform(rot) * scaleTransform(scale, scale)
        boundingBoxCommand.transform = transform
        pushCommand(renderBuffer, boundingBoxCommand)
    }
    
}

func renderEntityOnTorus(_ entity: Entity, _ gameState: GameStateRef, _ renderBuffer: RawPtr) {
    let pX = entity.p.x
    let pY = entity.p.y
    let rot = entity.rot
    let scale = entity.scale
    
    let renderable = gameState.renderables[entity.base.renderableId]!
    
    var command = RenderCommandTriangles()
    command.vertexBuffer = renderable.vertexBuffer
    command.transform = translateTransform(pX, pY) * rotateTransform(rot) * scaleTransform(scale, scale)
    command.vertexCount = renderable.vertexCount
    pushCommand(renderBuffer, command)
    
    let worldWidth = gameState.world.size.width
    let worldHeight = gameState.world.size.height
    
    if pX < (-worldWidth / 2.0) + scale {
        
        let transform = translateTransform(pX + worldWidth, pY) * rotateTransform(rot) * scaleTransform(scale, scale)
        command.transform = transform
        pushCommand(renderBuffer, command)
        
        if pY < (-worldHeight / 2.0) + scale {
            let transform = translateTransform(pX + worldWidth, pY + worldHeight) * rotateTransform(rot) * scaleTransform(scale, scale)
            command.transform = transform
            pushCommand(renderBuffer, command)
        }
        else if pY > (worldHeight / 2.0) - scale {
            let transform = translateTransform(pX + worldWidth, pY - worldHeight) * rotateTransform(rot) * scaleTransform(scale, scale)
            command.transform = transform
            pushCommand(renderBuffer, command)
        }
        
    }
    else if pX > (worldWidth / 2.0) - scale {
        
        let transform = translateTransform(pX - worldWidth, pY) * rotateTransform(rot) * scaleTransform(scale, scale)
        command.transform = transform
        pushCommand(renderBuffer, command)
        
        if pY < (-worldHeight / 2.0) + scale {
            let transform = translateTransform(pX - worldWidth, pY + worldHeight) * rotateTransform(rot) * scaleTransform(scale, scale)
            command.transform = transform
            pushCommand(renderBuffer, command)
        }
        else if pY > (worldHeight / 2.0) - scale {
            let transform = translateTransform(pX - worldWidth, pY - worldHeight) * rotateTransform(rot) * scaleTransform(scale, scale)
            command.transform = transform
            pushCommand(renderBuffer, command)
        }
        
    }
    
    if pY < (-worldHeight / 2.0) + scale {
        let transform = translateTransform(pX, pY + worldHeight) * rotateTransform(rot) * scaleTransform(scale, scale)
        command.transform = transform
        pushCommand(renderBuffer, command)
    }
    else if pY > (worldHeight / 2.0) - scale {
        let transform = translateTransform(pX, pY - worldHeight) * rotateTransform(rot) * scaleTransform(scale, scale)
        command.transform = transform
        pushCommand(renderBuffer, command)
    }

}

func renderShip(_ gameState: GameStateRef, _ renderBuffer: RawPtr) {
    let ship = gameState.world.ship
    if !ship.alive {
        return
    }
    
    renderEntityOnTorus(ship, gameState, renderBuffer)
}

func renderAsteroids(_ gameState: GameStateRef, _ renderBuffer: RawPtr) {
    let asteroids = gameState.world.asteroids
    for asteroidPtr in asteroids {
        let asteroid = AsteroidRef(asteroidPtr)
        renderEntityOnTorus(asteroid, gameState, renderBuffer)
    }
}

func renderLasers(_ gameState: GameStateRef, _ renderBuffer: RawPtr) {
    let lasers = gameState.world.lasers
    for laser in lasers {
        if !laser.alive {
            continue
        }
        
        var command = RenderCommandTriangles()
        command.vertexBuffer = gameState.renderables[Laser.renderableId]!.vertexBuffer
        command.transform = translateTransform(laser.p.x, laser.p.y) * scaleTransform(0.03, 0.03)
        command.vertexCount = 3 * 2
        
        pushCommand(renderBuffer, command)
    }
}
