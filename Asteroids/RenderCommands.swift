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
    case Options
    case Uniforms
    case Triangles
    case Text
}

public protocol RenderCommand {
    
    var type : RenderCommandType { get }
}

public class RenderCommandOptions : RenderCommand {
    public let type = RenderCommandType.Options
    
    public enum FillModes {
        case Fill
        case Wireframe
    }
    
    public var fillMode = FillModes.Fill
}

public class RenderCommandUniforms : RenderCommand {
    public let type = RenderCommandType.Uniforms
    public var transform = float4x4(1)
}

public class RenderCommandTriangles : RenderCommand {
    public let type = RenderCommandType.Triangles
    public var transform = float4x4(1)
    public var verts : VertexPointer = nil
    public var count : Int = 0
}

public class RenderCommandText : RenderCommand {
    public let type = RenderCommandType.Text
    public var transform = float4x4(1)
    
    public var quadCount : Int = 0
    public var quads : VertexPointer = nil
    public var indices : U16Ptr = nil
    
    public var texels : U8Ptr = nil
    public var width : Int = 0
    public var height : Int = 0
    public var stride : Int = 0
}


public class RenderCommandBuffer {
    public var commands : [RenderCommand] = []
    
    public func push(command: RenderCommand) {
        commands.append(command)
    }
}

