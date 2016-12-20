//
//  Audio.swift
//  Asteroids
//
//  Created by Sean Hickey on 12/17/16.
//  Copyright © 2016 Sean Hickey. All rights reserved.
//

import CoreAudio

var sound : StereoAudioSound! = nil

func audioInit() {
    
    
    sound = loadWavFile("howsoon.wav")
    
    let systemObjectId = AudioObjectID(kAudioObjectSystemObject)
    
    var propertyAddress = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDefaultOutputDevice, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMaster)
    
    // Query for size of output device
//    var dataSize = U32(0)
//    AudioObjectGetPropertyDataSize(systemObjectId, &propertyAddress, 0, nil, &dataSize)
    
//    var data = RawPtr.allocate(bytes: Int(dataSize), alignedTo: 4)
    
    var outputId = AudioObjectID(5)
    var idSize = U32(MemoryLayout<AudioObjectID>.size)
    var success = AudioObjectGetPropertyData(systemObjectId, &propertyAddress, 0, nil, &idSize, &outputId)
    
    propertyAddress.mSelector = kAudioObjectPropertyName
    var stringSize = U32(MemoryLayout<CFString>.size)
    var name = "" as CFString
    var success2 = AudioObjectGetPropertyData(outputId, &propertyAddress, 0, nil, &stringSize, &name)
    
    var procId : AudioDeviceIOProcID? = nil
    AudioDeviceCreateIOProcID(outputId, samplesRequested, nil, &procId)
    AudioDeviceStart(outputId, procId)
    
}

var sampleOffset = 0

func samplesRequested(_ inDevice: AudioObjectID, _ inNow: UnsafePointer<AudioTimeStamp>, _ inInputData: UnsafePointer<AudioBufferList>, _ inInputTime: UnsafePointer<AudioTimeStamp>, _ outOutputData: UnsafeMutablePointer<AudioBufferList>, _ inOutputTime: UnsafePointer<AudioTimeStamp>, _ inClientData: UnsafeMutableRawPointer?) -> OSStatus {
    
    if sampleOffset >= sound.samplesInterleaved.count {
        return 0
    }
    
    let bufferList = outOutputData.pointee
    
    let totalBytesRequested = bufferList.mBuffers.mDataByteSize
    let totalSamplesRequested = totalBytesRequested / 4 // Each sample is a 32-bit float
    
    var max : S16 = 0
    var min : S16 = 0
    
    var outSamples : [F32] = []
    for i in 0..<totalSamplesRequested {
        if sampleOffset >= sound.samplesInterleaved.count {
            break
        }
        
        var sample = sound.samplesInterleaved[sampleOffset]
        var floatSample = F32(sample) / F32(32760.0)
        
        if sample > max {
            max = sample
        }
        else if sample < min {
            min = sample
        }
        
        if floatSample > 1.0 || floatSample < -1.0 {
            print("Audio clipping")
        }
        
        outSamples.append(floatSample)
        
        sampleOffset += 1
    }
    
    
    memcpy(bufferList.mBuffers.mData, &outSamples, outSamples.count * 4)
    
    return 0
}

