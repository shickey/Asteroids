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


var gameInitialized = false
var ship = Ship()

struct World {
    var size = Size(20.0, 20.0)
}

var world = World()
var worldTransform = float4x4(1)

func gameInit() {
    // Set world scaling
    let scaleFactor = max(world.size.width, world.size.height)
    worldTransform[0][0] = 1.0 / (scaleFactor / 2.0)
    worldTransform[1][1] = 1.0 / (scaleFactor / 2.0)
    
    if DEBUG.ZOOM_OUT {
        worldTransform[0][0] = 1.0 / scaleFactor
        worldTransform[1][1] = 1.0 / scaleFactor
    }
    
    gameInitialized = true
}

public func updateAndRender(dt: Double, gamepadInputs: UnsafeMutablePointer<GamepadInputs>, renderCommands: UnsafeMutablePointer<RenderCommandBuffer>) {
    
    if !gameInitialized {
        gameInit()
    }
    
    let inputs = gamepadInputs.memory
    let commandBuffer = renderCommands.memory
    
    simulate(inputs)
    
    computeUniforms(commandBuffer)
    if DEBUG.BACKGROUND {
        renderTerribleBackground(commandBuffer)
    }
    else {
        renderBlackBackground(commandBuffer)
    }
    renderShip(commandBuffer)
}

func computeUniforms(commandBuffer: RenderCommandBuffer) {
    var uniformsCommand = RenderCommand(.Uniforms)
    uniformsCommand.transform = worldTransform
    commandBuffer.push(uniformsCommand)
}

func simulate(inputs: GamepadInputs) {
    rotateShip(ship, 0.05 * inputs.x)
    
    let accelFactor : Float = 0.005
    let maxVelocity : Float = 0.5
    
    if inputs.buttons[1] {
        ship.dP.x += sin(ship.rotation) * accelFactor
        ship.dP.y += cos(ship.rotation) * accelFactor
        
        ship.dP.x = clamp(ship.dP.x, -maxVelocity, maxVelocity)
        ship.dP.y = clamp(ship.dP.y, -maxVelocity, maxVelocity)
    }
    
    ship.p.x += ship.dP.x
    ship.p.y += ship.dP.y
    
    ship.p.x = normalizeToRange(ship.p.x, -world.size.w / 2.0, world.size.w / 2.0)
    ship.p.y = normalizeToRange(ship.p.y, -world.size.h / 2.0, world.size.h / 2.0)
    
}

func renderBlackBackground(commandBuffer: RenderCommandBuffer) {
    var command = RenderCommand(.Triangles)
    
    let verts = UnsafeMutablePointer<Float>.alloc(6 * 8)
    let vData = [
        -(world.size.w / 2.0),  (world.size.height / 2.0), 0.0, 1.0, 0.0, 0.0, 0.0, 1.0,
         (world.size.w / 2.0),  (world.size.height / 2.0), 0.0, 1.0, 0.0, 0.0, 0.0, 1.0,
         (world.size.w / 2.0), -(world.size.height / 2.0), 0.0, 1.0, 0.0, 0.0, 0.0, 1.0,
        -(world.size.w / 2.0),  (world.size.height / 2.0), 0.0, 1.0, 0.0, 0.0, 0.0, 1.0,
         (world.size.w / 2.0), -(world.size.height / 2.0), 0.0, 1.0, 0.0, 0.0, 0.0, 1.0,
        -(world.size.w / 2.0), -(world.size.height / 2.0), 0.0, 1.0, 0.0, 0.0, 0.0, 1.0,
        ]
    
    memcpy(verts, vData, vData.count * sizeof(Float))
    
    command.verts = verts
    command.transform = float4x4(1)
    command.count = 8 * 6
    
    commandBuffer.push(command)
}

func renderTerribleBackground(commandBuffer: RenderCommandBuffer) {
    var command = RenderCommand(.Triangles)
    
    let verts = UnsafeMutablePointer<Float>.alloc(6 * 8)
    let vData = [
        -(world.size.w / 2.0),  (world.size.height / 2.0), 0.0, 1.0, 1.0, 0.0, 0.0, 1.0,
         (world.size.w / 2.0),  (world.size.height / 2.0), 0.0, 1.0, 0.0, 1.0, 0.0, 1.0,
         (world.size.w / 2.0), -(world.size.height / 2.0), 0.0, 1.0, 0.0, 0.0, 1.0, 1.0,
        -(world.size.w / 2.0),  (world.size.height / 2.0), 0.0, 1.0, 1.0, 0.0, 0.0, 1.0,
         (world.size.w / 2.0), -(world.size.height / 2.0), 0.0, 1.0, 0.0, 0.0, 1.0, 1.0,
        -(world.size.w / 2.0), -(world.size.height / 2.0), 0.0, 1.0, 0.0, 1.0, 0.0, 1.0,
    ]
    
    memcpy(verts, vData, vData.count * sizeof(Float))
    
    command.verts = verts
    command.transform = float4x4(1)
    command.count = 8 * 6
    
    commandBuffer.push(command)
}

func renderShip(commandBuffer: RenderCommandBuffer) {
    var command = RenderCommand(.Triangles)
    
    command.verts = ship.verts
    command.transform = translateTransform(ship.p.x, ship.p.y) * rotateTransform(ship.rotation)
    command.count = 8 * 3
    
    commandBuffer.push(command)
}

func translateTransform(x: Float, _ y: Float) -> float4x4 {
    var transform = float4x4(1)
    transform[3][0] = x
    transform[3][1] = y
    return transform
}

func rotateTransform(theta: Float) -> float4x4 {
    var transform = float4x4(1)
    transform[0][0] =  cos(theta)
    transform[0][1] = -sin(theta)
    transform[1][0] =  sin(theta)
    transform[1][1] =  cos(theta)
    return transform
}