//
//  Font.swift
//  Asteroids
//
//  Created by Sean Hickey on 1/27/17.
//  Copyright © 2017 Sean Hickey. All rights reserved.
//

import Darwin
import simd

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

struct FontKerningPair {
    var first : U16
    var second : U16
    var kerning : F32
}

/*= BEGIN_REFSTRUCT =*/
struct BitmapFont {
    var chars : Ptr<BitmapChar> /*= GETSET =*/
    var advances : Ptr<F32> /*= GETSET =*/
    var texels : RawPtr /*= GETSET =*/
    var lineHeight : F32 /*= GETSET =*/
}
/*= END_REFSTRUCT =*/

/*= BEGIN_REFSTRUCT =*/
struct BitmapChar {
    var x : U32 = 0 /*= GETSET =*/
    var y : U32 = 0 /*= GETSET =*/
    var width : U32 = 0 /*= GETSET =*/
    var height : U32 = 0 /*= GETSET =*/
    var xOffset : F32 = 0 /*= GETSET =*/
    var yOffset : F32 = 0 /*= GETSET =*/
}
/*= END_REFSTRUCT =*/

func loadFont(_ assetZone: MemoryZoneRef, _ gameMemory: GameMemory, _ bytes: U8Ptr) -> BitmapFontRef {
    let headerPtr = RawPtr(bytes).bindMemory(to: FontHeader.self, capacity: 1)
    let header = headerPtr[0]
    let charsPtr = RawPtr(bytes + MemoryLayout<FontHeader>.size).bindMemory(to: FontCharacter.self, capacity: Int(header.numCharacters))
    let kernsPtr = RawPtr(charsPtr + Int(header.numCharacters)).bindMemory(to: FontKerningPair.self, capacity: Int(header.numKerns))
    let pixelsPtr = RawPtr(kernsPtr + Int(header.numKerns))
    
    let bitmapFontPtr = allocateTypeFromZone(assetZone, BitmapFont.self)
    let bitmapFont = BitmapFontRef(bitmapFontPtr)
    bitmapFont.chars = allocateFromZone(assetZone, MemoryLayout<BitmapChar>.stride * 200).bindMemory(to: BitmapChar.self, capacity: 200)
    bitmapFont.advances = allocateFromZone(assetZone, 4 * 200 * 200).bindMemory(to: F32.self, capacity: 4 * 200 * 200)
    
    for i in 0..<Int(header.numCharacters) {
        let fontChar = charsPtr[i]
        if fontChar.id >= 200 {
            print("Warning: tried to load glyph with codepoint greater than size of font character array")
            continue
        }
        var newChar = BitmapChar()
        newChar.width = fontChar.width
        newChar.x = fontChar.x
        newChar.y = fontChar.y
        newChar.height = fontChar.height
        newChar.xOffset = fontChar.xOffset
        newChar.yOffset = fontChar.yOffset
        
        // Set the default advances (kerns happen later)
        for j in 0..<200 {
            bitmapFont.advances[Int(fontChar.id) * 200 + j] = fontChar.xAdvance
        }
        bitmapFont.chars[Int(fontChar.id)] = newChar
    }
    
    for i in 0..<Int(header.numKerns) {
        let kern = kernsPtr[i]
        bitmapFont.advances[Int(kern.first) * 200 + Int(kern.second)] += kern.kerning
    }
    
    bitmapFont.texels = gameMemory.platformCreateTextureBuffer!(pixelsPtr, Int(header.pixelsPitch), Int(header.numPixels / header.pixelsPitch))
    
    bitmapFont.lineHeight = header.lineHeight
    
    return bitmapFont
}

func fontAdvanceForCodepointPair(_ font: BitmapFontRef, _ c1: U16, _ c2: U16) -> F32 {
    return font.advances[Int(c1) * 200 + Int(c2)]
}


/**************************************
 *
 * Font Rendering
 *
 **************************************/

func renderText(_ text: String, _ windowSize: Size, _ windowLocation: Vec2, _ font: BitmapFontRef, _ renderBuffer: RawPtr) -> RenderCommandText {
    
    var cursor : F32 = 0.0
    
    let codepoints = text.utf16
    
    let verts = VertexPointer.allocate(capacity: codepoints.count * 4 * 8)
    var vertsPtr = verts
    let indices = U16Ptr.allocate(capacity: 6 * codepoints.count)
    var indicesPtr = indices
    
    for (i, codepoint) in codepoints.enumerated() {
        let bmpChar = font.chars[Int(codepoint)]
        
        let startX = cursor + bmpChar.xOffset// + kerning
        let endX = startX + Float(bmpChar.width)
        let startY = bmpChar.yOffset
        let endY = startY + Float(bmpChar.height)
        
        
        let v : [Float] = [
            startX, startY, 0.0, 1.0, Float(bmpChar.x),                 Float(bmpChar.y + bmpChar.height),                  0.0, 0.0,
            startX, endY,   0.0, 1.0, Float(bmpChar.x),                 Float(bmpChar.y), 0.0, 0.0,
            endX,   startY, 0.0, 1.0, Float(bmpChar.x + bmpChar.width), Float(bmpChar.y + bmpChar.height),                  0.0, 0.0,
            endX,   endY,   0.0, 1.0, Float(bmpChar.x + bmpChar.width), Float(bmpChar.y), 0.0, 0.0,
            ]
        
        let idxOffset = UInt16(i * 4)
        let quadIndices : [UInt16] = [idxOffset, idxOffset + 1, idxOffset + 2, idxOffset + 1, idxOffset + 3, idxOffset + 2]
        
        memcpy(vertsPtr, v, 4 * 8 * MemoryLayout<Float>.size)
        memcpy(indicesPtr, quadIndices, 6 * MemoryLayout<UInt16>.size)
        
        vertsPtr += 4 * 8
        indicesPtr += 6
        
        if i < codepoints.count - 1 {
            let nextCodepoint = codepoints[codepoints.startIndex.advanced(by: i + 1)]
            let advance = fontAdvanceForCodepointPair(font, codepoint, nextCodepoint)
            cursor += Float(advance)
        }
    }
    
    var command = RenderCommandText()
    let normalizedLocation = windowToNormalizedCoordinates(windowLocation, windowSize)
    command.transform = translateTransform(normalizedLocation.x, normalizedLocation.y) * scaleTransform(1.0 / (windowSize.w / 2.0), 1.0 / (windowSize.h / 2.0))
    command.quadCount = codepoints.count
    command.quads = verts
    command.indices = indices
    command.texels = font.texels
    
    return command
    
}

