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

public func updateAndRender(_ gameMemoryPtr: UnsafeMutablePointer<GameMemory>, inputsPtr: UnsafeMutablePointer<Inputs>, renderCommandsPtr: UnsafeMutablePointer<RenderCommandBuffer>) {
    
    let gameMemory = gameMemoryPtr.pointee
    let inputs = inputsPtr.pointee
    let commandBuffer = renderCommandsPtr.pointee
    
    let gameStatePtr = gameMemory.permanent.bindMemory(to: GameState.self, capacity: 1)
    
    let options = RenderCommandOptions()
    options.fillMode = .fill
    commandBuffer.push(options)

    var gameState = gameStatePtr.pointee
    
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
    
    
    simulate(inputs.dt, inputs)
    
    computeUniforms(commandBuffer)
    if DEBUG.BACKGROUND {
        renderTerribleBackground(commandBuffer)
    }
    else {
        renderBlackBackground(commandBuffer)
    }
    renderAsteroids(commandBuffer)
    renderShip(commandBuffer)
    renderLasers(commandBuffer)
    
    let command = renderText("(Hello, world!)?", font)
    commandBuffer.push(command)
    
    // TEXT TEST
//    let textCommand = RenderCommandText()
//    textCommand.texels = U8Ptr(tex!.pixels)
//    textCommand.width  = Int(tex!.biWidth)
//    textCommand.height = Int(tex!.biHeight)
//    textCommand.stride = Int(tex!.biBitCount)
//    
//    let verts = UnsafeMutablePointer<Float>.alloc(6 * 8)
//    let vData : [Float] = [
//        -0.5,  0.5, 0.0, 1.0,   0.0,   0.0, 0.0,   0.0,
//         0.5,  0.5, 0.0, 1.0, 128.0,   0.0, 0.0,   0.0,
//         0.5, -0.5, 0.0, 1.0, 128.0, 512.0, 0.0,   0.0,
//        -0.5,  0.5, 0.0, 1.0,   0.0,   0.0, 0.0,   0.0,
//         0.5, -0.5, 0.0, 1.0, 128.0, 512.0, 0.0,   0.0,
//        -0.5, -0.5, 0.0, 1.0,   0.0, 512.0, 0.0,   0.0,
//    ]
//    
//    memcpy(verts, vData, vData.count * sizeof(Float))
//    
//    textCommand.verts = verts
//    textCommand.count = vData.count
//    
//    commandBuffer.push(textCommand)
    
}

func computeUniforms(_ commandBuffer: RenderCommandBuffer) {
    let uniformsCommand = RenderCommandUniforms()
    uniformsCommand.transform = worldTransform
    commandBuffer.push(uniformsCommand)
}

var laserTimeToWait : Float = 0.0

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

func renderBlackBackground(_ commandBuffer: RenderCommandBuffer) {
    let command = RenderCommandTriangles()
    
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
    
    commandBuffer.push(command)
}

func renderTerribleBackground(_ commandBuffer: RenderCommandBuffer) {
    let command = RenderCommandTriangles()
    
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
    
    commandBuffer.push(command)
}

func renderShip(_ commandBuffer: RenderCommandBuffer) {
    if !ship.alive {
        return
    }
    let command = RenderCommandTriangles()
    
    command.verts = ship.verts
    command.transform = translateTransform(ship.p.x, ship.p.y) * rotateTransform(ship.rot)
    command.count = 8 * 3
    
    commandBuffer.push(command)
}

func renderAsteroids(_ commandBuffer: RenderCommandBuffer) {
    
    for asteroid in asteroids {
        let command = RenderCommandTriangles()
        
        let scale : Float = scaleForAsteroidSize(asteroid.size)
        
        command.verts = asteroid.verts
        command.transform = translateTransform(asteroid.p.x, asteroid.p.y) * rotateTransform(asteroid.rot) * scaleTransform(scale, scale)
        command.count = 8 * 3 * 6
        
        commandBuffer.push(command)
    }
}

func renderLasers(_ commandBuffer: RenderCommandBuffer) {
    
    for laser in lasers {
        let command = RenderCommandTriangles()
        
        command.verts = laser.verts
        command.transform = translateTransform(laser.p.x, laser.p.y) * scaleTransform(laser.scale, laser.scale)
        command.count = 8 * 3 * 2
        
        commandBuffer.push(command)
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
