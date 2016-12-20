//
//  StaticArray.swift
//  Asteroids
//
//  Created by Sean Hickey on 12/14/16.
//  Copyright © 2016 Sean Hickey. All rights reserved.
//

import Darwin

/**********************************************
 * StaticArray<T>
 *
 * Really basic fixed-sized array structure.
 * Once you fill it up, you're toast!
 *
 **********************************************/

/*= BEGIN_REFSTRUCT =*/
struct StaticArray<T> {
    var storage : Ptr<T> /*= GETSET =*/
    var maxCount : Int /*= GETSET =*/
    var count : Int /*= GETSET =*/
}
/*= END_REFSTRUCT =*/

extension StaticArrayRef {
    subscript(index: Int) -> T {
        get {
            return storage[index]
        }
    }
}

func createStaticArray<T>(_ zone: MemoryZoneRef, type: T.Type, count: Int) -> StaticArrayRef<T> {
    let arrayBase = allocateTypeFromZone(zone, StaticArray<T>.self)
    
    let totalSize = MemoryLayout<T>.stride * count
    let storageBase = allocateFromZone(zone, totalSize)
    
    var arrayRef = StaticArrayRef(ptr: arrayBase)
    arrayRef.maxCount = count
    arrayRef.count = 0
    arrayRef.storage = storageBase.bindMemory(to: T.self, capacity: count)
    
    return arrayRef
}

func staticArrayPush<T>(_ arrayRef: StaticArrayRef<T>, _ element: T) {
    var array = arrayRef
    assert(array.count < array.maxCount)
    array.storage[array.count] = element
    array.count += 1
}

func clearStaticArray<T>(_ arrayRef: StaticArrayRef<T>) {
    var array = arrayRef
    let totalSize = MemoryLayout<T>.stride * array.maxCount
    memset(array.storage, 0, totalSize)
    array.count = 0
}

extension StaticArrayRef : Sequence {
    func makeIterator() -> StaticArrayIterator<T> {
        return StaticArrayIterator<T>(self)
    }
}

struct StaticArrayIterator<T> : IteratorProtocol {
    let arrayRef : StaticArrayRef<T>
    var index = 0
    
    init(_ newArrayRef: StaticArrayRef<T>) {
        arrayRef = newArrayRef
    }
    
    mutating func next() -> T? {
        if index >= arrayRef.count {
            return nil
        }
        let element = arrayRef[index]
        index += 1
        return element
    }
}


/**********************************************
 * CircularBuffer<T>
 *
 * Pretty similar to StaticArray<T>,
 * but now with fancy wrap-around!
 *
 **********************************************/

/*= BEGIN_REFSTRUCT =*/
struct CircularBuffer<T> {
    var storage : Ptr<T> /*= GETSET =*/
    var maxCount : Int /*= GETSET =*/
    var count : Int /*= GETSET =*/
    var nextIndex : Int /*= GETSET =*/
}
/*= END_REFSTRUCT =*/

extension CircularBufferRef {
    subscript(index: Int) -> T {
        get {
            return storage[index]
        }
    }
}



func createCircularBuffer<T>(_ zone: MemoryZoneRef, type: T.Type, count: Int) -> CircularBufferRef<T> {
    let bufferBase = allocateTypeFromZone(zone, CircularBuffer<T>.self)
    
    let totalSize = MemoryLayout<T>.stride * count
    let storageBase = allocateFromZone(zone, totalSize)
    
    var bufferRef = CircularBufferRef(ptr: bufferBase)
    bufferRef.maxCount = count
    bufferRef.nextIndex = 0
    bufferRef.storage = storageBase.bindMemory(to: T.self, capacity: count)
    
    return bufferRef
}

func circularBufferPush<T>(_ bufferRef: CircularBufferRef<T>, _ element: T) {
    var buffer = bufferRef
    buffer.storage[buffer.nextIndex] = element
    buffer.nextIndex += 1
    if buffer.nextIndex == buffer.maxCount {
        buffer.nextIndex = 0
    }
    if buffer.count < buffer.maxCount {
        buffer.count += 1
    }
}

func clearCircularBuffer<T>(_ bufferRef: CircularBufferRef<T>) {
    var buffer = bufferRef
    let totalSize = MemoryLayout<T>.stride * buffer.maxCount
    memset(buffer.storage, 0, totalSize)
    buffer.count = 0
}

extension CircularBufferRef : Sequence {
    func makeIterator() -> CircularBufferIterator<T> {
        return CircularBufferIterator<T>(self)
    }
}

struct CircularBufferIterator<T> : IteratorProtocol {
    let bufferRef : CircularBufferRef<T>
    var index = 0
    
    init(_ newBufferRef: CircularBufferRef<T>) {
        bufferRef = newBufferRef
    }
    
    mutating func next() -> T? {
        if index >= bufferRef.count {
            return nil
        }
        let element = bufferRef[index]
        index += 1
        return element
    }
}
