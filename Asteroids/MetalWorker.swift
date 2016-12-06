import Cocoa
import Metal
import QuartzCore
import CoreVideo
import simd
import IOKit
import IOKit.hid

let device = MTLCreateSystemDefaultDevice()!
let commandQueue = device.newCommandQueue()

var metalLayer : CAMetalLayer! = nil

var pipeline : MTLRenderPipelineState! = nil
var displayLink : CVDisplayLink? = nil

let libAsteroidsPath : String = ({
    let appPath = NSBundle.mainBundle().bundlePath
    let components = appPath.characters.split("/")
    let head = components.dropLast(1).map(String.init).joinWithSeparator("/")
    print(head)
    return "/" + head + "/libAsteroids.dylib"
})()

typealias updateAndRenderSignature = @convention(c) (Double, UnsafeMutablePointer<Void>, UnsafeMutablePointer<Void>) -> ()

typealias dylibHandle = UnsafeMutablePointer<Void>
var libAsteroids : dylibHandle = nil
var lastModTime : NSDate! = nil
var updateAndRender : ((Double, UnsafeMutablePointer<Void>, UnsafeMutablePointer<Void>) -> ())! = nil

let MAX_VERTICES = 0xFFFF // 65535
//var renderMemory : UnsafeMutablePointer<Void> = nil

// Inputs

struct ControllerElements {
    var x : IOHIDElementRef! = nil
    var y : IOHIDElementRef! = nil
    var z : IOHIDElementRef! = nil
    var rx : IOHIDElementRef! = nil
    var ry : IOHIDElementRef! = nil
    var rz : IOHIDElementRef! = nil
    var hat : IOHIDElementRef! = nil
    var buttons : [IOHIDElementRef!]! = nil
    
    init() {
        buttons = [IOHIDElementRef!](count: 16, repeatedValue: nil)
    }
}

var hidManager : IOHIDManager! = nil
var gamepad : IOHIDDeviceRef! = nil
var gamepadElements : ControllerElements! = nil

func inputSystemInit() {
    
    let manager = IOHIDManagerCreate(kCFAllocatorDefault, UInt32(kIOHIDOptionsTypeNone))
    let gamepadDictionary = [
        kIOHIDDeviceUsagePageKey : kHIDPage_GenericDesktop,
        kIOHIDDeviceUsageKey     : kHIDUsage_GD_GamePad,
    ]
    let joystickDictionary = [
        kIOHIDDeviceUsagePageKey : kHIDPage_GenericDesktop,
        kIOHIDDeviceUsageKey     : kHIDUsage_GD_Joystick,
    ]
    
    let matchingDictionaries = [gamepadDictionary, joystickDictionary]
    IOHIDManagerSetDeviceMatchingMultiple(manager.takeUnretainedValue(), matchingDictionaries)
    IOHIDManagerRegisterDeviceMatchingCallback(manager.takeUnretainedValue(), deviceAdded, nil)
    IOHIDManagerRegisterDeviceRemovalCallback(manager.takeUnretainedValue(), deviceRemoved, nil)
    IOHIDManagerScheduleWithRunLoop(manager.takeUnretainedValue(), CFRunLoopGetCurrent(), kCFRunLoopDefaultMode)
    IOHIDManagerOpen(manager.takeUnretainedValue(), UInt32(kIOHIDOptionsTypeNone))
    
    hidManager = manager.takeUnretainedValue()
}

func deviceAdded(inContext: UnsafeMutablePointer<Void>, inResult: IOReturn, inSender: UnsafeMutablePointer<Void>, inIOHIDDeviceRef: IOHIDDevice!) {
    print("device added!")
    
    if gamepad == nil {
        gamepad = inIOHIDDeviceRef
        
        var controllerEls = ControllerElements()
        
        let buttons = [kIOHIDElementUsagePageKey : kHIDPage_Button]
        let buttonElements = IOHIDDeviceCopyMatchingElements(inIOHIDDeviceRef, buttons, UInt32(kIOHIDOptionsTypeNone))
        
        for buttonRef in buttonElements.takeUnretainedValue() as Array {
            let button = buttonRef as! IOHIDElement 
            let usage = IOHIDElementGetUsage(button)
            if usage < 16 {
                let idx = usage - 1
                controllerEls.buttons![Int(idx)] = button
            }
        }
        
        let genericDesktop = [kIOHIDElementUsagePageKey : kHIDPage_GenericDesktop]
        let genericDesktopElements = IOHIDDeviceCopyMatchingElements(inIOHIDDeviceRef, genericDesktop, UInt32(kIOHIDOptionsTypeNone))
        
        for gdElementRef in genericDesktopElements.takeUnretainedValue() as Array {
            let gdElement = gdElementRef as! IOHIDElement
            let usage = IOHIDElementGetUsage(gdElement)
            
            if (usage == UInt32(kHIDUsage_GD_X)) {
                controllerEls.x = gdElement
            }
            else if (usage == UInt32(kHIDUsage_GD_Y)) {
                controllerEls.y = gdElement
            }
            else if (usage == UInt32(kHIDUsage_GD_Z)) {
                controllerEls.z = gdElement
            }
            else if (usage == UInt32(kHIDUsage_GD_Rx)) {
                controllerEls.rx = gdElement
            }
            else if (usage == UInt32(kHIDUsage_GD_Ry)) {
                controllerEls.ry = gdElement
            }
            else if (usage == UInt32(kHIDUsage_GD_Rz)) {
                controllerEls.rz = gdElement
            }
            else if (usage == UInt32(kHIDUsage_GD_Hatswitch)) {
                controllerEls.hat = gdElement
            }
        }
        
        gamepadElements = controllerEls
        
    }
}

func deviceRemoved(inContext: UnsafeMutablePointer<Void>, inResult: IOReturn, inSender: UnsafeMutablePointer<Void>, inIOHIDDeviceRef: IOHIDDevice!) {
    
    print("device removed!")
    
    if unsafeAddressOf(inIOHIDDeviceRef) == unsafeAddressOf(gamepad) {
        gamepad = nil
        gamepadElements = nil
    }
}

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
    
    pipeline = try! device.newRenderPipelineStateWithDescriptor(pipelineDescriptor)
    
    try! getLastWriteTime(libAsteroidsPath)
    loadLibAsteroids()
    
//    renderMemory = malloc(MAX_VERTICES * 8 * sizeof(Float))
    
    let displayId = CGMainDisplayID()
    CVDisplayLinkCreateWithCGDisplay(displayId, &displayLink)
    CVDisplayLinkSetOutputCallback(displayLink!, drawFrame, nil)
    CVDisplayLinkStart(displayLink!)
}

func loadLibAsteroids() {
    libAsteroids = dlopen(libAsteroidsPath, RTLD_LAZY|RTLD_GLOBAL)
    let updateAndRenderSym = dlsym(libAsteroids, "_TF12libAsteroids15updateAndRenderFTSd13gamepadInputsGSpVS_13GamepadInputs_14renderCommandsGSpCS_19RenderCommandBuffer__T_")
    updateAndRender = unsafeBitCast(updateAndRenderSym, updateAndRenderSignature.self)
    lastModTime = try! getLastWriteTime(libAsteroidsPath)
}

func unloadLibAsteroids() {
    updateAndRender = nil
    dlclose(libAsteroids)
    dlclose(libAsteroids) // THIS IS AWFUL. But the ObjC runtime opens all opened dylibs
                         // so you *have* to unload twice in order to get the reference count down to 0
    libAsteroids = nil
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
            let libAsteroidsWriteTime = try getLastWriteTime(libAsteroidsPath)
            if libAsteroidsWriteTime.compare(lastModTime!) == .OrderedDescending {
                unloadLibAsteroids()
                loadLibAsteroids()
                print("libAsteroids reloaded")
            }
        } catch {
            print("Missed libAsteroids live reload")
        } // Eat the error on purpose. If we can't reload this frame, we can try again next frame.
        
        let nextFrame = inOutputTime.memory
        
        var dt : Double = Double(nextFrame.videoRefreshPeriod) / Double(nextFrame.videoTimeScale)
        if lastFrameTime != nil {
            dt = Double(nextFrame.videoTime - lastFrameTime) / Double(nextFrame.videoTimeScale)
        }
        
        var gamepadInputs = GamepadInputs()
        
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
        
        var renderCommands : RenderCommandBuffer = RenderCommandBuffer()
        
        updateAndRender(dt, &gamepadInputs, &renderCommands)
        
        render(renderCommands)
        
        lastFrameTime = nextFrame.videoTime
    }
    
    return kCVReturnSuccess
}

func render(renderCommandBuffer : RenderCommandBuffer) {
    
    let commandBuffer = commandQueue.commandBuffer()
    
    let drawable = metalLayer.nextDrawable()!
    
    let renderPassDescriptor = MTLRenderPassDescriptor()
    renderPassDescriptor.colorAttachments[0].texture = drawable.texture
    renderPassDescriptor.colorAttachments[0].loadAction = .Clear
    renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
    
    let renderEncoder = commandBuffer.renderCommandEncoderWithDescriptor(renderPassDescriptor)
    renderEncoder.setRenderPipelineState(pipeline)
    
    var worldTransform = float4x4(1)
    var uniformsBuffer = device.newBufferWithBytes(&worldTransform, length: 16 * sizeof(Float), options: [])
    
    for command in renderCommandBuffer.commands {
        
        if command.type == .Uniforms {
            worldTransform = command.transform
            uniformsBuffer = device.newBufferWithBytes(&worldTransform, length: 16 * sizeof(Float), options: [])
        }
        else if command.type == .Triangles {
            var instanceTransform = command.transform
            let instanceUniformsBuffer = device.newBufferWithBytes(&instanceTransform, length: 16 * sizeof(Float), options: [])
            let vertexBuffer = device.newBufferWithBytes(command.verts, length: command.count * sizeof(Float), options: [])
            renderEncoder.setVertexBuffer(uniformsBuffer, offset: 0, atIndex: 0)
            renderEncoder.setVertexBuffer(instanceUniformsBuffer, offset: 0, atIndex: 1)
            renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, atIndex: 2)
            renderEncoder.drawPrimitives(.Triangle, vertexStart: 0, vertexCount: command.count / 8)
        }
        
    }
    
    
    renderEncoder.endEncoding()
    
    commandBuffer.presentDrawable(drawable)
    commandBuffer.commit()
    
}

