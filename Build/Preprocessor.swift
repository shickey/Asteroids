import Foundation


extension String {
    subscript(range: NSRange) -> String {
        get {
            let start = self.index(self.startIndex, offsetBy: range.location)
            let end = self.index(start, offsetBy: range.length)
            return self.substring(with: start..<end)
        }
    }
    
    func range(from nsrange: NSRange) -> Range<Index>? {
        guard let range = nsrange.toRange() else { return nil }
        let utf16Start = UTF16Index(range.lowerBound)
        let utf16End = UTF16Index(range.upperBound)
        
        guard let start = Index(utf16Start, within: self),
            let end = Index(utf16End, within: self)
            else { return nil }
        
        return start..<end
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

var gameFilepaths : [String] = []

if let gameFilepathsString = env["GAME_FILES"] {
    let paths = gameFilepathsString.components(separatedBy: "\n")
    for path in paths {
        if URL(fileURLWithPath: path).lastPathComponent == "RefStructs_GENERATED.swift" {
            continue;
        }
        gameFilepaths.append(path)
    }
}

/*********************
 Ref class and Renderable ID generation
 *********************/

// Preprocess files
var refStructs : [String : [RefStruct]] = [:]
for filepath in gameFilepaths {
    let filename = URL(fileURLWithPath: filepath).lastPathComponent
    
    var source = try! String(contentsOfFile: filepath)
    refStructs[filename] = parseRefStructs(source)
}

var outputString = "/***************************************************\n* ReferenceStructs.swift\n*\n* THIS FILE IS AUTOGENERATED WITH EACH BUILD.\n* DON'T WRITE ANYTHING IMPORTANT IN HERE!\n****************************************************/\nclass Ref<T> {\n    var ptr : Ptr<T>\n    init(referencing: inout T) {\n        ptr = Ptr<T>(&referencing)\n    }\n    init(_ newPtr: Ptr<T>) {\n        ptr = newPtr\n    }\n}\n\n"

var entities : [RefStruct] = []

// Generate output structs, grab all entities
for (filename, structs) in refStructs {
    if structs.count == 0 {
        continue
    }
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
if let sourceFolder = env["SOURCE_ROOT"] {
    let outputPath = sourceFolder + "/AsteroidsGame/RefStructs_GENERATED.swift"
    try! outputString.write(toFile: outputPath, atomically: true, encoding: .utf8)
}


/*********************
 TIMED_BLOCK generation
 *********************/

// Returns nil if there are no timed blocks to match
func preprocessTimedBlocks(_ source: String, _ nextBlockId: inout Int) -> String? {
    let timedBlockRegex = try! NSRegularExpression(pattern: "^(.*)(/\\*=\\s*TIMED_BLOCK\\s*=\\*/.*)$", options: [.anchorsMatchLines, .useUnixLineSeparators])

    let matches = timedBlockRegex.matches(in: source, options: [], range: NSMakeRange(0, source.characters.count))
    
    if matches.count == 0 {
        return nil
    }
    
    var preprocessedSource = source
    for (idx, match) in matches.reversed().enumerated() {
        let template = "$1/*= TIMED_BLOCK =*/ TIMED_BLOCK_BEGIN(\(nextBlockId + (matches.count - 1 - idx))); defer { TIMED_BLOCK_END(\(nextBlockId + (matches.count - 1 - idx))) };"
        let replacement = timedBlockRegex.replacementString(for: match, in: source, offset: 0, template: template)
        let matchRange = preprocessedSource.range(from: match.range)!
        preprocessedSource.replaceSubrange(matchRange, with: replacement)
    }
    
    nextBlockId += matches.count
    
    return preprocessedSource
}

var nextTimedBlockId = 0
for filepath in gameFilepaths {
    let filename = URL(fileURLWithPath: filepath).lastPathComponent
    var source = try! String(contentsOfFile: filepath)
    
    if let preprocessed = preprocessTimedBlocks(source, &nextTimedBlockId) {
        print(preprocessed)
    }
}






















