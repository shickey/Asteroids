//
//  AssetLoader.swift
//  Asteroids
//
//  Created by Sean Hickey on 12/7/16.
//  Copyright © 2016 Sean Hickey. All rights reserved.
//

import Darwin

let assetDir : String = ({
    let components = dylibPath().characters.split(separator: "/")
    let dir = "/" + components.dropLast(1).map(String.init).joined(separator: "/")
    return dir + "/assets"
})()

func assetPath(_ filename: String) -> String {
    return assetDir + "/\(filename)"
}

func dylibPath() -> String {
    //////////////////////// REMOVE! TEMPORARY HACK!
    return "/Users/seanhickey/Library/Developer/Xcode/DerivedData/Asteroids-cnsxvmrospeitxfvmnhjaxvyjyto/Build/Products/Debug/libAsteroids.dylib"
    
    let symbolAddress = unsafeBitCast(FileData.self, to: UnsafeMutableRawPointer.self)
    var info = Dl_info(dli_fname: "", dli_fbase: nil, dli_sname: "", dli_saddr: nil)
    dladdr(symbolAddress, &info)
    let path = String(cString: info.dli_fname)
    return path
}

class FileData {
    var length: Int = 0
    var bytes: U8Ptr! = nil
}

func readFile(_ path: String) -> FileData? {
    
    let data = FileData()
    
    let filePtr = fopen(path, "rb")
    if filePtr != nil {
        fseek(filePtr, 0, SEEK_END)
        data.length = ftell(filePtr)
        fseek(filePtr, 0, SEEK_SET)
        
        data.bytes = U8Ptr.allocate(capacity: data.length)
        fread(data.bytes, data.length, 1, filePtr)
        fclose(filePtr)
        
        return data
    }
    return nil
}



func loadTextAsset(_ filename: String) -> String? {
    
    let fileOpt = readFile(assetPath(filename))
    if let file = fileOpt {
        let nulTerm = UnsafeMutablePointer<CChar>.allocate(capacity: file.length + 1)
        memcpy(nulTerm, file.bytes, file.length)
        nulTerm[file.length] = 0
        let s = String(cString: nulTerm)
        return s
    }
    return nil
}

// Bitmap Loading


struct BitmapTypeHeader {
    var type          : UInt16
}
struct BitmapHeader {
    var size          : UInt32
    var reserved1     : UInt16
    var reserved2     : UInt16
    var offBits       : UInt32
    var infoSize      : UInt32
    var width         : Int32
    var height        : Int32
    var planes        : UInt16
    var bitCount      : UInt16
    var compression   : UInt32
    var sizeImage     : UInt32
    var xPelsPerMeter : Int32
    var yPelsPerMeter : Int32
    var clrUsed       : UInt32
    var clrImportant  : UInt32
    var redMask       : UInt32
    var greenMask     : UInt32
    var blueMask      : UInt32
    var alphaMask     : UInt32
}

class Bitmap {
    var width  : Int = 0
    var height : Int = 0
    var stride : Int = 0
    var pixels : U32Ptr! = nil
}

func loadBitmap(_ filename: String) -> Bitmap? {
    let fileOpt = readFile(assetPath(filename))
    if let file = fileOpt {
        let typeHeaderPtr = RawPtr(file.bytes).bindMemory(to: BitmapTypeHeader.self, capacity: 1)
        
        let headerPtr = RawPtr(file.bytes.advanced(by: 2)).bindMemory(to: BitmapHeader.self, capacity: 1)
        let header = headerPtr.pointee
        
        let bitmap = Bitmap()
        bitmap.width = Int(header.width)
        bitmap.height = Int(header.height)
        bitmap.stride = Int(header.bitCount) * bitmap.width
        bitmap.pixels = RawPtr(file.bytes.advanced(by: Int(header.offBits))).bindMemory(to: UInt32.self, capacity: bitmap.width * bitmap.height)
        
        let redShift   = findLeastSignificantSetBit(header.redMask)
        let greenShift = findLeastSignificantSetBit(header.greenMask)
        let blueShift  = findLeastSignificantSetBit(header.blueMask)
        let alphaShift = findLeastSignificantSetBit(header.alphaMask)
        
        var pixelPtr = bitmap.pixels!
        for _ in 0..<(bitmap.width * bitmap.height) {
            let pixel = pixelPtr[0]
            
            var r = (pixel & header.redMask)   >> UInt32(redShift)
            var g = (pixel & header.greenMask) >> UInt32(greenShift)
            let b = (pixel & header.blueMask)  >> UInt32(blueShift)
            var a = (pixel & header.alphaMask) >> UInt32(alphaShift)
            
            a = a << 24
            r = r << 16
            g = g << 8
            
            pixelPtr[0] = a|r|g|b
            
            pixelPtr += 1
        }
        
        return bitmap
    }
    return nil
}

func findLeastSignificantSetBit(_ val: UInt32) -> Int {
    for i in 0..<32 {
        if (val & UInt32(1 << i)) != 0 {
            return i
        }
    }
    return -1
}



// WAV Files

struct WavFileHeader {
    var sGroupID : U32
    var dwFileLength : U32
    var sRiffType : U32
    var format_sGroupID : U32
    var dwChunkSize : U32
    var wFormatTag : U16
    var wChannels : U16
    var dwSamplesPerSec : U32
    var dwAvgBytesPerSec : U32
    var wBlockAlign : U16
    var dwBitsPerSampleLOW : U16 // Stupidness about memory alignment forces us to split this into two values
    var dwBitsPerSampleHIGH : U16
    
    var dwBitsPerSample : U32 { return (U32(dwBitsPerSampleHIGH) << 16) | U32(dwBitsPerSampleLOW) }
}

struct WavFileDataChunk {
    var sGroupID : U32
    var dwChunkSize : U32
}

struct StereoAudioSound {
//    var left : [U16]
//    var right: [U16]
    var samplesInterleaved : [S16]
}

func loadWavFile(_ filename: String) -> StereoAudioSound? {
    
    let fileOpt = readFile(assetPath(filename))
    if let file = fileOpt {
        let headerPtr = RawPtr(file.bytes).bindMemory(to: WavFileHeader.self, capacity: 1)
        let header = headerPtr.pointee
        
        let dataChunkHeaderPtr = RawPtr(file.bytes) + 36
        let dataChunkHeader = dataChunkHeaderPtr.bindMemory(to: WavFileDataChunk.self, capacity: 1).pointee
        
        let samplesPtr = dataChunkHeaderPtr + 8
        let samplesCount = Int(dataChunkHeader.dwChunkSize / 2)
        let samples = samplesPtr.bindMemory(to: S16.self, capacity: samplesCount)
        
//        var leftSamples : [U16] = []
//        var rightSamples : [U16] = []
//        
//        leftSamples.reserveCapacity(samplesCount / 2)
//        rightSamples.reserveCapacity(samplesCount / 2)
//        
//        for i in 0..<samplesCount {
//            let sample = samples[i]
//            if i % 2 == 0 {
//                leftSamples.append(sample)
//            }
//            else {
//                rightSamples.append(sample)
//            }
//        }
        
        var outSamples : [S16] = []
        outSamples.reserveCapacity(samplesCount)
        for i in 0..<samplesCount {
            outSamples.append(samples[i])
        }
        
        return StereoAudioSound(samplesInterleaved: outSamples)
    }
    return nil
    
}









