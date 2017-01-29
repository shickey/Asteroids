//
//  BufferCreator.swift
//  Asteroids
//
//  Created by Sean Hickey on 1/29/17.
//  Copyright © 2017 Sean Hickey. All rights reserved.
//

import Metal

func createVertexBuffer(_ vertices: VertexArray) -> RawPtr {
    let buffer = device.makeBuffer(bytes: vertices, length: vertices.count * MemoryLayout<Float>.size, options: [])
    return RawPtr(Unmanaged.passRetained(buffer).toOpaque())
}

func createTextureBuffer(_ texels: RawPtr, _ width: Int, _ height: Int) -> RawPtr {
    let textureDesc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm, width: width, height: height, mipmapped: false)
    let texture = device.makeTexture(descriptor: textureDesc)
    texture.replace(region: MTLRegionMake2D(0, 0, width, height), mipmapLevel: 0, slice: 0, withBytes: texels, bytesPerRow: 4 * width, bytesPerImage: 4 * width * height)
    return RawPtr(Unmanaged.passRetained(texture).toOpaque())
}


typealias TransientBuffer = (buffer: RawPtr, bytes: RawPtr)

var availableBuffers : [U32 : [MTLBuffer]] = [:]


func findMostSignificantSetBit(_ val: U32) -> Int {
    for i in (0..<32).reversed() {
        if (val & UInt32(1 << i)) != 0 {
            return i
        }
    }
    return -1
}

func getTransientVertexBuffer(_ size: U32) -> TransientBuffer {
    
    let smallestPowerOfTwoGreaterThanSize = 1 << (findMostSignificantSetBit(size) + 1)
    
    if availableBuffers[U32(smallestPowerOfTwoGreaterThanSize)] != nil {
        if availableBuffers[U32(smallestPowerOfTwoGreaterThanSize)]!.count > 0 {
            let buffer = availableBuffers[U32(smallestPowerOfTwoGreaterThanSize)]!.remove(at: 0)
            return (buffer: RawPtr(Unmanaged.passRetained(buffer).toOpaque()), bytes: buffer.contents())
        }
    }
    
    let buffer = device.makeBuffer(length: smallestPowerOfTwoGreaterThanSize, options: [])
    return (buffer: RawPtr(Unmanaged.passRetained(buffer).toOpaque()), bytes: buffer.contents())
}

func releaseBufferToReuseQueue(_ opaqueBufferPointer: RawPtr) {
    
    let unmanagedBuffer = Unmanaged<MTLBuffer>.fromOpaque(opaqueBufferPointer)
    let buffer = unmanagedBuffer.takeUnretainedValue()
    
    let size = U32(buffer.length) // As long as the passed buffer was created with getTransientVertexBuffer, it must be a power of two in size
    
    if availableBuffers[size] == nil {
       availableBuffers[size] = []
    }
    
    availableBuffers[size]!.append(buffer)
    
    unmanagedBuffer.release()
}
