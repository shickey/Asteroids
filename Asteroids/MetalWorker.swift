import Cocoa
import Metal
import QuartzCore
import CoreVideo
import simd
import IOKit
import IOKit.hid

let gameCodeLibName = "libAsteroids"
let updateAndRenderSymbolName = "_TF12libAsteroids15updateAndRenderFTGSpCS_10GameMemory_9inputsPtrGSpCS_6Inputs_22renderCommandHeaderPtrGSpVS_25RenderCommandBufferHeader__T_"

let device = MTLCreateSystemDefaultDevice()!
let commandQueue = device.makeCommandQueue()

var metalLayer : CAMetalLayer! = nil

var pipelineSimple : MTLRenderPipelineState! = nil
var pipelineTexture : MTLRenderPipelineState! = nil
var sampleTex : MTLTexture! = nil
var displayLink : CVDisplayLink? = nil

let gameCodeLibPath : String = ({
    let appPath = Bundle.main.bundlePath
    let components = appPath.characters.split(separator: "/")
    let head = components.dropLast(1).map(String.init).joined(separator: "/")
    return "/" + head + "/\(gameCodeLibName).dylib"
})()

typealias updateAndRenderSignature = @convention(c) (RawPtr, RawPtr, RawPtr) -> ()

typealias dylibHandle = RawPtr
var gameCode : dylibHandle? = nil
var lastModTime : Date! = nil
var updateAndRender : ((RawPtr, RawPtr, RawPtr) -> ())! = nil

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
var renderCommandBufferBase : RawPtr! = nil

func beginRendering(_ hostLayer: CALayer) {
    
    metalLayer = CAMetalLayer()
    metalLayer.device = device
    metalLayer.pixelFormat = .bgra8Unorm
    metalLayer.framebufferOnly = true
    metalLayer.frame = hostLayer.frame
    
    hostLayer.addSublayer(metalLayer)
    
    let library = device.newDefaultLibrary()!
    let vertexShader = library.makeFunction(name: "tile_vertex_shader")
    let fragmentShader = library.makeFunction(name: "tile_fragment_shader")
    
    let pipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.vertexFunction = vertexShader
    pipelineDescriptor.fragmentFunction = fragmentShader
    pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
    pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
    pipelineDescriptor.sampleCount = 4
    
    // Set up multisampling for antialiasing
    let multisampleTexDesc = MTLTextureDescriptor()
    multisampleTexDesc.textureType = MTLTextureType.type2DMultisample
    multisampleTexDesc.width = Int(metalLayer.bounds.size.width)
    multisampleTexDesc.height = Int(metalLayer.bounds.size.height)
    multisampleTexDesc.sampleCount = 4
    multisampleTexDesc.pixelFormat = .bgra8Unorm
    multisampleTexDesc.storageMode = .private
    multisampleTexDesc.usage = .renderTarget
    
    sampleTex = device.makeTexture(descriptor: multisampleTexDesc)
    
    pipelineSimple = try! device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    
    // Textured
    let vertexTextureShader = library.makeFunction(name: "basic_transform_vertex_shader")
    let fragmentTextureShader = library.makeFunction(name: "textured_shader")
    
    let pipelineTextureDescriptor = MTLRenderPipelineDescriptor()
    pipelineTextureDescriptor.vertexFunction = vertexTextureShader
    pipelineTextureDescriptor.fragmentFunction = fragmentTextureShader
    pipelineTextureDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
    pipelineTextureDescriptor.colorAttachments[0].isBlendingEnabled = true
    pipelineTextureDescriptor.colorAttachments[0].rgbBlendOperation = .add
    pipelineTextureDescriptor.colorAttachments[0].alphaBlendOperation = .add
    pipelineTextureDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
    pipelineTextureDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
    pipelineTextureDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
    pipelineTextureDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
    pipelineTextureDescriptor.sampleCount = 4
    
    pipelineTexture = try! device.makeRenderPipelineState(descriptor: pipelineTextureDescriptor)
    
    loadGameCode()
    
    let bigAddress = RawPtr(bitPattern: 8.gigabytes)
    let permanentStorageSize = 256.megabytes
    let transientStorageSize = 2.gigabytes
    let commandBufferSize = 256.megabytes
    let totalSize = permanentStorageSize + transientStorageSize + commandBufferSize
    
    // TODO: Is this memory *guaranteed* to be cleared to zero?
    //       Linux docs suggest yes, Darwin docs doesn't specify
    //       Empirically seems to be true
    gameMemory.permanent = mmap(bigAddress, totalSize, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_FIXED|MAP_ANON, -1, 0)
    gameMemory.transient = gameMemory.permanent + permanentStorageSize
    renderCommandBufferBase = gameMemory.transient + transientStorageSize
    
    
    let displayId = CGMainDisplayID()
    CVDisplayLinkCreateWithCGDisplay(displayId, &displayLink)
    CVDisplayLinkSetOutputCallback(displayLink!, drawFrame, nil)
    CVDisplayLinkStart(displayLink!)
}

func loadGameCode() {
    gameCode = dlopen(gameCodeLibPath, RTLD_LAZY|RTLD_GLOBAL)
    let updateAndRenderSym = dlsym(gameCode, updateAndRenderSymbolName)
    updateAndRender = unsafeBitCast(updateAndRenderSym, to: updateAndRenderSignature.self)
    lastModTime = try! getLastWriteTime(gameCodeLibPath)
}

func unloadGameCode() {
    updateAndRender = nil
    dlclose(gameCode)
    dlclose(gameCode) // THIS IS AWFUL. But the ObjC runtime opens all opened dylibs
                      // so you *have* to unload twice in order to get the reference count down to 0
    gameCode = nil
}

func getLastWriteTime(_ filePath : String) throws -> Date {
    let attrs = try FileManager.default.attributesOfItem(atPath: filePath)
    return attrs[FileAttributeKey.modificationDate] as! Date
}

var lastFrameTime : Int64! = nil

func drawFrame(_ displayLink: CVDisplayLink,
               _ inNow: UnsafePointer<CVTimeStamp>,
                 _ inOutputTime:  UnsafePointer<CVTimeStamp>,
                   _ flagsIn: CVOptionFlags,
                     _ flagsOut: UnsafeMutablePointer<CVOptionFlags>,
                       _ displayLinkContext: UnsafeMutableRawPointer?) -> CVReturn {
    autoreleasepool {
        do {
            let gameCodeWriteTime = try getLastWriteTime(gameCodeLibPath)
            if gameCodeWriteTime.compare(lastModTime!) == .orderedDescending {
                unloadGameCode()
                loadGameCode()
                print("Game code reloaded")
            }
        } catch {
            print("Missed game code live reload")
        } // Eat the error on purpose. If we can't reload this frame, we can try again next frame.
        
        let nextFrame = inOutputTime.pointee
        
        var dt : Float = Float(nextFrame.videoRefreshPeriod) / Float(nextFrame.videoTimeScale)
        if lastFrameTime != nil {
            dt = Float(nextFrame.videoTime - lastFrameTime) / Float(nextFrame.videoTimeScale)
        }
        
        var inputs = Inputs()
        inputs.dt = dt
        
        let controllers = readControllers()
        
        // Gamepads win out over keyboards
        if controllers.gamepads.count > 0 {
            let gamepad = controllers.gamepads[0]
            inputs.rotate = gamepad.x
            inputs.thrust = gamepad.buttons[1]
            inputs.fire = gamepad.buttons[0]
            
            inputs.restart = gamepad.buttons[9]
        }
        else if controllers.keyboards.count > 0 && NSApp.isActive {
            var rotate : Float = 0.0
            var thrust = false
            var fire = false
            
            // Try to combine keyboard input as much as possible
            for keyboard in controllers.keyboards {
                if keyboard.leftArrow && !keyboard.rightArrow {
                    rotate += -1.0
                }
                else if keyboard.rightArrow && !keyboard.leftArrow {
                    rotate += 1.0
                }
                
                if keyboard.upArrow {
                    thrust = true
                }
                
                if keyboard.spacebar {
                    fire = true
                }
            }
            
            rotate = clamp(rotate, -1.0, 1.0)
            
            inputs.rotate = rotate
            inputs.thrust = thrust
            inputs.fire = fire
        }
        
        // Clear the buffer by reseting the count
        let header = RenderCommandBufferHeader()
        renderCommandBufferBase.storeBytes(of: header, as: RenderCommandBufferHeader.self)
        
        updateAndRender(&gameMemory, &inputs, renderCommandBufferBase)
        
        render()
        
        lastFrameTime = nextFrame.videoTime
    }
    
    return kCVReturnSuccess
}

func render() {
    
    let commandBuffer = commandQueue.makeCommandBuffer()
    
    let drawable = metalLayer.nextDrawable()!
    
    let renderPassDescriptor = MTLRenderPassDescriptor()
    renderPassDescriptor.colorAttachments[0].texture = sampleTex
    renderPassDescriptor.colorAttachments[0].resolveTexture = drawable.texture
    renderPassDescriptor.colorAttachments[0].loadAction = .clear
    renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
    renderPassDescriptor.colorAttachments[0].storeAction = .multisampleResolve
    
    
    let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
    
    var worldTransform = float4x4(1)
    var uniformsBuffer = device.makeBuffer(bytes: &worldTransform, length: 16 * MemoryLayout<Float>.size, options: [])
    
    let headerPtr = renderCommandBufferBase.bindMemory(to: RenderCommandBufferHeader.self, capacity: 1)
    let header = headerPtr.pointee
    
    var commandPtr : RawPtr = header.firstCommandBase!
    
    for i in 0..<header.commandCount {
        
        let command = commandPtr.bindMemory(to: RenderCommandHeader.self, capacity: 1).pointee
        
        // Swift type system/module namespacing stupidness
        // means we have to directly cast the memory.
        // Also, this just doesn't work if RenderCommands
        // are structs and not classes. Weird value vs.
        // reference semantics??
        
        if command.type == .options {
            let optionsCommand = commandPtr.bindMemory(to: RenderCommandOptions.self, capacity: 1).pointee
            if optionsCommand.fillMode == .fill {
                renderEncoder.setTriangleFillMode(.fill)
            }
            else {
                renderEncoder.setTriangleFillMode(.lines)
            }
        }
        else if command.type == .uniforms {
            let uniformsCommand = commandPtr.bindMemory(to: RenderCommandUniforms.self, capacity: 1).pointee
            renderEncoder.setRenderPipelineState(pipelineSimple)
            
            worldTransform = uniformsCommand.transform
            uniformsBuffer = device.makeBuffer(bytes: &worldTransform, length: 16 * MemoryLayout<Float>.size, options: [])
        }
        else if command.type == .triangles {
            let trianglesCommand = commandPtr.bindMemory(to: RenderCommandTriangles.self, capacity: 1).pointee
            renderEncoder.setRenderPipelineState(pipelineSimple)
            
            var instanceTransform = trianglesCommand.transform
            let instanceUniformsBuffer = device.makeBuffer(bytes: &instanceTransform, length: 16 * MemoryLayout<Float>.size, options: [])
            let vertexBuffer = device.makeBuffer(bytes: trianglesCommand.verts, length: trianglesCommand.count * MemoryLayout<Float>.size, options: [])
            renderEncoder.setVertexBuffer(uniformsBuffer, offset: 0, at: 0)
            renderEncoder.setVertexBuffer(instanceUniformsBuffer, offset: 0, at: 1)
            renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, at: 2)
            renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: trianglesCommand.count / 8)
        }
        else if command.type == .text {
            let textCommand = commandPtr.bindMemory(to: RenderCommandText.self, capacity: 1).pointee
            renderEncoder.setRenderPipelineState(pipelineTexture)
            
            var instanceTransform = textCommand.transform
            let instanceUniformsBuffer = device.makeBuffer(bytes: &instanceTransform, length: 16 * MemoryLayout<Float>.size, options: [])
            let vertexBuffer = device.makeBuffer(bytes: textCommand.quads, length: textCommand.quadCount * 4 * 8 * MemoryLayout<Float>.size, options: [])
            renderEncoder.setVertexBuffer(instanceUniformsBuffer, offset: 0, at: 0)
            renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, at: 1)
            
            let indexBuffer = device.makeBuffer(bytes: textCommand.indices, length: (textCommand.quadCount * 6) * MemoryLayout<Float>.size, options:[])
            
            let textureDesc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm, width: textCommand.width, height: textCommand.height, mipmapped: false)
            let texture = device.makeTexture(descriptor: textureDesc)
            texture.replace(region: MTLRegionMake2D(0, 0, textCommand.width, textCommand.height), mipmapLevel: 0, slice: 0, withBytes: textCommand.texels, bytesPerRow: 4 * textCommand.width, bytesPerImage: 4 * textCommand.width * textCommand.height)
            renderEncoder.setFragmentTexture(texture, at: 0)
            renderEncoder.drawIndexedPrimitives(type: .triangle, indexCount: (textCommand.quadCount * 6), indexType: .uint16, indexBuffer: indexBuffer, indexBufferOffset: 0)
        }
        
        if let nextCommandPtr = command.next {
            commandPtr = nextCommandPtr
        }
        
    }
    
    
    renderEncoder.endEncoding()
    
    commandBuffer.present(drawable)
    commandBuffer.commit()
    
}

