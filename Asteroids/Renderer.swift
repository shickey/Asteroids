//
//  Renderer.swift
//  Asteroids
//
//  Created by Sean Hickey on 12/5/16.
//  Copyright © 2016 Sean Hickey. All rights reserved.
//

import Darwin
import simd

struct DEBUG_STRUCT {
    let ZOOM_OUT = false
    let BACKGROUND = false
}

let DEBUG = DEBUG_STRUCT()

struct GameState {
    var gameInitialized = false
}

struct World {
    var size = Size(20.0, 20.0)
}

var levelInitialized = false

var world = World()
var ship = Ship()
var asteroids = Set<Asteroid>()
var lasers = Set<Laser>()

var font : BitmapFont! = nil

var worldTransform = float4x4(1)



func gameInit(_ gameStatePtr: UnsafeMutablePointer<GameState>) {
    
    var gameState = gameStatePtr.pointee
    
    font = BitmapFont(loadTextAsset("bad-font.txt")!)
    
    // Set world scaling
    let scaleFactor = max(world.size.width, world.size.height)
    worldTransform[0][0] = 1.0 / (scaleFactor / 2.0)
    worldTransform[1][1] = 1.0 / (scaleFactor / 2.0)
    
    if DEBUG.ZOOM_OUT {
        worldTransform[0][0] = 1.0 / scaleFactor
        worldTransform[1][1] = 1.0 / scaleFactor
    }
    
    gameState.gameInitialized = true
    
    UnsafeMutableRawPointer(gameStatePtr).storeBytes(of: gameState, as: GameState.self)
}

func levelInit() {

    world = World()
    ship = Ship()
    asteroids = Set<Asteroid>()
    lasers = Set<Laser>()
    
    for _ in 0..<3 {
        var a : Asteroid
        repeat {
            a = Asteroid(world, .large)
        } while distance(a.p, ship.p) < (scaleForAsteroidSize(.large) * 2.0) // Prevent an asteroid from spawning right on top of the ship
        asteroids.insert(a)
    }
    
    levelInitialized = true
}

var restarting = false

public func updateAndRender(_ gameMemoryPtr: UnsafeMutablePointer<GameMemory>, inputsPtr: UnsafeMutablePointer<Inputs>, renderCommandHeaderPtr: UnsafeMutablePointer<RenderCommandBufferHeader>) {
    
    let gameMemory = gameMemoryPtr.pointee
    let inputs = inputsPtr.pointee
    
    let gameStatePtr = gameMemory.permanent.bindMemory(to: GameState.self, capacity: 1)


    let gameState = gameStatePtr.pointee
    
    if !gameState.gameInitialized {
        gameInit(gameStatePtr)
    }
    
    if !levelInitialized || (inputs.restart && !restarting) {
        restarting = true
        levelInit()
    }
    
    if !inputs.restart {
        restarting = false
    }
    
    
    // Simulate
    
    simulate(inputs.dt, inputs)
    
    
    // Render
    let renderBuffer = UnsafeMutableRawPointer(renderCommandHeaderPtr)

    var options = RenderCommandOptions()
    options.fillMode = .fill
    pushCommand(renderBuffer, options)
    
    
    var uniforms = RenderCommandUniforms()
    uniforms.transform = worldTransform
    pushCommand(renderBuffer, uniforms)
    
    
    if DEBUG.BACKGROUND {
        renderTerribleBackground(renderBuffer)
    }
    else {
        renderBlackBackground(renderBuffer)
    }
    renderAsteroids(renderBuffer)
    renderShip(renderBuffer)
    renderLasers(renderBuffer)
    
    let command = renderText(renderBuffer, "(Hello, world!)?", font)
    pushCommand(renderBuffer, command)
    
}

func pushCommand<T: RenderCommand>(_ renderBufferBase: RawPtr, _ command: T) {
    
    // Get the buffer header
    var header = renderBufferBase.bindMemory(to: RenderCommandBufferHeader.self, capacity: 1).pointee
    
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
        var commandHeader = header.lastCommandBase!.bindMemory(to: RenderCommandHeader.self, capacity: 1).pointee
        commandHeader.next = pushCommandPtr
        header.lastCommandBase!.storeBytes(of: commandHeader, as: RenderCommandHeader.self)
        
    }
    
    // Push the new command
    pushCommandPtr.storeBytes(of: command, as: T.self)
    
    // Update pointers
    header.lastCommandBase = pushCommandPtr
    header.lastCommandHead = pushCommandPtr + MemoryLayout.stride(ofValue: command)

    header.commandCount += 1
    renderBufferBase.storeBytes(of: header, as: RenderCommandBufferHeader.self)
    
}


var laserTimeToWait : Float = 0.0


// TODO: Rewrite completely. Needs to be dependent on dt otherwise will change speed depending on framerate
func simulate(_ dt: Float, _ inputs: Inputs) {
    
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
    
    ship.p.x += ship.dP.x
    ship.p.y += ship.dP.y
    
    ship.p.x = normalizeToRange(ship.p.x, -world.size.w / 2.0, world.size.w / 2.0)
    ship.p.y = normalizeToRange(ship.p.y, -world.size.h / 2.0, world.size.h / 2.0)
    
    // Simulate Asteroids
    for asteroid in asteroids {
        asteroid.rot += asteroid.dRot
        asteroid.rot = normalizeToRange(asteroid.rot, -FLOAT_PI, FLOAT_PI)
        
        asteroid.p.x += asteroid.dP.x
        asteroid.p.y += asteroid.dP.y
        
        asteroid.p.x = normalizeToRange(asteroid.p.x, -world.size.w / 2.0, world.size.w / 2.0)
        asteroid.p.y = normalizeToRange(asteroid.p.y, -world.size.h / 2.0, world.size.h / 2.0)
    }
    
    // Simulate Lasers
    laserTimeToWait -= dt
    if laserTimeToWait < 0.0 {
        laserTimeToWait = 0.0
    }
    
    if inputs.fire {
        if laserTimeToWait <= 0.0 {
            lasers.insert(Laser(ship))
            laserTimeToWait = 0.25
        }
    }
    
    for laser in lasers {
        laser.timeAlive += dt
        if laser.timeAlive > laser.lifetime {
            lasers.remove(laser)
            continue
        }
        laser.p += laser.dP
        laser.p.x = normalizeToRange(laser.p.x, -world.size.w / 2.0, world.size.w / 2.0)
        laser.p.y = normalizeToRange(laser.p.y, -world.size.h / 2.0, world.size.h / 2.0)
    }
    
    // Collision Detection - Laser to Asteroid
    for asteroid in asteroids {
        for laser in lasers {
            if distance(laser.p, asteroid.p) < scaleForAsteroidSize(asteroid.size)  {
                if asteroid.size == .large {
                    asteroids.insert(Asteroid(asteroid.p, .medium))
                    asteroids.insert(Asteroid(asteroid.p, .medium))
                }
                else if asteroid.size == .medium {
                    asteroids.insert(Asteroid(asteroid.p, .small))
                    asteroids.insert(Asteroid(asteroid.p, .small))
                }
                
                lasers.remove(laser)
                asteroids.remove(asteroid)
            }
        }
    }
    
    // Collision Detection - Ship to Asteroid
    let p1 = ship.p + Vec2(0.0, 0.7)
    let p2 = ship.p + Vec2(0.5, -0.7)
    let p3 = ship.p + Vec2(-0.5, -0.7)
    
    for asteroid in asteroids {
        if distance(asteroid.p, p1) < scaleForAsteroidSize(asteroid.size)
        || distance(asteroid.p, p2) < scaleForAsteroidSize(asteroid.size)
        || distance(asteroid.p, p3) < scaleForAsteroidSize(asteroid.size) {
            ship.alive = false
            break
        }
    }
    
}

func renderBlackBackground(_ renderBuffer: RawPtr) {
    var command = RenderCommandTriangles()
    
    let verts = UnsafeMutablePointer<Float>.allocate(capacity: 6 * 8)
    let vData = [
        -(world.size.w / 2.0),  (world.size.height / 2.0), 0.0, 1.0, 0.0, 0.0, 0.0, 1.0,
         (world.size.w / 2.0),  (world.size.height / 2.0), 0.0, 1.0, 0.0, 0.0, 0.0, 1.0,
         (world.size.w / 2.0), -(world.size.height / 2.0), 0.0, 1.0, 0.0, 0.0, 0.0, 1.0,
        -(world.size.w / 2.0),  (world.size.height / 2.0), 0.0, 1.0, 0.0, 0.0, 0.0, 1.0,
         (world.size.w / 2.0), -(world.size.height / 2.0), 0.0, 1.0, 0.0, 0.0, 0.0, 1.0,
        -(world.size.w / 2.0), -(world.size.height / 2.0), 0.0, 1.0, 0.0, 0.0, 0.0, 1.0,
        ]
    
    memcpy(verts, vData, vData.count * MemoryLayout<Float>.size)
    
    command.verts = verts
    command.transform = float4x4(1)
    command.count = 8 * 6
    
    pushCommand(renderBuffer, command)
}

func renderTerribleBackground(_ renderBuffer: RawPtr) {
    var command = RenderCommandTriangles()
    
    let verts = UnsafeMutablePointer<Float>.allocate(capacity: 6 * 8)
    let vData = [
        -(world.size.w / 2.0),  (world.size.height / 2.0), 0.0, 1.0, 1.0, 0.0, 0.0, 1.0,
         (world.size.w / 2.0),  (world.size.height / 2.0), 0.0, 1.0, 0.0, 1.0, 0.0, 1.0,
         (world.size.w / 2.0), -(world.size.height / 2.0), 0.0, 1.0, 0.0, 0.0, 1.0, 1.0,
        -(world.size.w / 2.0),  (world.size.height / 2.0), 0.0, 1.0, 1.0, 0.0, 0.0, 1.0,
         (world.size.w / 2.0), -(world.size.height / 2.0), 0.0, 1.0, 0.0, 0.0, 1.0, 1.0,
        -(world.size.w / 2.0), -(world.size.height / 2.0), 0.0, 1.0, 0.0, 1.0, 0.0, 1.0,
    ]
    
    memcpy(verts, vData, vData.count * MemoryLayout<Float>.size)
    
    command.verts = verts
    command.transform = float4x4(1)
    command.count = 8 * 6
    
    pushCommand(renderBuffer, command)
}

func renderShip(_ renderBuffer: RawPtr) {
    if !ship.alive {
        return
    }
    var command = RenderCommandTriangles()
    
    command.verts = ship.verts
    command.transform = translateTransform(ship.p.x, ship.p.y) * rotateTransform(ship.rot)
    command.count = 8 * 3
    
    pushCommand(renderBuffer, command)
}

func renderAsteroids(_ renderBuffer: RawPtr) {
    
    for asteroid in asteroids {
        var command = RenderCommandTriangles()
        
        let scale : Float = scaleForAsteroidSize(asteroid.size)
        
        command.verts = asteroid.verts
        command.transform = translateTransform(asteroid.p.x, asteroid.p.y) * rotateTransform(asteroid.rot) * scaleTransform(scale, scale)
        command.count = 8 * 3 * 6
        
        pushCommand(renderBuffer, command)
    }
}

func renderLasers(_ renderBuffer: RawPtr) {
    
    for laser in lasers {
        var command = RenderCommandTriangles()
        
        command.verts = laser.verts
        command.transform = translateTransform(laser.p.x, laser.p.y) * scaleTransform(laser.scale, laser.scale)
        command.count = 8 * 3 * 2
        
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
