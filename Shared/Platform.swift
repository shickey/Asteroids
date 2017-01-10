//
//  Platform.swift
//  Asteroids
//
//  Created by Sean Hickey on 12/19/16.
//  Copyright © 2016 Sean Hickey. All rights reserved.
//

public typealias platform_CreateVertexBuffer  = (VertexArray) -> RawPtr
//typealias platform_CreateGPUTexture = (VertexPointer!) -> RawPtr

open class GameMemory {
    open var permanentStorageSize : Int = 0
    open var permanentStorage : RawPtr! = nil
    
    open var transientStorageSize : Int = 0
    open var transientStorage : RawPtr! = nil
    
    open var debugStorageSize : Int = 0
    open var debugStorage : RawPtr! = nil
    
    // Platform Provided Functions
    open var platformCreateVertexBuffer : platform_CreateVertexBuffer! = nil
}
