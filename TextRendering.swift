//
//  TextRendering.swift
//  Asteroids
//
//  Created by Sean Hickey on 12/9/16.
//  Copyright © 2016 Sean Hickey. All rights reserved.
//

import Darwin
import simd

func renderText(text: String, _ font: BitmapFont) -> RenderCommandText {
    
    var cursor : Float = 0.0
    
    let chars = text.utf8
    
    let verts = VertexPointer.alloc(chars.count * 4 * 8)
    var vertsPtr = verts
    let indices = U16Ptr.alloc(6 * chars.count)
    var indicesPtr = indices
    
    for (i, char) in chars.enumerate() {
        if let bmpChar = font.chars[Int(char)] {
            
            // Kerning
            var kerning : Float = 0.0
            if i > 0 {
                let prevChar = chars[chars.startIndex.advancedBy(i - 1)]
                if let kerns = font.kerns[Int(prevChar)] {
                    for kern in kerns {
                        if kern.second == Int(char) {
                            kerning = Float(kern.offset)
                            break
                        }
                    }
                }
            }
            
            
            
            let startX = cursor + Float(bmpChar.xOffset) + kerning
            let endX = startX + Float(bmpChar.width)
            let startY = Float(font.baselineHeight) - Float(bmpChar.yOffset) - Float(bmpChar.height)
            let endY = startY + Float(bmpChar.height)
            
            
            // TODO: Flip bitmaps rows to access them normally?
            let v : [Float] = [
                startX, startY, 0.0, 1.0, Float(bmpChar.x),                 Float(font.bitmap.height) - Float(bmpChar.y + bmpChar.height), 0.0, 0.0,
                startX, endY,   0.0, 1.0, Float(bmpChar.x),                 Float(font.bitmap.height) - Float(bmpChar.y),                  0.0, 0.0,
                endX,   startY, 0.0, 1.0, Float(bmpChar.x + bmpChar.width), Float(font.bitmap.height) - Float(bmpChar.y + bmpChar.height), 0.0, 0.0,
                endX,   endY,   0.0, 1.0, Float(bmpChar.x + bmpChar.width), Float(font.bitmap.height) - Float(bmpChar.y),                  0.0, 0.0,
            ]
            
            let idxOffset = UInt16(i * 4)
            let quadIndices : [UInt16] = [idxOffset, idxOffset + 1, idxOffset + 2, idxOffset + 1, idxOffset + 3, idxOffset + 2]
            
            memcpy(vertsPtr, v, 4 * 8 * sizeof(Float))
            memcpy(indicesPtr, quadIndices, 6 * sizeof(UInt16))
            
            vertsPtr += 4 * 8
            indicesPtr += 6
            cursor += Float(bmpChar.advance)
        }
        else {
            print("unknown character found")
            // TODO: Render blank box or something?
        }
    }
    
    let command = RenderCommandText()
    command.transform = translateTransform(-0.5, 0.0) * scaleTransform(1.0 / 250.0, 1.0 / 250.0)
    command.quadCount = chars.count
    command.quads = verts
    command.indices = indices
    command.texels = U8Ptr(font.bitmap.pixels)
    command.width = font.bitmap.width
    command.height = font.bitmap.height
    command.stride = font.bitmap.stride
    
    return command
    
}

