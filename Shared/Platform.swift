//
//  Platform.swift
//  Asteroids
//
//  Created by Sean Hickey on 12/19/16.
//  Copyright © 2016 Sean Hickey. All rights reserved.
//

public typealias platform_CreateVertexBuffer  = (VertexArray) -> RawPtr
public typealias platform_CreateTextureBuffer = (RawPtr, Int, Int) -> RawPtr
public typealias platform_GetTransientBuffer = (U32) -> (RawPtr, RawPtr)

open class GameMemory {
    open var permanentStorageSize : Int = 0
    open var permanentStorage : RawPtr! = nil
    
    open var transientStorageSize : Int = 0
    open var transientStorage : RawPtr! = nil
    
    open var debugStorageSize : Int = 0
    open var debugStorage : RawPtr! = nil
    
    // Platform Provided Functions
    open var platformCreateVertexBuffer : platform_CreateVertexBuffer! = nil
    open var platformCreateTextureBuffer : platform_CreateTextureBuffer! = nil
    open var platformGetTransientBuffer : platform_GetTransientBuffer! = nil
}
