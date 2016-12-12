//
//  Font.swift
//  Asteroids
//
//  Created by Sean Hickey on 12/6/16.
//  Copyright © 2016 Sean Hickey. All rights reserved.
//

public struct BitmapFont {
    var baselineHeight : Int = 0
    var chars : [Int : BitmapChar]
    var kerns : [Int : [BitmapKerning]]
    var bitmap : Bitmap
    
    init(_ fontDesc: String) {
        chars = [:]
        kerns = [:]
        
        var bmpName : String! = nil
        
        let lines = fontDesc.characters.split("\n")
        for line in lines {
            let tokens = line.split(" ")
            if String(tokens[0]) == "common" {
                for token in tokens {
                    let pairs = token.split("=")
                    if String(pairs[0]) == "base" {
                        baselineHeight = Int(String(pairs[1]))!
                    }
                }
            }
            else if String(tokens[0]) == "page" {
                for token in tokens {
                    let pairs = token.split("=")
                    if String(pairs[0]) == "file" {
                        let s = String(pairs[1])
                        bmpName = s[s.startIndex.advancedBy(1)..<s.endIndex.predecessor()]
                    }
                }
            }
            else if String(tokens[0]) == "char" {
                var c = BitmapChar()
                for token in tokens {
                    let props = token.split("=")
                    switch String(props[0]) {
                    case "id":
                        c.id = Int(String(props[1]))
                    case "x":
                        c.x = Int(String(props[1]))
                    case "y":
                        c.y = Int(String(props[1]))
                    case "width":
                        c.width = Int(String(props[1]))
                    case "height":
                        c.height = Int(String(props[1]))
                    case "xoffset":
                        c.xOffset = Int(String(props[1]))
                    case "yoffset":
                        c.yOffset = Int(String(props[1]))
                    case "xadvance":
                        c.advance = Int(String(props[1]))
                    default: break
                    }
                }
                chars[c.id] = c
            }
            else if String(tokens[0]) == "kerning" {
                var k = BitmapKerning()
                for token in tokens {
                    let props = token.split("=")
                    switch String(props[0]) {
                    case "first":
                        k.first = Int(String(props[1]))
                    case "second":
                        k.second = Int(String(props[1]))
                    case "amount":
                        k.offset = Int(String(props[1]))
                    default: break
                    }
                }
                if kerns[k.first] == nil {
                    kerns[k.first] = []
                }
                kerns[k.first]!.append(k)
            }
        }
        bitmap = loadBitmap(bmpName)!
    }
}

struct BitmapChar {
    var id : Int! = nil
    
    // Texture Bounds
    var x : Int! = nil
    var y : Int! = nil
    
    var width : Int! = nil
    var height : Int! = nil
    var xOffset : Int! = nil
    var yOffset : Int! = nil
    var advance : Int! = nil
}

struct BitmapKerning {
    var first : Int! = nil
    var second : Int! = nil
    var offset : Int! = nil
}

