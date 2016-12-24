//
//  Font.swift
//  Asteroids
//
//  Created by Sean Hickey on 12/6/16.
//  Copyright © 2016 Sean Hickey. All rights reserved.
//

/*= BEGIN_REFSTRUCT =*/
struct BitmapFont {
    var baselineHeight : Float /*= GETSET =*/
    var chars : Ptr<BitmapChar> /*= GETSET =*/
//    var kerns : Dictionary<Int, Array<BitmapKerning>>
    var bitmap : BitmapRef /*= GETSET =*/
}
/*= END_REFSTRUCT =*/

/*= BEGIN_REFSTRUCT =*/
struct BitmapChar {
    var x : Float = 0 /*= GETSET =*/
    var y : Float = 0 /*= GETSET =*/
    var width : Float = 0 /*= GETSET =*/
    var height : Float = 0 /*= GETSET =*/
    var xOffset : Float = 0 /*= GETSET =*/
    var yOffset : Float = 0 /*= GETSET =*/
    var advance : Float = 0 /*= GETSET =*/
}
/*= END_REFSTRUCT =*/

//struct BitmapKerning {
//    var first : Int /*= GETSET =*/
//    var second : Int /*= GETSET =*/
//    var offset : Int /*= GETSET =*/
//}

func loadBitmapFont(_ assetZone: MemoryZoneRef, _ fontName: String) -> BitmapFontRef {
    
    let bitmapFontPtr = allocateTypeFromZone(assetZone, BitmapFont.self)
    var bitmapFont = BitmapFontRef(ptr: bitmapFontPtr)
    
//    bitmapFont.chars = [:]
//    bitmapFont.kerns = [:]
    
    bitmapFont.chars = allocateFromZone(assetZone, MemoryLayout<BitmapChar>.stride * 200).bindMemory(to: BitmapChar.self, capacity: 200)
    
    var fontDesc = loadTextAsset(fontName)!
    
    var bmpName : String! = nil
    
    let lines = fontDesc.characters.split(separator: "\n")
    for line in lines {
        let tokens = line.split(separator: " ")
        if String(tokens[0]) == "common" {
            for token in tokens {
                let pairs = token.split(separator: "=")
                if String(pairs[0]) == "base" {
                    bitmapFont.baselineHeight = Float(String(pairs[1]))!
                }
            }
        }
        else if String(tokens[0]) == "page" {
            for token in tokens {
                let pairs = token.split(separator: "=")
                if String(pairs[0]) == "file" {
                    let s = String(pairs[1])
                    bmpName = s[s.characters.index(s.startIndex, offsetBy: 1)..<s.characters.index(before: s.endIndex)]
                }
            }
        }
        else if String(tokens[0]) == "char" {
            var charId : Int? = nil
            var c = BitmapChar()
            for token in tokens {
                let props = token.split(separator: "=")
                switch String(props[0]) {
                case "id":
                    charId = Int(String(props[1]))
                case "x":
                    c.x = Float(String(props[1]))!
                case "y":
                    c.y = Float(String(props[1]))!
                case "width":
                    c.width = Float(String(props[1]))!
                case "height":
                    c.height = Float(String(props[1]))!
                case "xoffset":
                    c.xOffset = Float(String(props[1]))!
                case "yoffset":
                    c.yOffset = Float(String(props[1]))!
                case "xadvance":
                    c.advance = Float(String(props[1]))!
                default: break
                }
            }
            if let id = charId {
                if id > 200 {
                    print("game over, man")
                    continue
                }
                bitmapFont.chars[id] = c
            }
        }
//        else if String(tokens[0]) == "kerning" {
//            var k = BitmapKerning()
//            for token in tokens {
//                let props = token.split(separator: "=")
//                switch String(props[0]) {
//                case "first":
//                    k.first = Int(String(props[1]))
//                case "second":
//                    k.second = Int(String(props[1]))
//                case "amount":
//                    k.offset = Int(String(props[1]))
//                default: break
//                }
//            }
//            if bitmapFont.kerns[k.first] == nil {
//                bitmapFont.kerns[k.first] = []
//            }
//            bitmapFont.kerns[k.first]!.append(k)
//        }
    }
    bitmapFont.bitmap = loadBitmap(assetZone, bmpName)
    
    return bitmapFont
    
}

