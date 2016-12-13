//
//  Shared.swift
//  SwiftBot
//
//  Created by Sean Hickey on 10/23/16.
//
//

import simd

public typealias VertexPointer = UnsafeMutablePointer<Float>

public enum RenderCommandType {
    case options
    case uniforms
    case triangles
    case text
}

public protocol RenderCommand {
    
    var type : RenderCommandType { get }
}

open class RenderCommandOptions : RenderCommand {
    open let type = RenderCommandType.options
    
    public enum FillModes {
        case fill
        case wireframe
    }
    
    open var fillMode = FillModes.fill
}

open class RenderCommandUniforms : RenderCommand {
    open let type = RenderCommandType.uniforms
    open var transform = float4x4(1)
}

open class RenderCommandTriangles : RenderCommand {
    open let type = RenderCommandType.triangles
    open var transform = float4x4(1)
    open var verts : VertexPointer! = nil
    open var count : Int = 0
}

open class RenderCommandText : RenderCommand {
    open let type = RenderCommandType.text
    open var transform = float4x4(1)
    
    open var quadCount : Int = 0
    open var quads : VertexPointer! = nil
    open var indices : U16Ptr! = nil
    
    open var texels : U8Ptr! = nil
    open var width : Int = 0
    open var height : Int = 0
    open var stride : Int = 0
}


open class RenderCommandBuffer {
    open var commands : [RenderCommand] = []
    
    open func push(_ command: RenderCommand) {
        commands.append(command)
    }
}

