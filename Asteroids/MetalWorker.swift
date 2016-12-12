import Cocoa
import Metal
import QuartzCore
import CoreVideo
import simd
import IOKit
import IOKit.hid

let gameCodeLibName = "libAsteroids"
let updateAndRenderSymbolName = "_TF12libAsteroids15updateAndRenderFTGSpCS_10GameMemory_9inputsPtrGSpCS_6Inputs_17renderCommandsPtrGSpCS_19RenderCommandBuffer__T_"

let device = MTLCreateSystemDefaultDevice()!
let commandQueue = device.newCommandQueue()

var metalLayer : CAMetalLayer! = nil

var pipelineSimple : MTLRenderPipelineState! = nil
var pipelineTexture : MTLRenderPipelineState! = nil
var sampleTex : MTLTexture! = nil
var displayLink : CVDisplayLink? = nil

let gameCodeLibPath : String = ({
    let appPath = NSBundle.mainBundle().bundlePath
    let components = appPath.characters.split("/")
    let head = components.dropLast(1).map(String.init).joinWithSeparator("/")
    return "/" + head + "/\(gameCodeLibName).dylib"
})()

typealias updateAndRenderSignature = @convention(c) (Ptr, Ptr, Ptr) -> ()

typealias dylibHandle = Ptr
var gameCode : dylibHandle = nil
var lastModTime : NSDate! = nil
var updateAndRender : ((Ptr, Ptr, Ptr) -> ())! = nil

extension Int {
    var kilobytes : Int {
        return self * 1024
    }
    var megabytes : Int {
        return self * 1024 * 1024
    }
    var gigabytes : Int {
        return self * 1024 * 1024 * 1024
    }
}

var gameMemory = GameMemory()

func beginRendering(hostLayer: CALayer) {
    
    metalLayer = CAMetalLayer()
    metalLayer.device = device
    metalLayer.pixelFormat = .BGRA8Unorm
    metalLayer.framebufferOnly = true
    metalLayer.frame = hostLayer.frame
    
    hostLayer.addSublayer(metalLayer)
    
    let library = device.newDefaultLibrary()!
    let vertexShader = library.newFunctionWithName("tile_vertex_shader")
    let fragmentShader = library.newFunctionWithName("tile_fragment_shader")
    
    let pipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.vertexFunction = vertexShader
    pipelineDescriptor.fragmentFunction = fragmentShader
    pipelineDescriptor.colorAttachments[0].pixelFormat = .BGRA8Unorm
    pipelineDescriptor.colorAttachments[0].blendingEnabled = true
    pipelineDescriptor.sampleCount = 4
    
//    // Set up multisampling for antialiasing
    let multisampleTexDesc = MTLTextureDescriptor()
    multisampleTexDesc.textureType = MTLTextureType.Type2DMultisample
    multisampleTexDesc.width = Int(metalLayer.bounds.size.width)
    multisampleTexDesc.height = Int(metalLayer.bounds.size.height)
    multisampleTexDesc.sampleCount = 4
    multisampleTexDesc.pixelFormat = .BGRA8Unorm
    multisampleTexDesc.storageMode = .Private
    multisampleTexDesc.usage = .RenderTarget
    
    sampleTex = device.newTextureWithDescriptor(multisampleTexDesc)
    
    pipelineSimple = try! device.newRenderPipelineStateWithDescriptor(pipelineDescriptor)
    
    // Textured
    let vertexTextureShader = library.newFunctionWithName("basic_transform_vertex_shader")
    let fragmentTextureShader = library.newFunctionWithName("textured_shader")
    
    let pipelineTextureDescriptor = MTLRenderPipelineDescriptor()
    pipelineTextureDescriptor.vertexFunction = vertexTextureShader
    pipelineTextureDescriptor.fragmentFunction = fragmentTextureShader
    pipelineTextureDescriptor.colorAttachments[0].pixelFormat = .BGRA8Unorm
    pipelineTextureDescriptor.colorAttachments[0].blendingEnabled = true
    pipelineTextureDescriptor.colorAttachments[0].rgbBlendOperation = .Add
    pipelineTextureDescriptor.colorAttachments[0].alphaBlendOperation = .Add
    pipelineTextureDescriptor.colorAttachments[0].sourceRGBBlendFactor = .SourceAlpha
    pipelineTextureDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .SourceAlpha
    pipelineTextureDescriptor.colorAttachments[0].destinationRGBBlendFactor = .OneMinusSourceAlpha
    pipelineTextureDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .OneMinusSourceAlpha
    pipelineTextureDescriptor.sampleCount = 4
    
    pipelineTexture = try! device.newRenderPipelineStateWithDescriptor(pipelineTextureDescriptor)
    
    try! getLastWriteTime(gameCodeLibPath)
    loadGameCode()
    
    let bigAddress = Ptr(bitPattern: 8.gigabytes)
    let permanentStorageSize = 256.megabytes
    let transientStorageSize = 2.gigabytes
    let totalSize = permanentStorageSize + transientStorageSize
    
    // TODO: Is this memory *guaranteed* to be cleared to zero?
    //       Linux docs suggest yes, Darwin docs doesn't specify
    //       Empirically seems to be true
    gameMemory.permanent = mmap(bigAddress, totalSize, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_FIXED|MAP_ANON, -1, 0)
    gameMemory.transient = gameMemory.permanent + permanentStorageSize
    
//    var p = UnsafeMutablePointer<GameState>(gameMemory.permanent)
//    p[0] = GameState()
    
    let displayId = CGMainDisplayID()
    CVDisplayLinkCreateWithCGDisplay(displayId, &displayLink)
    CVDisplayLinkSetOutputCallback(displayLink!, drawFrame, nil)
    CVDisplayLinkStart(displayLink!)
}

func loadGameCode() {
    gameCode = dlopen(gameCodeLibPath, RTLD_LAZY|RTLD_GLOBAL)
    let updateAndRenderSym = dlsym(gameCode, updateAndRenderSymbolName)
    updateAndRender = unsafeBitCast(updateAndRenderSym, updateAndRenderSignature.self)
    lastModTime = try! getLastWriteTime(gameCodeLibPath)
}

func unloadGameCode() {
    updateAndRender = nil
    dlclose(gameCode)
    dlclose(gameCode) // THIS IS AWFUL. But the ObjC runtime opens all opened dylibs
                      // so you *have* to unload twice in order to get the reference count down to 0
    gameCode = nil
}

func getLastWriteTime(filePath : String) throws -> NSDate {
    let attrs = try NSFileManager.defaultManager().attributesOfItemAtPath(filePath)
    return attrs[NSFileModificationDate] as! NSDate
}

var lastFrameTime : Int64! = nil

func drawFrame(displayLink: CVDisplayLink,
               _ inNow: UnsafePointer<CVTimeStamp>,
                 _ inOutputTime:  UnsafePointer<CVTimeStamp>,
                   _ flagsIn: CVOptionFlags,
                     _ flagsOut: UnsafeMutablePointer<CVOptionFlags>,
                       _ displayLinkContext: UnsafeMutablePointer<Void>) -> CVReturn {
    autoreleasepool {
        do {
            let gameCodeWriteTime = try getLastWriteTime(gameCodeLibPath)
            if gameCodeWriteTime.compare(lastModTime!) == .OrderedDescending {
                unloadGameCode()
                loadGameCode()
                print("Game code reloaded")
            }
        } catch {
            print("Missed game code live reload")
        } // Eat the error on purpose. If we can't reload this frame, we can try again next frame.
        
        let nextFrame = inOutputTime.memory
        
        var dt : Double = Double(nextFrame.videoRefreshPeriod) / Double(nextFrame.videoTimeScale)
        if lastFrameTime != nil {
            dt = Double(nextFrame.videoTime - lastFrameTime) / Double(nextFrame.videoTimeScale)
        }
        
        var gamepadInputs  = GamepadInputs()
        var keyboardInputs = KeyboardInputs()
        
        // Get Inputs
        if gamepad != nil {
            
            for (i, button) in gamepadElements.buttons.enumerate() {
                if button != nil {
                    var value : Unmanaged<IOHIDValue>?
                    IOHIDDeviceGetValue(gamepad, button, &value)
                    if IOHIDValueGetIntegerValue(value!.takeUnretainedValue()) != 0 {
                        gamepadInputs.buttons[i] = true
                    }
                }
            }
            
            

            let deadzoneThreshold : Float = 0.06
            
            if gamepadElements.x != nil {
                let min = IOHIDElementGetLogicalMin(gamepadElements.x)
                let max = IOHIDElementGetLogicalMax(gamepadElements.x)
                var value : Unmanaged<IOHIDValue>?
                IOHIDDeviceGetValue(gamepad, gamepadElements.x, &value)
                let val = IOHIDValueGetIntegerValue(value!.takeUnretainedValue())
                let numerator = Float(val - min)
                let denominator = Float(max - min)
                let scaledValue = (( numerator / denominator ) * 2.0) - 1.0;
                if (fabs(scaledValue) > deadzoneThreshold) {
                    gamepadInputs.x = scaledValue
                }
                else {
                    gamepadInputs.x = 0.0
                }
            }
            
            if gamepadElements.y != nil {
                let min = IOHIDElementGetLogicalMin(gamepadElements.y)
                let max = IOHIDElementGetLogicalMax(gamepadElements.y)
                var value : Unmanaged<IOHIDValue>?
                IOHIDDeviceGetValue(gamepad, gamepadElements.y, &value)
                let val = IOHIDValueGetIntegerValue(value!.takeUnretainedValue())
                let numerator = Float(val - min)
                let denominator = Float(max - min)
                let scaledValue = (( numerator / denominator ) * 2.0) - 1.0;
                if (fabs(scaledValue) > deadzoneThreshold) {
                    gamepadInputs.y = scaledValue
                }
                else {
                    gamepadInputs.y = 0.0
                }
            }
            
        }
        
        if keyboard != nil && NSApp.active {
            if keyboardElements.leftArrow != nil {
                var value : Unmanaged<IOHIDValue>?
                IOHIDDeviceGetValue(keyboard, keyboardElements.leftArrow, &value)
                if IOHIDValueGetIntegerValue(value!.takeUnretainedValue()) != 0 {
                    keyboardInputs.leftArrow = true
                }
            }
            if keyboardElements.rightArrow != nil {
                var value : Unmanaged<IOHIDValue>?
                IOHIDDeviceGetValue(keyboard, keyboardElements.rightArrow, &value)
                if IOHIDValueGetIntegerValue(value!.takeUnretainedValue()) != 0 {
                    keyboardInputs.rightArrow = true
                }
            }
            if keyboardElements.upArrow != nil {
                var value : Unmanaged<IOHIDValue>?
                IOHIDDeviceGetValue(keyboard, keyboardElements.upArrow, &value)
                if IOHIDValueGetIntegerValue(value!.takeUnretainedValue()) != 0 {
                    keyboardInputs.upArrow = true
                }
            }
            if keyboardElements.spacebar != nil {
                var value : Unmanaged<IOHIDValue>?
                IOHIDDeviceGetValue(keyboard, keyboardElements.spacebar, &value)
                if IOHIDValueGetIntegerValue(value!.takeUnretainedValue()) != 0 {
                    keyboardInputs.spacebar = true
                }
            }
        }
        
        // Resolve Inputs
        var inputs = Inputs()
        inputs.dt = Float(dt)
        if keyboard != nil {
            if keyboardInputs.leftArrow && !keyboardInputs.rightArrow {
                inputs.rotate = -1.0
            }
            else if keyboardInputs.rightArrow && !keyboardInputs.leftArrow {
                inputs.rotate = 1.0
            }
            
            if keyboardInputs.upArrow {
                inputs.thrust = true
            }
            
            if keyboardInputs.spacebar {
                inputs.fire = true
            }
        }
        
        // Gamepad wins out over keyboard
        if gamepad != nil {
            inputs.rotate = gamepadInputs.x
            inputs.thrust = gamepadInputs.buttons[1]
            inputs.fire = gamepadInputs.buttons[0]
            
            inputs.restart = gamepadInputs.buttons[9]
        }
        
        var renderCommands : RenderCommandBuffer = RenderCommandBuffer()
        
        updateAndRender(&gameMemory, &inputs, &renderCommands)
        
        render(renderCommands)
        
        lastFrameTime = nextFrame.videoTime
    }
    
    return kCVReturnSuccess
}

func render(renderCommandBuffer : RenderCommandBuffer) {
    
    let commandBuffer = commandQueue.commandBuffer()
    
    let drawable = metalLayer.nextDrawable()!
    
    let renderPassDescriptor = MTLRenderPassDescriptor()
    renderPassDescriptor.colorAttachments[0].texture = sampleTex
    renderPassDescriptor.colorAttachments[0].resolveTexture = drawable.texture
    renderPassDescriptor.colorAttachments[0].loadAction = .Clear
    renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
    renderPassDescriptor.colorAttachments[0].storeAction = .MultisampleResolve
    
    
    let renderEncoder = commandBuffer.renderCommandEncoderWithDescriptor(renderPassDescriptor)
    
    var worldTransform = float4x4(1)
    var uniformsBuffer = device.newBufferWithBytes(&worldTransform, length: 16 * sizeof(Float), options: [])
    
    for command in renderCommandBuffer.commands {
        
        // Swift type system/module namespacing stupidness
        // means we have to directly cast the memory.
        // Also, this just doesn't work if RenderCommands
        // are structs and not classes. Weird value vs.
        // reference semantics??
        
        if command.type == .Options {
            let optionsCommand : RenderCommandOptions = coldCast(command)
            if optionsCommand.fillMode == .Fill {
                renderEncoder.setTriangleFillMode(.Fill)
            }
            else {
                renderEncoder.setTriangleFillMode(.Lines)
            }
        }
        else if command.type == .Uniforms {
            let uniformsCommand : RenderCommandUniforms = coldCast(command)
            renderEncoder.setRenderPipelineState(pipelineSimple)
            
            worldTransform = uniformsCommand.transform
            uniformsBuffer = device.newBufferWithBytes(&worldTransform, length: 16 * sizeof(Float), options: [])
        }
        else if command.type == .Triangles {
            let trianglesCommand : RenderCommandTriangles = coldCast(command)
            renderEncoder.setRenderPipelineState(pipelineSimple)
            
            var instanceTransform = trianglesCommand.transform
            let instanceUniformsBuffer = device.newBufferWithBytes(&instanceTransform, length: 16 * sizeof(Float), options: [])
            let vertexBuffer = device.newBufferWithBytes(trianglesCommand.verts, length: trianglesCommand.count * sizeof(Float), options: [])
            renderEncoder.setVertexBuffer(uniformsBuffer, offset: 0, atIndex: 0)
            renderEncoder.setVertexBuffer(instanceUniformsBuffer, offset: 0, atIndex: 1)
            renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, atIndex: 2)
            renderEncoder.drawPrimitives(.Triangle, vertexStart: 0, vertexCount: trianglesCommand.count / 8)
        }
        else if command.type == .Text {
            let textCommand : RenderCommandText = coldCast(command)
            renderEncoder.setRenderPipelineState(pipelineTexture)
            
            var instanceTransform = textCommand.transform
            let instanceUniformsBuffer = device.newBufferWithBytes(&instanceTransform, length: 16 * sizeof(Float), options: [])
            let vertexBuffer = device.newBufferWithBytes(textCommand.quads, length: textCommand.quadCount * 4 * 8 * sizeof(Float), options: [])
            renderEncoder.setVertexBuffer(instanceUniformsBuffer, offset: 0, atIndex: 0)
            renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, atIndex: 1)
            
            let indexBuffer = device.newBufferWithBytes(textCommand.indices, length: (textCommand.quadCount * 6) * sizeof(Float), options:[])
            
            let textureDesc = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(.BGRA8Unorm, width: textCommand.width, height: textCommand.height, mipmapped: false)
            let texture = device.newTextureWithDescriptor(textureDesc)
            texture.replaceRegion(MTLRegionMake2D(0, 0, textCommand.width, textCommand.height), mipmapLevel: 0, slice: 0, withBytes: textCommand.texels, bytesPerRow: 4 * textCommand.width, bytesPerImage: 4 * textCommand.width * textCommand.height)
            renderEncoder.setFragmentTexture(texture, atIndex: 0)
            renderEncoder.drawIndexedPrimitives(.Triangle, indexCount: (textCommand.quadCount * 6), indexType: .UInt16, indexBuffer: indexBuffer, indexBufferOffset: 0)
        }
        
    }
    
    
    renderEncoder.endEncoding()
    
    commandBuffer.presentDrawable(drawable)
    commandBuffer.commit()
    
}

