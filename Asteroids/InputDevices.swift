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

// Gamepad Structs
var gamepad : IOHIDDeviceRef! = nil
var gamepadElements : GamepadElements! = nil

struct GamepadElements {
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

struct GamepadInputs {
    var x : Float = 0.0
    var y : Float = 0.0
    var z : Float = 0.0
    var rx : Float = 0.0
    var ry : Float = 0.0
    var rz : Float = 0.0
    var hat : Float = 0.0
    var buttons : [Bool] = [Bool](count: 16, repeatedValue: false)
}

// Keyboard Structs
var keyboard : IOHIDDeviceRef! = nil
var keyboardElements : KeyboardElements! = nil

struct KeyboardElements {
    var a : IOHIDElementRef! = nil
    var b : IOHIDElementRef! = nil
    var c : IOHIDElementRef! = nil
    var d : IOHIDElementRef! = nil
    var e : IOHIDElementRef! = nil
    var f : IOHIDElementRef! = nil
    var g : IOHIDElementRef! = nil
    var h : IOHIDElementRef! = nil
    var i : IOHIDElementRef! = nil
    var j : IOHIDElementRef! = nil
    var k : IOHIDElementRef! = nil
    var l : IOHIDElementRef! = nil
    var m : IOHIDElementRef! = nil
    var n : IOHIDElementRef! = nil
    var o : IOHIDElementRef! = nil
    var p : IOHIDElementRef! = nil
    var q : IOHIDElementRef! = nil
    var r : IOHIDElementRef! = nil
    var s : IOHIDElementRef! = nil
    var t : IOHIDElementRef! = nil
    var u : IOHIDElementRef! = nil
    var v : IOHIDElementRef! = nil
    var w : IOHIDElementRef! = nil
    var x : IOHIDElementRef! = nil
    var y : IOHIDElementRef! = nil
    var z : IOHIDElementRef! = nil
    var spacebar : IOHIDElementRef! = nil
    var rightArrow : IOHIDElementRef! = nil
    var leftArrow : IOHIDElementRef! = nil
    var downArrow : IOHIDElementRef! = nil
    var upArrow : IOHIDElementRef! = nil
    var leftControl : IOHIDElementRef! = nil
    var leftShift : IOHIDElementRef! = nil
    var leftAlt : IOHIDElementRef! = nil
    var leftGUI : IOHIDElementRef! = nil
    var rightControl : IOHIDElementRef! = nil
    var rightShift : IOHIDElementRef! = nil
    var rightAlt : IOHIDElementRef! = nil
    var rightGUI : IOHIDElementRef! = nil
}

struct KeyboardInputs {
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
    
    let matchingDictionaries = [[
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
    IOHIDManagerSetDeviceMatchingMultiple(manager.takeUnretainedValue(), matchingDictionaries)
    IOHIDManagerRegisterDeviceMatchingCallback(manager.takeUnretainedValue(), deviceAdded, nil)
    IOHIDManagerRegisterDeviceRemovalCallback(manager.takeUnretainedValue(), deviceRemoved, nil)
    IOHIDManagerScheduleWithRunLoop(manager.takeUnretainedValue(), CFRunLoopGetCurrent(), kCFRunLoopDefaultMode)
    IOHIDManagerOpen(manager.takeUnretainedValue(), UInt32(kIOHIDOptionsTypeNone))
    
    hidManager = manager.takeUnretainedValue()
}

func deviceAdded(inContext: UnsafeMutablePointer<Void>, inResult: IOReturn, inSender: UnsafeMutablePointer<Void>, deviceRef: IOHIDDevice!) {
    
    if IOHIDDeviceConformsTo(deviceRef, UInt32(kHIDPage_GenericDesktop), UInt32(kHIDUsage_GD_GamePad)) {
        print("gamepad added!")
        
        if gamepad == nil {
            gamepad = deviceRef
            
            var controllerEls = GamepadElements()
            
            let buttons = [kIOHIDElementUsagePageKey : kHIDPage_Button]
            let buttonElements = IOHIDDeviceCopyMatchingElements(deviceRef, buttons, UInt32(kIOHIDOptionsTypeNone))
            
            for buttonRef in buttonElements.takeUnretainedValue() as Array {
                let button = buttonRef as! IOHIDElement
                let usage = IOHIDElementGetUsage(button)
                if usage < 16 {
                    let idx = usage - 1
                    controllerEls.buttons![Int(idx)] = button
                }
            }
            
            let genericDesktop = [kIOHIDElementUsagePageKey : kHIDPage_GenericDesktop]
            let genericDesktopElements = IOHIDDeviceCopyMatchingElements(deviceRef, genericDesktop, UInt32(kIOHIDOptionsTypeNone))
            
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
    else if IOHIDDeviceConformsTo(deviceRef, UInt32(kHIDPage_GenericDesktop), UInt32(kHIDUsage_GD_Joystick)) {
        print("joystick added!")
        
        if gamepad == nil {
            gamepad = deviceRef
            
            var controllerEls = GamepadElements()
            
            let buttons = [kIOHIDElementUsagePageKey : kHIDPage_Button]
            let buttonElements = IOHIDDeviceCopyMatchingElements(deviceRef, buttons, UInt32(kIOHIDOptionsTypeNone))
            
            for buttonRef in buttonElements.takeUnretainedValue() as Array {
                let button = buttonRef as! IOHIDElement
                let usage = IOHIDElementGetUsage(button)
                if usage < 16 {
                    let idx = usage - 1
                    controllerEls.buttons![Int(idx)] = button
                }
            }
            
            let genericDesktop = [kIOHIDElementUsagePageKey : kHIDPage_GenericDesktop]
            let genericDesktopElements = IOHIDDeviceCopyMatchingElements(deviceRef, genericDesktop, UInt32(kIOHIDOptionsTypeNone))
            
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
    else if IOHIDDeviceConformsTo(deviceRef, UInt32(kHIDPage_GenericDesktop), UInt32(kHIDUsage_GD_Keyboard)) {
        print("keyboard added!")
        
        // TODO: Multiple keyboards!
        if keyboard == nil {
            keyboard = deviceRef
            
            var keyboardEls = KeyboardElements()
            let genericDesktopElements = IOHIDDeviceCopyMatchingElements(deviceRef, nil, UInt32(kIOHIDOptionsTypeNone))
            
            for gdElementRef in genericDesktopElements.takeUnretainedValue() as Array {
                let gdElement = gdElementRef as! IOHIDElement
                let usage = Int(IOHIDElementGetUsage(gdElement))
                
                switch usage {
                case kHIDUsage_KeyboardA:
                    keyboardEls.a = gdElement
                case kHIDUsage_KeyboardB:
                    keyboardEls.b = gdElement
                case kHIDUsage_KeyboardC:
                    keyboardEls.c = gdElement
                case kHIDUsage_KeyboardD:
                    keyboardEls.d = gdElement
                case kHIDUsage_KeyboardE:
                    keyboardEls.e = gdElement
                case kHIDUsage_KeyboardF:
                    keyboardEls.f = gdElement
                case kHIDUsage_KeyboardG:
                    keyboardEls.g = gdElement
                case kHIDUsage_KeyboardH:
                    keyboardEls.h = gdElement
                case kHIDUsage_KeyboardI:
                    keyboardEls.i = gdElement
                case kHIDUsage_KeyboardJ:
                    keyboardEls.j = gdElement
                case kHIDUsage_KeyboardK:
                    keyboardEls.k = gdElement
                case kHIDUsage_KeyboardL:
                    keyboardEls.l = gdElement
                case kHIDUsage_KeyboardM:
                    keyboardEls.m = gdElement
                case kHIDUsage_KeyboardN:
                    keyboardEls.n = gdElement
                case kHIDUsage_KeyboardO:
                    keyboardEls.o = gdElement
                case kHIDUsage_KeyboardP:
                    keyboardEls.p = gdElement
                case kHIDUsage_KeyboardQ:
                    keyboardEls.q = gdElement
                case kHIDUsage_KeyboardR:
                    keyboardEls.r = gdElement
                case kHIDUsage_KeyboardS:
                    keyboardEls.s = gdElement
                case kHIDUsage_KeyboardT:
                    keyboardEls.t = gdElement
                case kHIDUsage_KeyboardU:
                    keyboardEls.u = gdElement
                case kHIDUsage_KeyboardV:
                    keyboardEls.v = gdElement
                case kHIDUsage_KeyboardW:
                    keyboardEls.w = gdElement
                case kHIDUsage_KeyboardX:
                    keyboardEls.x = gdElement
                case kHIDUsage_KeyboardY:
                    keyboardEls.y = gdElement
                case kHIDUsage_KeyboardZ:
                    keyboardEls.z = gdElement
                case kHIDUsage_KeyboardSpacebar:
                    keyboardEls.spacebar = gdElement
                case kHIDUsage_KeyboardRightArrow:
                    keyboardEls.rightArrow = gdElement
                case kHIDUsage_KeyboardLeftArrow:
                    keyboardEls.leftArrow = gdElement
                case kHIDUsage_KeyboardDownArrow:
                    keyboardEls.downArrow = gdElement
                case kHIDUsage_KeyboardUpArrow:
                    keyboardEls.upArrow = gdElement
                case kHIDUsage_KeyboardLeftControl:
                    keyboardEls.leftControl = gdElement
                case kHIDUsage_KeyboardLeftShift:
                    keyboardEls.leftShift = gdElement
                case kHIDUsage_KeyboardLeftAlt:
                    keyboardEls.leftAlt = gdElement
                case kHIDUsage_KeyboardLeftGUI:
                    keyboardEls.leftGUI = gdElement
                case kHIDUsage_KeyboardRightControl:
                    keyboardEls.rightControl = gdElement
                case kHIDUsage_KeyboardRightShift:
                    keyboardEls.rightShift = gdElement
                case kHIDUsage_KeyboardRightAlt:
                    keyboardEls.rightAlt = gdElement
                case kHIDUsage_KeyboardRightGUI:
                    keyboardEls.rightGUI = gdElement
                default: break
                }
            }
            
            keyboardElements = keyboardEls
        }
    }
    else if IOHIDDeviceConformsTo(deviceRef, UInt32(kHIDPage_GenericDesktop), UInt32(kHIDUsage_GD_Keypad)) {
        print("keypad added!")
    }
    else {
        print("unknown device added")
    }
    
}

func deviceRemoved(inContext: UnsafeMutablePointer<Void>, inResult: IOReturn, inSender: UnsafeMutablePointer<Void>, inIOHIDDeviceRef: IOHIDDevice!) {
    
    print("device removed!")
    
    if unsafeAddressOf(inIOHIDDeviceRef) == unsafeAddressOf(gamepad) {
        gamepad = nil
        gamepadElements = nil
    }
}
