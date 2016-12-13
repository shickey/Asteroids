//
//  Input.swift
//  Asteroids
//
//  Created by Sean Hickey on 12/7/16.
//  Copyright © 2016 Sean Hickey. All rights reserved.
//

import IOKit
import IOKit.hid

var hidManager : IOHIDManager! = nil

let MAX_CONTROLLERS = 4
var controllers = Controllers()


class Controllers {
    var gamepads = [Gamepad?](repeating: nil, count: MAX_CONTROLLERS)
    var keyboards = [Keyboard?](repeating: nil, count: MAX_CONTROLLERS)
}

class ControllerValues {
    var gamepads : [GamepadValues] = []
    var keyboards : [KeyboardValues] = []
}

class Gamepad {
    class Elements {
        var x : IOHIDElement! = nil
        var y : IOHIDElement! = nil
        var z : IOHIDElement! = nil
        var rx : IOHIDElement! = nil
        var ry : IOHIDElement! = nil
        var rz : IOHIDElement! = nil
        var hat : IOHIDElement! = nil
        var buttons = [IOHIDElement?](repeating: nil, count: 16)
    }
    
    var device : IOHIDDevice
    var elements = Elements()
    
    init(_ newDevice: IOHIDDevice) {
        device = newDevice
    }
}

class GamepadValues {
    var x : Float = 0.0
    var y : Float = 0.0
    var z : Float = 0.0
    var rx : Float = 0.0
    var ry : Float = 0.0
    var rz : Float = 0.0
    var hat : Float = 0.0
    var buttons : [Bool] = [Bool](repeating: false, count: 16)
}

class Keyboard {
    class Elements {
        var a : IOHIDElement! = nil
        var b : IOHIDElement! = nil
        var c : IOHIDElement! = nil
        var d : IOHIDElement! = nil
        var e : IOHIDElement! = nil
        var f : IOHIDElement! = nil
        var g : IOHIDElement! = nil
        var h : IOHIDElement! = nil
        var i : IOHIDElement! = nil
        var j : IOHIDElement! = nil
        var k : IOHIDElement! = nil
        var l : IOHIDElement! = nil
        var m : IOHIDElement! = nil
        var n : IOHIDElement! = nil
        var o : IOHIDElement! = nil
        var p : IOHIDElement! = nil
        var q : IOHIDElement! = nil
        var r : IOHIDElement! = nil
        var s : IOHIDElement! = nil
        var t : IOHIDElement! = nil
        var u : IOHIDElement! = nil
        var v : IOHIDElement! = nil
        var w : IOHIDElement! = nil
        var x : IOHIDElement! = nil
        var y : IOHIDElement! = nil
        var z : IOHIDElement! = nil
        var spacebar : IOHIDElement! = nil
        var rightArrow : IOHIDElement! = nil
        var leftArrow : IOHIDElement! = nil
        var downArrow : IOHIDElement! = nil
        var upArrow : IOHIDElement! = nil
        var leftControl : IOHIDElement! = nil
        var leftShift : IOHIDElement! = nil
        var leftAlt : IOHIDElement! = nil
        var leftGUI : IOHIDElement! = nil
        var rightControl : IOHIDElement! = nil
        var rightShift : IOHIDElement! = nil
        var rightAlt : IOHIDElement! = nil
        var rightGUI : IOHIDElement! = nil
    }
    
    
    var device : IOHIDDevice
    var elements = Elements()
    
    init(_ newDevice: IOHIDDevice) {
        device = newDevice
    }
}

class KeyboardValues {
    var a : Bool = false
    var b : Bool = false
    var c : Bool = false
    var d : Bool = false
    var e : Bool = false
    var f : Bool = false
    var g : Bool = false
    var h : Bool = false
    var i : Bool = false
    var j : Bool = false
    var k : Bool = false
    var l : Bool = false
    var m : Bool = false
    var n : Bool = false
    var o : Bool = false
    var p : Bool = false
    var q : Bool = false
    var r : Bool = false
    var s : Bool = false
    var t : Bool = false
    var u : Bool = false
    var v : Bool = false
    var w : Bool = false
    var x : Bool = false
    var y : Bool = false
    var z : Bool = false
    var spacebar : Bool = false
    var rightArrow : Bool = false
    var leftArrow : Bool = false
    var downArrow : Bool = false
    var upArrow : Bool = false
    var leftControl : Bool = false
    var leftShift : Bool = false
    var leftAlt : Bool = false
    var leftGUI : Bool = false
    var rightControl : Bool = false
    var rightShift : Bool = false
    var rightAlt : Bool = false
    var rightGUI : Bool = false
}


func inputSystemInit() {
    
    let manager = IOHIDManagerCreate(kCFAllocatorDefault, UInt32(kIOHIDOptionsTypeNone))
    
    let matchingDictionaries = [
           [
            kIOHIDDeviceUsagePageKey : kHIDPage_GenericDesktop,
            kIOHIDDeviceUsageKey     : kHIDUsage_GD_GamePad,
        ], [
            kIOHIDDeviceUsagePageKey : kHIDPage_GenericDesktop,
            kIOHIDDeviceUsageKey     : kHIDUsage_GD_Joystick,
        ], [
            kIOHIDDeviceUsagePageKey : kHIDPage_GenericDesktop,
            kIOHIDDeviceUsageKey     : kHIDUsage_GD_Keyboard,
        ], [
            kIOHIDDeviceUsagePageKey : kHIDPage_GenericDesktop,
            kIOHIDDeviceUsageKey     : kHIDUsage_GD_Keypad,
        ]
    ]
    IOHIDManagerSetDeviceMatchingMultiple(manager, matchingDictionaries as CFArray)
    IOHIDManagerRegisterDeviceMatchingCallback(manager, deviceAdded, nil)
    IOHIDManagerRegisterDeviceRemovalCallback(manager, deviceRemoved, nil)
    IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
    IOHIDManagerOpen(manager, UInt32(kIOHIDOptionsTypeNone))
    
    hidManager = manager
}

func deviceAdded(_ inContext: UnsafeMutableRawPointer?, inResult: IOReturn, inSender: UnsafeMutableRawPointer?, deviceRef: IOHIDDevice!) {
    
    if IOHIDDeviceConformsTo(deviceRef, UInt32(kHIDPage_GenericDesktop), UInt32(kHIDUsage_GD_GamePad)) || IOHIDDeviceConformsTo(deviceRef, UInt32(kHIDPage_GenericDesktop), UInt32(kHIDUsage_GD_Joystick)) {
        
        print("gamepad added!")

        let gamepad = Gamepad(deviceRef)
        
        let buttons = [kIOHIDElementUsagePageKey : kHIDPage_Button]
        let buttonElements = IOHIDDeviceCopyMatchingElements(deviceRef, buttons as CFDictionary, UInt32(kIOHIDOptionsTypeNone)) as! Array<IOHIDElement>
        
        for button in buttonElements {
            let usage = IOHIDElementGetUsage(button)
            if usage < 16 {
                let idx = usage - 1
                gamepad.elements.buttons[Int(idx)] = button
            }
        }
        
        let genericDesktop = [kIOHIDElementUsagePageKey : kHIDPage_GenericDesktop]
        let genericDesktopElements = IOHIDDeviceCopyMatchingElements(deviceRef, genericDesktop as CFDictionary, UInt32(kIOHIDOptionsTypeNone)) as! Array<IOHIDElement>
        
        for gdElement in genericDesktopElements {
            let usage = IOHIDElementGetUsage(gdElement)
            
            if (usage == UInt32(kHIDUsage_GD_X)) {
                gamepad.elements.x = gdElement
            }
            else if (usage == UInt32(kHIDUsage_GD_Y)) {
                gamepad.elements.y = gdElement
            }
            else if (usage == UInt32(kHIDUsage_GD_Z)) {
                gamepad.elements.z = gdElement
            }
            else if (usage == UInt32(kHIDUsage_GD_Rx)) {
                gamepad.elements.rx = gdElement
            }
            else if (usage == UInt32(kHIDUsage_GD_Ry)) {
                gamepad.elements.ry = gdElement
            }
            else if (usage == UInt32(kHIDUsage_GD_Rz)) {
                gamepad.elements.rz = gdElement
            }
            else if (usage == UInt32(kHIDUsage_GD_Hatswitch)) {
                gamepad.elements.hat = gdElement
            }
        }
        
        // Insert gamepad at first available slot,
        // If no slots available, ignore!
        var idx = 0
        for gp in controllers.gamepads {
            if gp == nil {
                controllers.gamepads[idx] = gamepad
                break
            }
            idx += 1
        }
        
    }
    else if IOHIDDeviceConformsTo(deviceRef, UInt32(kHIDPage_GenericDesktop), UInt32(kHIDUsage_GD_Keyboard)) || IOHIDDeviceConformsTo(deviceRef, UInt32(kHIDPage_GenericDesktop), UInt32(kHIDUsage_GD_Keypad)) {
        
        print("keyboard added!")
        
        let keyboard = Keyboard(deviceRef)

        let genericDesktopElements = IOHIDDeviceCopyMatchingElements(deviceRef, nil, UInt32(kIOHIDOptionsTypeNone)) as! Array<IOHIDElement>
        
        for gdElement in genericDesktopElements {
            let usage = Int(IOHIDElementGetUsage(gdElement))
            
            switch usage {
            case kHIDUsage_KeyboardA:
                keyboard.elements.a = gdElement
            case kHIDUsage_KeyboardB:
                keyboard.elements.b = gdElement
            case kHIDUsage_KeyboardC:
                keyboard.elements.c = gdElement
            case kHIDUsage_KeyboardD:
                keyboard.elements.d = gdElement
            case kHIDUsage_KeyboardE:
                keyboard.elements.e = gdElement
            case kHIDUsage_KeyboardF:
                keyboard.elements.f = gdElement
            case kHIDUsage_KeyboardG:
                keyboard.elements.g = gdElement
            case kHIDUsage_KeyboardH:
                keyboard.elements.h = gdElement
            case kHIDUsage_KeyboardI:
                keyboard.elements.i = gdElement
            case kHIDUsage_KeyboardJ:
                keyboard.elements.j = gdElement
            case kHIDUsage_KeyboardK:
                keyboard.elements.k = gdElement
            case kHIDUsage_KeyboardL:
                keyboard.elements.l = gdElement
            case kHIDUsage_KeyboardM:
                keyboard.elements.m = gdElement
            case kHIDUsage_KeyboardN:
                keyboard.elements.n = gdElement
            case kHIDUsage_KeyboardO:
                keyboard.elements.o = gdElement
            case kHIDUsage_KeyboardP:
                keyboard.elements.p = gdElement
            case kHIDUsage_KeyboardQ:
                keyboard.elements.q = gdElement
            case kHIDUsage_KeyboardR:
                keyboard.elements.r = gdElement
            case kHIDUsage_KeyboardS:
                keyboard.elements.s = gdElement
            case kHIDUsage_KeyboardT:
                keyboard.elements.t = gdElement
            case kHIDUsage_KeyboardU:
                keyboard.elements.u = gdElement
            case kHIDUsage_KeyboardV:
                keyboard.elements.v = gdElement
            case kHIDUsage_KeyboardW:
                keyboard.elements.w = gdElement
            case kHIDUsage_KeyboardX:
                keyboard.elements.x = gdElement
            case kHIDUsage_KeyboardY:
                keyboard.elements.y = gdElement
            case kHIDUsage_KeyboardZ:
                keyboard.elements.z = gdElement
            case kHIDUsage_KeyboardSpacebar:
                keyboard.elements.spacebar = gdElement
            case kHIDUsage_KeyboardRightArrow:
                keyboard.elements.rightArrow = gdElement
            case kHIDUsage_KeyboardLeftArrow:
                keyboard.elements.leftArrow = gdElement
            case kHIDUsage_KeyboardDownArrow:
                keyboard.elements.downArrow = gdElement
            case kHIDUsage_KeyboardUpArrow:
                keyboard.elements.upArrow = gdElement
            case kHIDUsage_KeyboardLeftControl:
                keyboard.elements.leftControl = gdElement
            case kHIDUsage_KeyboardLeftShift:
                keyboard.elements.leftShift = gdElement
            case kHIDUsage_KeyboardLeftAlt:
                keyboard.elements.leftAlt = gdElement
            case kHIDUsage_KeyboardLeftGUI:
                keyboard.elements.leftGUI = gdElement
            case kHIDUsage_KeyboardRightControl:
                keyboard.elements.rightControl = gdElement
            case kHIDUsage_KeyboardRightShift:
                keyboard.elements.rightShift = gdElement
            case kHIDUsage_KeyboardRightAlt:
                keyboard.elements.rightAlt = gdElement
            case kHIDUsage_KeyboardRightGUI:
                keyboard.elements.rightGUI = gdElement
            default: break
            }
        }
        
        // Insert keyboard at first available slot,
        // If no slots available, ignore!
        var idx = 0
        for kb in controllers.keyboards {
            if kb == nil {
                controllers.keyboards[idx] = keyboard
                break
            }
            idx += 1
        }

    }
    else {
        print("unknown device added")
    }
    
}

func deviceRemoved(_ inContext: UnsafeMutableRawPointer?, inResult: IOReturn, inSender: UnsafeMutableRawPointer?, inIOHIDDeviceRef: IOHIDDevice!) {
    
    var gpIdx = 0
    for gp in controllers.gamepads {
        if gp == nil {
            continue
        }
        let gamepad = gp!
        if Unmanaged.passUnretained(inIOHIDDeviceRef!).toOpaque() == Unmanaged.passUnretained(gamepad.device).toOpaque() {
            controllers.gamepads[gpIdx] = nil
            print("gamepad removed!")
            return
        }
        gpIdx += 1
    }
    
    var kbIdx = 0
    for kb in controllers.keyboards {
        if kb == nil {
            continue
        }
        let keyboard = kb!
        if Unmanaged.passUnretained(inIOHIDDeviceRef!).toOpaque() == Unmanaged.passUnretained(keyboard.device).toOpaque() {
            controllers.gamepads[kbIdx] = nil
            print("keyboard removed!")
            return
        }
        kbIdx += 1
    }
}


// TODO: Fetch this with the HID API?
let DEADZONE_THRESHOLD : Float = 0.06


// TODO: The returned value objects don't necessarily match up index-wise with the controllers object 
func readControllers() -> ControllerValues {
    
    let controllerValues = ControllerValues()
    
    for gamepadOpt in controllers.gamepads {
        
        if gamepadOpt == nil {
            continue
        }
        
        let gamepad = gamepadOpt!
        
        let gamepadValues = GamepadValues()
        
        var value = Unmanaged<IOHIDValue>.passUnretained(IOHIDValueCreateWithIntegerValue(nil, IOHIDElementCreateWithDictionary(nil, [:] as CFDictionary), 0, 0))
        
        var idx = 0
        for button in gamepad.elements.buttons {
            if button != nil {
                IOHIDDeviceGetValue(gamepad.device, button!, &value)
                if IOHIDValueGetIntegerValue(value.takeUnretainedValue()) != 0 {
                    gamepadValues.buttons[idx] = true
                }
            }
            idx += 1
        }
        
        if gamepad.elements.x != nil {
            let min = IOHIDElementGetLogicalMin(gamepad.elements.x)
            let max = IOHIDElementGetLogicalMax(gamepad.elements.x)
            IOHIDDeviceGetValue(gamepad.device, gamepad.elements.x, &value)
            let val = IOHIDValueGetIntegerValue(value.takeUnretainedValue())
            let numerator = Float(val - min)
            let denominator = Float(max - min)
            let scaledValue = (( numerator / denominator ) * 2.0) - 1.0;
            if (fabs(scaledValue) > DEADZONE_THRESHOLD) {
                gamepadValues.x = scaledValue
            }
            else {
                gamepadValues.x = 0.0
            }
        }
        
        if gamepad.elements.y != nil {
            let min = IOHIDElementGetLogicalMin(gamepad.elements.y)
            let max = IOHIDElementGetLogicalMax(gamepad.elements.y)
            IOHIDDeviceGetValue(gamepad.device, gamepad.elements.y, &value)
            let val = IOHIDValueGetIntegerValue(value.takeUnretainedValue())
            let numerator = Float(val - min)
            let denominator = Float(max - min)
            let scaledValue = (( numerator / denominator ) * 2.0) - 1.0;
            if (fabs(scaledValue) > DEADZONE_THRESHOLD) {
                gamepadValues.y = scaledValue
            }
            else {
                gamepadValues.y = 0.0
            }
        }
        
        controllerValues.gamepads.append(gamepadValues)
    }
    
    for keyboardOpt in controllers.keyboards {
        
        if keyboardOpt == nil {
            continue
        }
        
        let keyboard = keyboardOpt!
        
        let keyboardValues = KeyboardValues()
        
        var value = Unmanaged<IOHIDValue>.passUnretained(IOHIDValueCreateWithIntegerValue(nil, IOHIDElementCreateWithDictionary(nil, [:] as CFDictionary), 0, 0))
        
        if keyboard.elements.a != nil {
            IOHIDDeviceGetValue(keyboard.device, keyboard.elements.a, &value)
            if IOHIDValueGetIntegerValue(value.takeUnretainedValue()) != 0 {
                keyboardValues.a = true
            }
        }
        if keyboard.elements.b != nil {
            IOHIDDeviceGetValue(keyboard.device, keyboard.elements.b, &value)
            if IOHIDValueGetIntegerValue(value.takeUnretainedValue()) != 0 {
                keyboardValues.b = true
            }
        }
        if keyboard.elements.c != nil {
            IOHIDDeviceGetValue(keyboard.device, keyboard.elements.c, &value)
            if IOHIDValueGetIntegerValue(value.takeUnretainedValue()) != 0 {
                keyboardValues.c = true
            }
        }
        if keyboard.elements.d != nil {
            IOHIDDeviceGetValue(keyboard.device, keyboard.elements.d, &value)
            if IOHIDValueGetIntegerValue(value.takeUnretainedValue()) != 0 {
                keyboardValues.d = true
            }
        }
        if keyboard.elements.e != nil {
            IOHIDDeviceGetValue(keyboard.device, keyboard.elements.e, &value)
            if IOHIDValueGetIntegerValue(value.takeUnretainedValue()) != 0 {
                keyboardValues.e = true
            }
        }
        if keyboard.elements.f != nil {
            IOHIDDeviceGetValue(keyboard.device, keyboard.elements.f, &value)
            if IOHIDValueGetIntegerValue(value.takeUnretainedValue()) != 0 {
                keyboardValues.f = true
            }
        }
        if keyboard.elements.g != nil {
            IOHIDDeviceGetValue(keyboard.device, keyboard.elements.g, &value)
            if IOHIDValueGetIntegerValue(value.takeUnretainedValue()) != 0 {
                keyboardValues.g = true
            }
        }
        if keyboard.elements.h != nil {
            IOHIDDeviceGetValue(keyboard.device, keyboard.elements.h, &value)
            if IOHIDValueGetIntegerValue(value.takeUnretainedValue()) != 0 {
                keyboardValues.h = true
            }
        }
        if keyboard.elements.i != nil {
            IOHIDDeviceGetValue(keyboard.device, keyboard.elements.i, &value)
            if IOHIDValueGetIntegerValue(value.takeUnretainedValue()) != 0 {
                keyboardValues.i = true
            }
        }
        if keyboard.elements.j != nil {
            IOHIDDeviceGetValue(keyboard.device, keyboard.elements.j, &value)
            if IOHIDValueGetIntegerValue(value.takeUnretainedValue()) != 0 {
                keyboardValues.j = true
            }
        }
        if keyboard.elements.k != nil {
            IOHIDDeviceGetValue(keyboard.device, keyboard.elements.k, &value)
            if IOHIDValueGetIntegerValue(value.takeUnretainedValue()) != 0 {
                keyboardValues.k = true
            }
        }
        if keyboard.elements.l != nil {
            IOHIDDeviceGetValue(keyboard.device, keyboard.elements.l, &value)
            if IOHIDValueGetIntegerValue(value.takeUnretainedValue()) != 0 {
                keyboardValues.l = true
            }
        }
        if keyboard.elements.m != nil {
            IOHIDDeviceGetValue(keyboard.device, keyboard.elements.m, &value)
            if IOHIDValueGetIntegerValue(value.takeUnretainedValue()) != 0 {
                keyboardValues.m = true
            }
        }
        if keyboard.elements.n != nil {
            IOHIDDeviceGetValue(keyboard.device, keyboard.elements.n, &value)
            if IOHIDValueGetIntegerValue(value.takeUnretainedValue()) != 0 {
                keyboardValues.n = true
            }
        }
        if keyboard.elements.o != nil {
            IOHIDDeviceGetValue(keyboard.device, keyboard.elements.o, &value)
            if IOHIDValueGetIntegerValue(value.takeUnretainedValue()) != 0 {
                keyboardValues.o = true
            }
        }
        if keyboard.elements.p != nil {
            IOHIDDeviceGetValue(keyboard.device, keyboard.elements.p, &value)
            if IOHIDValueGetIntegerValue(value.takeUnretainedValue()) != 0 {
                keyboardValues.p = true
            }
        }
        if keyboard.elements.q != nil {
            IOHIDDeviceGetValue(keyboard.device, keyboard.elements.q, &value)
            if IOHIDValueGetIntegerValue(value.takeUnretainedValue()) != 0 {
                keyboardValues.q = true
            }
        }
        if keyboard.elements.r != nil {
            IOHIDDeviceGetValue(keyboard.device, keyboard.elements.r, &value)
            if IOHIDValueGetIntegerValue(value.takeUnretainedValue()) != 0 {
                keyboardValues.r = true
            }
        }
        if keyboard.elements.s != nil {
            IOHIDDeviceGetValue(keyboard.device, keyboard.elements.s, &value)
            if IOHIDValueGetIntegerValue(value.takeUnretainedValue()) != 0 {
                keyboardValues.s = true
            }
        }
        if keyboard.elements.t != nil {
            IOHIDDeviceGetValue(keyboard.device, keyboard.elements.t, &value)
            if IOHIDValueGetIntegerValue(value.takeUnretainedValue()) != 0 {
                keyboardValues.t = true
            }
        }
        if keyboard.elements.u != nil {
            IOHIDDeviceGetValue(keyboard.device, keyboard.elements.u, &value)
            if IOHIDValueGetIntegerValue(value.takeUnretainedValue()) != 0 {
                keyboardValues.u = true
            }
        }
        if keyboard.elements.v != nil {
            IOHIDDeviceGetValue(keyboard.device, keyboard.elements.v, &value)
            if IOHIDValueGetIntegerValue(value.takeUnretainedValue()) != 0 {
                keyboardValues.v = true
            }
        }
        if keyboard.elements.w != nil {
            IOHIDDeviceGetValue(keyboard.device, keyboard.elements.w, &value)
            if IOHIDValueGetIntegerValue(value.takeUnretainedValue()) != 0 {
                keyboardValues.w = true
            }
        }
        if keyboard.elements.x != nil {
            IOHIDDeviceGetValue(keyboard.device, keyboard.elements.x, &value)
            if IOHIDValueGetIntegerValue(value.takeUnretainedValue()) != 0 {
                keyboardValues.x = true
            }
        }
        if keyboard.elements.y != nil {
            IOHIDDeviceGetValue(keyboard.device, keyboard.elements.y, &value)
            if IOHIDValueGetIntegerValue(value.takeUnretainedValue()) != 0 {
                keyboardValues.y = true
            }
        }
        if keyboard.elements.z != nil {
            IOHIDDeviceGetValue(keyboard.device, keyboard.elements.z, &value)
            if IOHIDValueGetIntegerValue(value.takeUnretainedValue()) != 0 {
                keyboardValues.z = true
            }
        }
        if keyboard.elements.spacebar != nil {
            IOHIDDeviceGetValue(keyboard.device, keyboard.elements.spacebar, &value)
            if IOHIDValueGetIntegerValue(value.takeUnretainedValue()) != 0 {
                keyboardValues.spacebar = true
            }
        }
        if keyboard.elements.rightArrow != nil {
            IOHIDDeviceGetValue(keyboard.device, keyboard.elements.rightArrow, &value)
            if IOHIDValueGetIntegerValue(value.takeUnretainedValue()) != 0 {
                keyboardValues.rightArrow = true
            }
        }
        if keyboard.elements.leftArrow != nil {
            IOHIDDeviceGetValue(keyboard.device, keyboard.elements.leftArrow, &value)
            if IOHIDValueGetIntegerValue(value.takeUnretainedValue()) != 0 {
                keyboardValues.leftArrow = true
            }
        }
        if keyboard.elements.downArrow != nil {
            IOHIDDeviceGetValue(keyboard.device, keyboard.elements.downArrow, &value)
            if IOHIDValueGetIntegerValue(value.takeUnretainedValue()) != 0 {
                keyboardValues.downArrow = true
            }
        }
        if keyboard.elements.upArrow != nil {
            IOHIDDeviceGetValue(keyboard.device, keyboard.elements.upArrow, &value)
            if IOHIDValueGetIntegerValue(value.takeUnretainedValue()) != 0 {
                keyboardValues.upArrow = true
            }
        }
        if keyboard.elements.leftControl != nil {
            IOHIDDeviceGetValue(keyboard.device, keyboard.elements.leftControl, &value)
            if IOHIDValueGetIntegerValue(value.takeUnretainedValue()) != 0 {
                keyboardValues.leftControl = true
            }
        }
        if keyboard.elements.leftShift != nil {
            IOHIDDeviceGetValue(keyboard.device, keyboard.elements.leftShift, &value)
            if IOHIDValueGetIntegerValue(value.takeUnretainedValue()) != 0 {
                keyboardValues.leftShift = true
            }
        }
        if keyboard.elements.leftAlt != nil {
            IOHIDDeviceGetValue(keyboard.device, keyboard.elements.leftAlt, &value)
            if IOHIDValueGetIntegerValue(value.takeUnretainedValue()) != 0 {
                keyboardValues.leftAlt = true
            }
        }
        if keyboard.elements.leftGUI != nil {
            IOHIDDeviceGetValue(keyboard.device, keyboard.elements.leftGUI, &value)
            if IOHIDValueGetIntegerValue(value.takeUnretainedValue()) != 0 {
                keyboardValues.leftGUI = true
            }
        }
        if keyboard.elements.rightControl != nil {
            IOHIDDeviceGetValue(keyboard.device, keyboard.elements.rightControl, &value)
            if IOHIDValueGetIntegerValue(value.takeUnretainedValue()) != 0 {
                keyboardValues.rightControl = true
            }
        }
        if keyboard.elements.rightShift != nil {
            IOHIDDeviceGetValue(keyboard.device, keyboard.elements.rightShift, &value)
            if IOHIDValueGetIntegerValue(value.takeUnretainedValue()) != 0 {
                keyboardValues.rightShift = true
            }
        }
        if keyboard.elements.rightAlt != nil {
            IOHIDDeviceGetValue(keyboard.device, keyboard.elements.rightAlt, &value)
            if IOHIDValueGetIntegerValue(value.takeUnretainedValue()) != 0 {
                keyboardValues.rightAlt = true
            }
        }
        if keyboard.elements.rightGUI != nil {
            IOHIDDeviceGetValue(keyboard.device, keyboard.elements.rightGUI, &value)
            if IOHIDValueGetIntegerValue(value.takeUnretainedValue()) != 0 {
                keyboardValues.rightGUI = true
            }
        }
        
        controllerValues.keyboards.append(keyboardValues)
    }
    
    return controllerValues

}
