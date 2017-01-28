//
//  main.swift
//  GenerateFonts
//
//  Created by Sean Hickey on 1/20/17.
//  Copyright © 2017 Sean Hickey. All rights reserved.
//

import Cocoa
import CoreText
import QuartzCore

typealias U8  = UInt8
typealias U16 = UInt16
typealias U32 = UInt32
typealias U64 = UInt64

typealias S8  = Int8
typealias S16 = Int16
typealias S32 = Int32
typealias S64 = Int64

typealias F32 = Float
typealias F64 = Double

typealias RawPtr = UnsafeMutableRawPointer
typealias Ptr<T> = UnsafeMutablePointer<T>



struct BitmapCharacter {
    var pixels : Ptr<U32>?
    var width : Int
    var height : Int
    
    var xOffset : Double
    var yOffset : Double
    var xAdvance : Double
}

struct KerningPair {
    var first : U16
    var second : U16
    var kerning : F32
}


func copyPixels(_ srcPixels: Ptr<U32>, _ srcPitch: Int, _ srcRect: CGRect, _ dstPixels: Ptr<U32>, _ dstPitch: Int, _ dstOrigin: CGPoint) {
    for y in 0..<Int(srcRect.size.height) {
        for x in 0..<Int(srcRect.size.width) {
            dstPixels[(y + Int(dstOrigin.y)) * dstPitch + (x + Int(dstOrigin.x))] = srcPixels[(y + Int(srcRect.origin.y)) * srcPitch + (x + Int(srcRect.origin.x))]
        }
    }
}

func kerningForCodepoints(_ first: U16, _ second: U16, _ font: CTFont) -> F32 {
    let codepoints : [unichar] = [first, second]
    let str = String(utf16CodeUnits: codepoints, count: 2)
    let unkerned = CFAttributedStringCreate(kCFAllocatorDefault, str as CFString, [
        NSFontAttributeName : font,
        NSKernAttributeName : 0,
    ] as CFDictionary)!
    let kerned = CFAttributedStringCreate(kCFAllocatorDefault, str as CFString, [
        NSFontAttributeName : font,
    ] as CFDictionary)!
    
    let unkernedLine = CTLineCreateWithAttributedString(unkerned)
    let kernedLine = CTLineCreateWithAttributedString(kerned)
    
    let unkernedOffset = CTLineGetOffsetForStringIndex(unkernedLine, 1, nil)
    let kernedOffset = CTLineGetOffsetForStringIndex(kernedLine, 1, nil)
    
    return F32(kernedOffset - unkernedOffset)
}


//let font = NSFont.monospacedDigitSystemFont(ofSize: 14.0, weight: 0.0) as CTFont
let font = NSFont(name: "Arial", size: 28
    .0)! as CTFont
let lineHeight = CTFontGetAscent(font) + abs(CTFontGetDescent(font)) + CTFontGetLeading(font)

let chars = " ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789()[]{};:'\"<>?,./\\!@#$%^&*-_+=~"
let unichars = chars.utf16.map { $0 }

var glyphs = UnsafeMutablePointer<CGGlyph>.allocate(capacity: unichars.count)
CTFontGetGlyphsForCharacters(font, unichars, glyphs, unichars.count)

var boundingBoxes = UnsafeMutablePointer<CGRect>.allocate(capacity: unichars.count)
CTFontGetBoundingRectsForGlyphs(font, .default, glyphs, boundingBoxes, unichars.count)

var advances = UnsafeMutablePointer<CGSize>.allocate(capacity: unichars.count)
CTFontGetAdvancesForGlyphs(font, .default, glyphs, advances, unichars.count)




var bitmapChars = [U16 : BitmapCharacter]()


let width = 64
let height = 64
let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 4 * 64, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue)!

context.setFillColor(gray: 1.0, alpha: 1.0)
var point = CGPoint(x: width / 2, y: height / 2)

let pixels = context.data!.bindMemory(to: U32.self, capacity: context.width * context.height)

// Handle space character separately
bitmapChars[32] = BitmapCharacter(pixels: nil, width: 0, height: 0, xOffset: 0, yOffset: 0, xAdvance: Double(advances[0].width))

for glyphIdx in 1..<unichars.count { // Start at 1 to skip over space
    context.clear(CGRect(x: 0, y: 0, width: width, height: height))
    
    CTFontDrawGlyphs(font, glyphs + glyphIdx, &point, 1, context)
    
    var minX : Int = Int.max
    var maxX : Int = Int.min
    var minY : Int = Int.max
    var maxY : Int = Int.min
    
    for y in 0..<context.height {
        for x in 0..<context.width {
            let pixel = pixels[y * context.width + x]
            let a = pixel & 0xFF
            if a != 0 {
                if x < minX {
                    minX = x
                }
                if x > maxX {
                    maxX = x
                }
                if y < minY {
                    minY = y
                }
                if y > maxY {
                    maxY = y
                }
            }
        }
    }
    
    let boundedWidth = maxX - minX + 1
    let boundedHeight = maxY - minY + 1
    
    var rawBoundedPixels = UnsafeMutableRawPointer.allocate(bytes: 4 * boundedWidth * boundedHeight, alignedTo: MemoryLayout<U32>.alignment)
    var boundedPixels = rawBoundedPixels.bindMemory(to: U32.self, capacity: boundedWidth * boundedHeight)
    
    copyPixels(pixels, width, CGRect(x: minX, y: minY, width: boundedWidth, height: boundedHeight), boundedPixels, boundedWidth, CGPoint(x: 0, y: 0))
    
    let boundingBox = boundingBoxes[glyphIdx]
    let advance = advances[glyphIdx]
    
    let additionalYOffset = Double(point.y - CGFloat(maxY)) - Double(ceil(boundingBox.origin.y))
    
    let newChar = BitmapCharacter(pixels: boundedPixels, width: boundedWidth, height: boundedHeight, xOffset: Double(boundingBox.origin.x), yOffset: Double(boundingBox.origin.y) + additionalYOffset, xAdvance: Double(advance.width))
    
    bitmapChars[unichars[glyphIdx]] = newChar
}

var padding = 1

var maxHeight = 0
var totalWidth = 0

for (_, bc) in bitmapChars {
    if bc.height > maxHeight {
        maxHeight = bc.height
    }
    totalWidth += bc.width + (2 * padding)
}

maxHeight += 2 * padding


let atlasContext = CGContext(data: nil, width: totalWidth, height: maxHeight, bitsPerComponent: 8, bytesPerRow: 4 * totalWidth, space: context.colorSpace!, bitmapInfo: context.bitmapInfo.rawValue)!
let atlasPixels = atlasContext.data!.bindMemory(to: U32.self, capacity: atlasContext.width * atlasContext.height)

var pixelOffsets : [U16 : (U32, U32)] = [:]

var cursor = padding
for (codepoint, bc) in bitmapChars {
    if bc.pixels != nil {
        copyPixels(bc.pixels!, bc.width, CGRect(x: 0, y: 0, width: bc.width, height: bc.height), atlasPixels, totalWidth, CGPoint(x: cursor, y: padding))
        pixelOffsets[codepoint] = (U32(cursor), U32(padding))
    }
    else {
        pixelOffsets[codepoint] = (0, 0)
    }
    cursor += bc.width + (2 * padding)
}

// Calculate kerning pair
var kerningPairs : [KerningPair] = []
for c1 in unichars {
    for c2 in unichars {
        if c1 == c2 {
            continue
        }
        let kerning = kerningForCodepoints(c1, c2, font)
        if kerning != 0 {
            //            let str = String(utf16CodeUnits: [c1, c2], count: 2)
            //            print("\(str) kerning: \(kerning)")
            kerningPairs.append(KerningPair(first: c1, second: c2, kerning: kerning))
        }
    }
}




struct FontHeader {
    var magic : U32 = 0xF00D4DAD
    var numCharacters : U32
    var numKerns : U32
    var numPixels : U32
    var pixelsPitch : U32
    
    var lineHeight : F32
}


struct FontCharacter {
    var id : U32
    var x : U32
    var y : U32
    var width : U32
    var height : U32
    var xOffset : F32
    var yOffset : F32
    var xAdvance : F32
}



// Write the font header
var header = FontHeader(magic: 0xF00D4DAD, numCharacters: U32(bitmapChars.count), numKerns: U32(kerningPairs.count), numPixels: U32(totalWidth * maxHeight), pixelsPitch: U32(totalWidth), lineHeight: F32(lineHeight))
let headerPtr = RawPtr(&header).bindMemory(to: U8.self, capacity: MemoryLayout<FontHeader>.size)

var fontData = Data()
fontData.append(headerPtr, count: MemoryLayout<FontHeader>.size)

// Write the character information
for (codepoint, bc) in bitmapChars {
    var offset = pixelOffsets[codepoint]!
    var fontChar = FontCharacter(id: U32(codepoint), x: offset.0, y: offset.1, width: U32(bc.width), height: U32(bc.height), xOffset: F32(bc.xOffset), yOffset: F32(bc.yOffset), xAdvance: F32(bc.xAdvance))
    var fontCharPtr = RawPtr(&fontChar).bindMemory(to: U8.self, capacity: MemoryLayout<FontCharacter>.size)
    fontData.append(fontCharPtr, count: MemoryLayout<FontCharacter>.size)
}

// Write the kerning pairs
for pair in kerningPairs {
    var mutablePair = pair
    let kernPtr = RawPtr(&mutablePair).bindMemory(to: U8.self, capacity: MemoryLayout<KerningPair>.size)
    fontData.append(kernPtr, count: MemoryLayout<KerningPair>.size)
}

// Write the pixel data
var atlasBytes = atlasContext.data!.bindMemory(to: U8.self, capacity: 4 * totalWidth * maxHeight)
fontData.append(atlasBytes, count: 4 * totalWidth * maxHeight)


// TODO: Fix this hardcoded URL
try! fontData.write(to: URL(fileURLWithPath: "/Users/seanhickey/Development/Asteroids/AsteroidsGame/Assets/font.bin"))




//let image = atlasContext.makeImage()!
//
//let url = URL(fileURLWithPath: "/Users/seanhickey/Desktop/atlas.png")
//
//let dest = CGImageDestinationCreateWithURL(url as CFURL, kUTTypePNG, 1, nil)!
//CGImageDestinationAddImage(dest, image, nil)
//CGImageDestinationFinalize(dest)





//for (i, bc) in bitmapChars.enumerated() {
//    let charContext = CGContext(data: bc.pixels, width: bc.width, height: bc.height, bitsPerComponent: 8, bytesPerRow: 4 * bc.width, space: context.colorSpace!, bitmapInfo: context.bitmapInfo.rawValue)!
//    
//    let image = charContext.makeImage()!
//    
//    let url = URL(fileURLWithPath: "/Users/seanhickey/Desktop/letter_\(i).png")
//    
//    let dest = CGImageDestinationCreateWithURL(url as CFURL, kUTTypePNG, 1, nil)!
//    CGImageDestinationAddImage(dest, image, nil)
//    CGImageDestinationFinalize(dest)
//}




//let wordContext = CGContext(data: nil, width: 200, height: 32, bitsPerComponent: 8, bytesPerRow: 4 * 200, space: context.colorSpace!, bitmapInfo: context.bitmapInfo.rawValue)!
//
//
//var xCursor : CGFloat = 2.0
//var baseline = abs(CTFontGetDescent(font)) + CTFontGetLeading(font)
//
//for codepoint in "Hello, world!".utf16 {
//    let letter = bitmapChars[codepoint]!
//    if letter.pixels != nil {
//        let letterContext = CGContext(data: letter.pixels, width: letter.width, height: letter.height, bitsPerComponent: 8, bytesPerRow: 4 * letter.width, space: context.colorSpace!, bitmapInfo: context.bitmapInfo.rawValue)!
//        let image = letterContext.makeImage()!
//        
//        let imageRect = CGRect(x: xCursor + CGFloat(letter.xOffset), y: baseline + CGFloat(letter.yOffset), width: CGFloat(letter.width), height: CGFloat(letter.height))
//        wordContext.draw(image, in: imageRect)
//    }
//    xCursor += CGFloat(letter.xAdvance)
//}

