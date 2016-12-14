//
//  TypesAndUtils.swift
//  Asteroids
//
//  Created by Sean Hickey on 12/8/16.
//  Copyright © 2016 Sean Hickey. All rights reserved.
//

public typealias U8  = UInt8
public typealias U16 = UInt16
public typealias U32 = UInt32
public typealias U64 = UInt64

public typealias S8  = Int8
public typealias S16 = Int16
public typealias S32 = Int32
public typealias S64 = Int64

public typealias F32 = Float
public typealias F64 = Double


public typealias RawPtr = UnsafeMutableRawPointer
public typealias Ptr<T> = UnsafeMutablePointer<T>


public typealias U8Ptr  = UnsafeMutablePointer<UInt8>
public typealias U16Ptr = UnsafeMutablePointer<UInt16>
public typealias U32Ptr = UnsafeMutablePointer<UInt32>
public typealias U64Ptr = UnsafeMutablePointer<UInt64>

public typealias S8Ptr  = UnsafeMutablePointer<Int8>
public typealias S16Ptr = UnsafeMutablePointer<Int16>
public typealias S32Ptr = UnsafeMutablePointer<Int32>
public typealias S64Ptr = UnsafeMutablePointer<Int64>

public typealias VertexPointer = UnsafeMutablePointer<Float>

open class GameMemory {
    open var permanent : RawPtr! = nil
    open var transient : RawPtr! = nil
}


