//
//  TypesAndUtils.swift
//  Asteroids
//
//  Created by Sean Hickey on 12/8/16.
//  Copyright © 2016 Sean Hickey. All rights reserved.
//

public typealias Ptr = UnsafeMutablePointer<Void>

public typealias U8Ptr  = UnsafeMutablePointer<UInt8>
public typealias U16Ptr = UnsafeMutablePointer<UInt16>
public typealias U32Ptr = UnsafeMutablePointer<UInt32>
public typealias U64Ptr = UnsafeMutablePointer<UInt64>

public typealias S8Ptr  = UnsafeMutablePointer<Int8>
public typealias S16Ptr = UnsafeMutablePointer<Int16>
public typealias S32Ptr = UnsafeMutablePointer<Int32>
public typealias S64Ptr = UnsafeMutablePointer<Int64>

public class GameMemory {
    public var permanent : Ptr = nil
    public var transient : Ptr = nil
}

// Stuff to make memory actually usable in this god-forsaken language

prefix operator ^ {}
prefix func ^<T>(inout lhs: T) -> UnsafeMutablePointer<T> {
    return withUnsafeMutablePointer(&lhs) {UnsafeMutablePointer<T>($0)}
}

prefix operator * {}
prefix func *<T>(lhs: UnsafeMutablePointer<T>) -> T {
    return lhs.memory
}

func coldCast<T>(val: Any) -> T {
    var v = val
    let ptr = withUnsafeMutablePointer(&v) {UnsafeMutablePointer<Void>($0)}
    return UnsafeMutablePointer<T>(ptr).memory
}