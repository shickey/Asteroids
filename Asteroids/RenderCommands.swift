//
//  Shared.swift
//  SwiftBot
//
//  Created by Sean Hickey on 10/23/16.
//
//

import simd

public struct RenderCommandBufferHeader {
    var commandCount : U32 = 0
    var firstCommandBase : RawPtr? = nil
    var lastCommandBase : RawPtr? = nil
    var lastCommandHead : RawPtr? = nil
}

public enum RenderCommandType {
    case header
    case options
    case uniforms
    case triangles
    case text
}

public protocol RenderCommand {
    var type : RenderCommandType { get }
    var next : RawPtr? { get set }
}

// Memory layout compatible struct for determining
// type of command, next pointer, etc.
public struct RenderCommandHeader {
    public let type = RenderCommandType.options
    public var next : RawPtr? = nil
}

public struct RenderCommandOptions : RenderCommand {
    public let type = RenderCommandType.options
    public var next : RawPtr? = nil
    
    public enum FillModes {
        case fill
        case wireframe
    }
    
    public var fillMode = FillModes.fill
}

public struct RenderCommandUniforms : RenderCommand {
    public let type = RenderCommandType.uniforms
    public var next : RawPtr? = nil
    
    public var transform = float4x4(1)
}

public struct RenderCommandTriangles : RenderCommand {
    public let type = RenderCommandType.triangles
    public var next : RawPtr? = nil
    
    public var transform = float4x4(1)
    public var verts : VertexPointer! = nil
    public var count : Int = 0
}

public struct RenderCommandText : RenderCommand {
    public let type = RenderCommandType.text
    public var next : RawPtr? = nil
    
    public var transform = float4x4(1)
    
    public var quadCount : Int = 0
    public var quads : VertexPointer! = nil
    public var indices : U16Ptr! = nil
    
    public var texels : U8Ptr! = nil
    public var width : Int = 0
    public var height : Int = 0
    public var stride : Int = 0
}


