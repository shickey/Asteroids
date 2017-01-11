import Foundation


extension String {
    subscript(range: NSRange) -> String {
        get {
            let start = self.index(self.startIndex, offsetBy: range.location)
            let end = self.index(start, offsetBy: range.length)
            return self.substring(with: start..<end)
        }
    }
}

struct RefStruct {
    var type : String = ""
    var genericType : String = ""
    var inheritedTypes : String = ""
    var properties : [RefStructProperty] = []
}

struct RefStructProperty {
    enum AccessorType {
        case get
        case set
        case getset
    }
    
    var name : String = ""
    var type : String = ""
    var accessorType : AccessorType = .getset
}

func parseRefStructs(_ source: String) -> [RefStruct] {
    
    let structRegex = try! NSRegularExpression(pattern: "/\\*=\\s*BEGIN_REFSTRUCT\\s*=\\*/\\s*(.*?)\\s*/\\*=\\s*END_REFSTRUCT\\s*=\\*/", options: [.dotMatchesLineSeparators, .allowCommentsAndWhitespace])
    
    let declRegex = try! NSRegularExpression(pattern: "^\\s*struct\\s+([\\w]+)(<([\\w\\s\\,&:]*)>)?\\s*(:\\s*(\\w+\\?*)\\s*)?\\{\\s*$", options: [.anchorsMatchLines, .useUnixLineSeparators])
    
    let propertyRegex = try! NSRegularExpression(pattern: "^(\\s+var\\s+(\\w+)\\s+:\\s+([\\w<>\\,\\s\\.]+\\??))\\s+/\\*=\\s(GETSET|GET|SET)\\s=\\*/$", options: [.anchorsMatchLines, .useUnixLineSeparators])
    
    var refStructs : [RefStruct] = []
    
    structRegex.enumerateMatches(in: source, options: [], range: NSMakeRange(0, source.characters.count), using: { (result, flags, stopPtr) in
        
        let range = result!.rangeAt(1)
        let structString = source[range]
        
        declRegex.enumerateMatches(in: structString, options: [], range: NSMakeRange(0, structString.characters.count), using: { (result, flags, stopPtr) in
            
            let typeName = structString[result!.rangeAt(1)]
            
            var genericType = ""
            if result!.rangeAt(3).location != NSNotFound {
                genericType = structString[result!.rangeAt(3)]
            }
            
            var inheritedTypes = ""
            if result!.rangeAt(5).location != NSNotFound {
                inheritedTypes = structString[result!.rangeAt(5)]

            }
            
            var refStruct = RefStruct()
            refStruct.type = typeName
            refStruct.genericType = genericType
            refStruct.inheritedTypes = inheritedTypes
            
            propertyRegex.enumerateMatches(in: structString, options: [], range: NSMakeRange(0, structString.characters.count), using: { (result, flags, stopPtr) in
                
                var prop = RefStructProperty()
                
                prop.name = structString[result!.rangeAt(2)]
                prop.type = structString[result!.rangeAt(3)]
                let accessorTypeString = structString[result!.rangeAt(4)]
                if accessorTypeString == "GET" {
                    prop.accessorType = .get
                }
                else if accessorTypeString == "SET" {
                    prop.accessorType = .set
                }
                else if accessorTypeString == "GETSET" {
                    prop.accessorType = .getset
                }
                
                refStruct.properties.append(prop)

            })
            
            refStructs.append(refStruct)
        })
        
    })
    
    return refStructs
}

func outputStringForRefStruct(_ refStruct: RefStruct) -> String {
    var genericDecl = ""
    if refStruct.genericType != "" {
        genericDecl = "<\(refStruct.genericType)>"
    }
    
    var result = "class \(refStruct.type)Ref\(genericDecl) : "
    
    if refStruct.inheritedTypes == "Entity" {
        result += "EntityRef<\(refStruct.type)> {\n"
    }
    else {
        result += "Ref<\(refStruct.type)\(genericDecl)> {\n"
    }
    
    for prop in refStruct.properties {
        if refStruct.inheritedTypes == "Entity" && prop.name == "base" {
            continue
        }
        
        var propDecl = "    var \(prop.name) : \(prop.type) { "
        if prop.accessorType == .get || prop.accessorType == .getset {
            propDecl += "get { return ptr.pointee.\(prop.name) } "
        }
        if prop.accessorType == .set || prop.accessorType == .getset {
            propDecl += "set(val) { ptr.pointee.\(prop.name) = val } "
        }
        propDecl += "}\n"
        
        result += propDecl
    }
    
    
    result += "}\n\n"
    
    return result
}




let env = ProcessInfo.processInfo.environment

if let numInputsStr = env["SCRIPT_INPUT_FILE_COUNT"] {
    let numInputs = Int(numInputsStr)!
    
    // Preprocess files
    var refStructs : [String : [RefStruct]] = [:]
    for i in 0..<numInputs {
        if let inputPath = env["SCRIPT_INPUT_FILE_\(i)"] {
            let filename = (inputPath as NSString).lastPathComponent
            var source = try! String(contentsOfFile: inputPath)
            refStructs[filename] = parseRefStructs(source)
        }
    }
    
    var outputString = "/***************************************************\n* ReferenceStructs.swift\n*\n* THIS FILE IS AUTOGENERATED WITH EACH BUILD.\n* DON'T WRITE ANYTHING IMPORTANT IN HERE!\n****************************************************/\nclass Ref<T> {\n    var ptr : Ptr<T>\n    init(referencing: inout T) {\n        ptr = Ptr<T>(&referencing)\n    }\n    init(_ newPtr: Ptr<T>) {\n        ptr = newPtr\n    }\n}\n\n"
    
    var entities : [RefStruct] = []
    
    // Generate output structs, grab all entities
    for (filename, structs) in refStructs {
        outputString += "/************************\n * \(filename)\n ************************/\n\n"
        for refStruct in structs {
            if refStruct.inheritedTypes == "Entity" {
                entities.append(refStruct)
            }
            outputString += outputStringForRefStruct(refStruct)
        }
    }
    
    // Generate renderable ids
    outputString += "/************************\n * Renderable Type Ids\n ************************/\n\n"
    for entity in entities {
        // Hash the entity name. This has the nice property of being deterministic between builds
        var hash : UInt64 = 0
        for c in entity.type.unicodeScalars {
            hash = UInt64(c.value) &+ (hash << 6) &+ (hash << 16) &- hash // The &+ and &- allow overflow
        }
        outputString += "extension \(entity.type) {\n  static var renderableId : RenderableId = 0x\(String(format:"%08X", hash >> 32))\(String(format:"%08X", hash))\n}\n\n"
        outputString += "extension \(entity.type)Ref {\n  static var renderableId : RenderableId { get { return \(entity.type).renderableId } }\n}\n\n"
    }
    
    // Write file
    if let outputPath = env["SCRIPT_OUTPUT_FILE_0"] {
        try! outputString.write(toFile: outputPath, atomically: true, encoding: .utf8)
    }
}

