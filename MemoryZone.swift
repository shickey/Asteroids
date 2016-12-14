//
//  MemoryZone.swift
//  Asteroids
//
//  Created by Sean Hickey on 12/13/16.
//  Copyright © 2016 Sean Hickey. All rights reserved.
//


struct MemoryZone {
    var base : RawPtr
    var size : Int
    var used : Int = 0
}

struct MemoryZoneRef {
    let ptr : Ptr<MemoryZone>
    var base : RawPtr { get { return ptr.pointee.base } }
    var size : Int { get { return ptr.pointee.size } }
    var used : Int { get { return ptr.pointee.used} set(val){ptr.pointee.used = val} }
}

func createZone(_ zoneZone: inout MemoryZone, _ base: RawPtr, _ size: Int) -> MemoryZoneRef {
    
    let zoneEntryBase = zoneZone.base + zoneZone.used
    
    var zone = MemoryZone(base: base, size: size, used: 0)
    zoneEntryBase.copyBytes(from: &zone, count: MemoryLayout<MemoryZone>.size)
    
    zoneZone.used += MemoryLayout<MemoryZone>.size
    
    return MemoryZoneRef(ptr: <-zoneEntryBase)
}

func allocateFromZone(_ zoneRef: MemoryZoneRef, _ size: Int) -> RawPtr {
    var zone = zoneRef
    assert(zone.used + size < zone.size)
    let base = zone.base + zone.used
    zone.used += size
    return base
}

// TODO: Do we need to worry about alignment here?
func allocateTypeFromZone<T>(_ zoneRef: MemoryZoneRef, _ type: T.Type) -> Ptr<T> {
    return <-allocateFromZone(zoneRef, MemoryLayout<T>.size)
}
