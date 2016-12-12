//
//  AssetLoader.swift
//  Asteroids
//
//  Created by Sean Hickey on 12/7/16.
//  Copyright © 2016 Sean Hickey. All rights reserved.
//

import Darwin

let assetDir : String = ({
    let components = dylibPath().characters.split("/")
    let dir = "/" + components.dropLast(1).map(String.init).joinWithSeparator("/")
    return dir + "/assets"
})()

func assetPath(filename: String) -> String {
    return assetDir + "/\(filename)"
}

func dylibPath() -> String {
    let symbolAddress = unsafeBitCast(Entity.self, UnsafeMutablePointer<Void>.self)
    var info = Dl_info(dli_fname: "", dli_fbase: nil, dli_sname: "", dli_saddr: nil)
    dladdr(symbolAddress, &info)
    let path = String.fromCString(info.dli_fname)!
    return path
}

class FileData {
    var length: Int = 0
    var bytes: U8Ptr = nil
}

func readFile(path: String) -> FileData? {
    
    let data = FileData()
    
    let filePtr = fopen(path, "rb")
    if filePtr != nil {
        fseek(filePtr, 0, SEEK_END)
        data.length = ftell(filePtr)
        fseek(filePtr, 0, SEEK_SET)
        
        data.bytes = U8Ptr.alloc(data.length)
        fread(data.bytes, data.length, 1, filePtr)
        fclose(filePtr)
        
        return data
    }
    return nil
}



func loadTextAsset(filename: String) -> String? {
    
    let fileOpt = readFile(assetPath(filename))
    if let file = fileOpt {
        let nulTerm = UnsafeMutablePointer<CChar>.alloc(file.length + 1)
        memcpy(nulTerm, file.bytes, file.length)
        nulTerm[file.length] = 0
        let s = String.fromCString(nulTerm)
        return s
    }
    return nil
}

// Bitmap Loading


struct BitmapHeader {
    let base : U8Ptr
    
    var type          : UInt16 { return U16Ptr(base +  0)[0] }
    var size          : UInt32 { return U32Ptr(base +  2)[0] }
    var reserved1     : UInt16 { return U16Ptr(base +  6)[0] }
    var reserved2     : UInt16 { return U16Ptr(base +  8)[0] }
    var offBits       : UInt32 { return U32Ptr(base + 10)[0] }
    var infoSize      : UInt32 { return U32Ptr(base + 14)[0] }
    var width         : Int32  { return S32Ptr(base + 18)[0] }
    var height        : Int32  { return S32Ptr(base + 22)[0] }
    var planes        : UInt16 { return U16Ptr(base + 26)[0] }
    var bitCount      : UInt16 { return U16Ptr(base + 28)[0] }
    var compression   : UInt32 { return U32Ptr(base + 30)[0] }
    var sizeImage     : UInt32 { return U32Ptr(base + 34)[0] }
    var xPelsPerMeter : Int32  { return S32Ptr(base + 38)[0] }
    var yPelsPerMeter : Int32  { return S32Ptr(base + 42)[0] }
    var clrUsed       : UInt32 { return U32Ptr(base + 46)[0] }
    var clrImportant  : UInt32 { return U32Ptr(base + 50)[0] }
    var redMask       : UInt32 { return U32Ptr(base + 54)[0] }
    var greenMask     : UInt32 { return U32Ptr(base + 58)[0] }
    var blueMask      : UInt32 { return U32Ptr(base + 62)[0] }
    var alphaMask     : UInt32 { return U32Ptr(base + 66)[0] }
    
    var pixels : U32Ptr {
        return U32Ptr(base + Int(offBits))
    }
    
    init(_ newBase: U8Ptr) {
        base = newBase
    }
}

class Bitmap {
    var width  : Int = 0
    var height : Int = 0
    var stride : Int = 0
    var pixels : U32Ptr = nil
}

func loadBitmap(filename: String) -> Bitmap? {
    let fileOpt = readFile(assetPath(filename))
    if let file = fileOpt {
        let header = BitmapHeader(file.bytes)
        
        let bitmap = Bitmap()
        bitmap.width = Int(header.width)
        bitmap.height = Int(header.height)
        bitmap.stride = Int(header.bitCount) * bitmap.width
        bitmap.pixels = header.pixels
        
        let redShift   = findLeastSignificantSetBit(header.redMask)
        let greenShift = findLeastSignificantSetBit(header.greenMask)
        let blueShift  = findLeastSignificantSetBit(header.blueMask)
        let alphaShift = findLeastSignificantSetBit(header.alphaMask)
        
        var pixelPtr = bitmap.pixels
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

func findLeastSignificantSetBit(val: UInt32) -> Int {
    for i in 0..<32 {
        if (val & UInt32(1 << i)) != 0 {
            return i
        }
    }
    return -1
}









