//
//  Shared.swift
//  SwiftBot
//
//  Created by Sean Hickey on 10/23/16.
//
//

import simd

public struct RenderCommand {
    public enum Type {
        case Uniforms
        case Triangles
    }
    
    public let type : Type
    public var verts : UnsafeMutablePointer<Float> = nil
    public var count : Int = 0
    public var transform: float4x4 = float4x4(1)
    
    init(_ newType: Type) {
        type = newType
    }
}

public class RenderCommandBuffer {
    public var commands : [RenderCommand] = []
    
    public func push(command: RenderCommand) {
        commands.append(command)
    }
}

public struct GamepadInputs {
    var x : Float = 0.0
    var y : Float = 0.0
    var z : Float = 0.0
    var rx : Float = 0.0
    var ry : Float = 0.0
    var rz : Float = 0.0
    var hat : Float = 0.0
    var buttons : [Bool] = [Bool](count: 16, repeatedValue: false)
}