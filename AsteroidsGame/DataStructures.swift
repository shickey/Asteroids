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
    
    let arrayRef = StaticArrayRef(&arrayBase.pointee)
    arrayRef.maxCount = count
    arrayRef.count = 0
    arrayRef.storage = storageBase.bindMemory(to: T.self, capacity: count)
    
    return arrayRef
}

func staticArrayPush<T>(_ array: StaticArrayRef<T>, _ element: T) {
    assert(array.count < array.maxCount)
    array.storage[array.count] = element
    array.count += 1
}

func clearStaticArray<T>(_ array: StaticArrayRef<T>) {
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
 * Pool<T>
 *
 * Linear data structure which allows deallocation
 * and reuse of indices
 *
 **********************************************/

/*= BEGIN_REFSTRUCT =*/
struct Pool<T> {
    var storage : Ptr<T> /*= GETSET =*/
    var maxCount : Int /*= GETSET =*/
    var count : Int /*= GETSET =*/
    var occupiedMask : U64 /*= GETSET =*/
}
/*= END_REFSTRUCT =*/

extension PoolRef {
    subscript(index: Int) -> T? {
        get {
            if (self.occupiedMask & (U64(1) << U64(index))) == 0 {
                return nil
            }
            return storage[index]
        }
    }
}

func createPool<T>(_ zone: MemoryZoneRef, _ type: T.Type, _ count: Int) -> PoolRef<T> {
    assert(count < 64) // TODO: Currently bounded by what is representable in the occupiedMask. Figure out how to allocate bigger pools and/or grow dynamically
    let poolBase = allocateTypeFromZone(zone, Pool<T>.self)
    
    let totalSize = MemoryLayout<T>.stride * count
    let storageBase = allocateFromZone(zone, totalSize)
    
    let poolRef = PoolRef(&poolBase.pointee)
    poolRef.maxCount = count
    poolRef.count = 0
    poolRef.storage = storageBase.bindMemory(to: T.self, capacity: count)
    poolRef.occupiedMask = 0
    
    return poolRef
}

@discardableResult
func poolAdd<T>(_ pool: PoolRef<T>, _ element: T) -> Int {
    assert(pool.count < pool.maxCount)
    
    // Find open slot
    var index = 0
    while (pool.occupiedMask & U64(1) << U64(index)) != 0 {
        index += 1
    }
    
    pool.storage[index] = element
    
    pool.occupiedMask |= U64(1) << U64(index)
    pool.count += 1
    
    return index
}

func poolRemoveAtIndex<T>(_ pool: PoolRef<T>, _ index: Int) {
    assert(index < pool.maxCount)
    assert((pool.occupiedMask & U64(1) << U64(index)) != 0)
    
    // Simply mark the slot as unoccupied
    pool.occupiedMask ^= U64(1) << U64(index)
    pool.count -= 1
}

func clearPool<T>(_ pool: PoolRef<T>) {
    let totalSize = MemoryLayout<T>.stride * pool.maxCount
    memset(pool.storage, 0, totalSize)
    pool.count = 0
    pool.occupiedMask = 0
}

extension PoolRef : Sequence {
    func makeIterator() -> PoolIterator<T> {
        return PoolIterator<T>(self)
    }
}

extension PoolRef {
    func enumeratedWithSlot() -> IteratorSequence<PoolIteratorWithSlot<T>> {
        return IteratorSequence(PoolIteratorWithSlot<T>(self))
    }
}

struct PoolIterator<T> : IteratorProtocol {
    let poolRef : PoolRef<T>
    var index = 0
    
    init(_ newPoolRef: PoolRef<T>) {
        poolRef = newPoolRef
    }
    
    mutating func next() -> T? {
        // Skip over unoccupied slots
        while (poolRef.occupiedMask & U64(1) << U64(index)) == 0 {
            if index >= poolRef.maxCount {
                return nil
            }
            index += 1
        }
        let element = poolRef[index]
        index += 1
        return element
    }
}

struct PoolIteratorWithSlot<T> : IteratorProtocol {
    let poolRef : PoolRef<T>
    var index = 0
    
    init(_ newPoolRef: PoolRef<T>) {
        poolRef = newPoolRef
    }
    
    mutating func next() -> (Int, T)? {
        // Skip over unoccupied slots
        while (poolRef.occupiedMask & U64(1) << U64(index)) == 0 {
            if index >= poolRef.maxCount {
                return nil
            }
            index += 1
        }
        let result = (index, poolRef[index]!)
        index += 1
        return result
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
    
    let bufferRef = CircularBufferRef(&bufferBase.pointee)
    bufferRef.maxCount = count
    bufferRef.nextIndex = 0
    bufferRef.storage = storageBase.bindMemory(to: T.self, capacity: count)
    
    return bufferRef
}

func circularBufferPush<T>(_ buffer: CircularBufferRef<T>, _ element: T) {
    buffer.storage[buffer.nextIndex] = element
    buffer.nextIndex += 1
    if buffer.nextIndex == buffer.maxCount {
        buffer.nextIndex = 0
    }
    if buffer.count < buffer.maxCount {
        buffer.count += 1
    }
}

func clearCircularBuffer<T>(_ buffer: CircularBufferRef<T>) {
    let totalSize = MemoryLayout<T>.stride * buffer.maxCount
    memset(buffer.storage, 0, totalSize)
    buffer.count = 0
    buffer.nextIndex = 0
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

/**********************************************
 * HashTable<K, V>
 *
 * Simple hash table for storage of fixed sized structures.
 * TODO: Add ability to remove entries and grow dynamically.
 *
 **********************************************/

protocol HashableKey {
    var hashValue : Int { get } // Must not be 0
}

extension RenderableId : HashableKey {
    var hashValue : Int {
        return Int(self)
    }
}

struct HashTable<K : HashableKey, V> {
    var storage : Ptr<HashTableEntry<K, V>>
    var maxCount : Int
}

struct HashTableEntry<K : HashableKey, V> {
    var keyHash : Int // I.e., K.hashValue
    var value : V
}

// Just manually create the ref types since the generic-ness is getting a little wacky
class HashTableRef<K : HashableKey, V> : Ref<HashTable<K, V>> {
    var storage : Ptr<HashTableEntry<K, V>> { get { return ptr.pointee.storage } set(val) { ptr.pointee.storage = val } }
    var maxCount : Int { get { return ptr.pointee.maxCount } set(val) { ptr.pointee.maxCount = val } }
}

class HashTableEntryRef<K : HashableKey, V> : Ref<HashTableEntry<K, V>> {
    var keyHash : Int { get { return ptr.pointee.keyHash } set(val) { ptr.pointee.keyHash = val } }
    var value : V { get { return ptr.pointee.value } set(val) { ptr.pointee.value = val } }
}

extension HashTableRef {
    subscript(key: K) -> V? {
        get {
            return hashTableRetrieve(self, key)
        }
        set(value) {
            hashTableInsert(self, key, value!)
        }
    }
}

func createHashTable<K, V>(_ zone: MemoryZoneRef, _ count: Int) -> HashTableRef<K, V> {
    let bufferBase = allocateTypeFromZone(zone, HashTable<K, V>.self)
    
    let totalSize = MemoryLayout<HashTableEntry<K, V>>.stride * count
    let storageBase = allocateFromZone(zone, totalSize)
    memset(storageBase, 0, totalSize)
    
    let hashTableRef = HashTableRef(&bufferBase.pointee)
    hashTableRef.maxCount = count
    hashTableRef.storage = storageBase.bindMemory(to: HashTableEntry<K, V>.self, capacity: count)
    
    return hashTableRef
}

func hashTableInsert<K, V>(_ hashTable: HashTableRef<K, V>, _ key: K, _ value: V) {
    assert(key.hashValue > 0)
    let hashIndex = key.hashValue % hashTable.maxCount
    var insertionIndex = hashIndex
    var newEntry = hashTable.storage[insertionIndex]
    while newEntry.keyHash != 0 && newEntry.keyHash != key.hashValue { // If the slot is occupied, use linear probing. Also, allow a key's value to be overwritten
        insertionIndex += 1
        if insertionIndex == hashTable.maxCount {
            insertionIndex = 0
        }
        assert(insertionIndex != hashIndex, "Attempted to insert into a full hash table.")
        newEntry = hashTable.storage[insertionIndex]
    }
    hashTable.storage[insertionIndex].keyHash = key.hashValue
    hashTable.storage[insertionIndex].value = value
}

func hashTableRetrieve<K, V>(_ hashTable: HashTableRef<K, V>, _ key: K) -> V? {
    assert(key.hashValue > 0)
    let hashIndex = key.hashValue % hashTable.maxCount
    var retrievalIndex = hashIndex
    var possibleEntry = hashTable.storage[retrievalIndex]
    while possibleEntry.keyHash != key.hashValue {
        // TODO: This early return only works because we have no way to remove entries from the table.
        //       Figure out a way to account for this when removal is implemented
        if possibleEntry.keyHash == 0 {
            return nil
        }
        
        retrievalIndex += 1
        if retrievalIndex == hashTable.maxCount {
            retrievalIndex = 0
        }
        if retrievalIndex == hashIndex {
            return nil
        }
        possibleEntry = hashTable.storage[retrievalIndex]
    }
    return possibleEntry.value
}






