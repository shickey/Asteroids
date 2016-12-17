//
//  Input.swift
//  Asteroids
//
//  Created by Sean Hickey on 12/7/16.
//  Copyright © 2016 Sean Hickey. All rights reserved.
//

import IOKit
import IOKit.hid

typealias HIDUsage = U32

var hidManager : IOHIDManager! = nil

let MAX_CONTROLLERS = 4
let controllers = Controllers()

class Controllers {
    var gamepads = [Gamepad?](repeating: nil, count: MAX_CONTROLLERS)
    var keyboard = Keyboard()
}

class Gamepad {
    var device : IOHIDDevice
    
    var buttons : [HIDUsage : Bool] = [:]
    var continuous : [HIDUsage : Float] = [:]
    
    var x   : Float? { return continuous[HIDUsage(kHIDUsage_GD_X)] }
    var y   : Float? { return continuous[HIDUsage(kHIDUsage_GD_Y)] }
    var z   : Float? { return continuous[HIDUsage(kHIDUsage_GD_Z)] }
    var rx  : Float? { return continuous[HIDUsage(kHIDUsage_GD_Rx)] }
    var ry  : Float? { return continuous[HIDUsage(kHIDUsage_GD_Ry)] }
    var rz  : Float? { return continuous[HIDUsage(kHIDUsage_GD_Rz)] }
    var hat : Float? { return continuous[HIDUsage(kHIDUsage_GD_Hatswitch)] }
    
    init(_ newDevice: IOHIDDevice) {
        device = newDevice
    }
}


class Keyboard {
    var keys : [HIDUsage : Bool] = [:]
    
    var a : Bool { return keys[HIDUsage(kHIDUsage_KeyboardA)] ?? false }
    var b : Bool { return keys[HIDUsage(kHIDUsage_KeyboardB)] ?? false }
    var c : Bool { return keys[HIDUsage(kHIDUsage_KeyboardC)] ?? false }
    var d : Bool { return keys[HIDUsage(kHIDUsage_KeyboardD)] ?? false }
    var e : Bool { return keys[HIDUsage(kHIDUsage_KeyboardE)] ?? false }
    var f : Bool { return keys[HIDUsage(kHIDUsage_KeyboardF)] ?? false }
    var g : Bool { return keys[HIDUsage(kHIDUsage_KeyboardG)] ?? false }
    var h : Bool { return keys[HIDUsage(kHIDUsage_KeyboardH)] ?? false }
    var i : Bool { return keys[HIDUsage(kHIDUsage_KeyboardI)] ?? false }
    var j : Bool { return keys[HIDUsage(kHIDUsage_KeyboardJ)] ?? false }
    var k : Bool { return keys[HIDUsage(kHIDUsage_KeyboardK)] ?? false }
    var l : Bool { return keys[HIDUsage(kHIDUsage_KeyboardL)] ?? false }
    var m : Bool { return keys[HIDUsage(kHIDUsage_KeyboardM)] ?? false }
    var n : Bool { return keys[HIDUsage(kHIDUsage_KeyboardN)] ?? false }
    var o : Bool { return keys[HIDUsage(kHIDUsage_KeyboardO)] ?? false }
    var p : Bool { return keys[HIDUsage(kHIDUsage_KeyboardP)] ?? false }
    var q : Bool { return keys[HIDUsage(kHIDUsage_KeyboardQ)] ?? false }
    var r : Bool { return keys[HIDUsage(kHIDUsage_KeyboardR)] ?? false }
    var s : Bool { return keys[HIDUsage(kHIDUsage_KeyboardS)] ?? false }
    var t : Bool { return keys[HIDUsage(kHIDUsage_KeyboardT)] ?? false }
    var u : Bool { return keys[HIDUsage(kHIDUsage_KeyboardU)] ?? false }
    var v : Bool { return keys[HIDUsage(kHIDUsage_KeyboardV)] ?? false }
    var w : Bool { return keys[HIDUsage(kHIDUsage_KeyboardW)] ?? false }
    var x : Bool { return keys[HIDUsage(kHIDUsage_KeyboardX)] ?? false }
    var y : Bool { return keys[HIDUsage(kHIDUsage_KeyboardY)] ?? false }
    var z : Bool { return keys[HIDUsage(kHIDUsage_KeyboardZ)] ?? false }
    var keyboard1 : Bool { return keys[HIDUsage(kHIDUsage_Keyboard1)] ?? false }
    var keyboard2 : Bool { return keys[HIDUsage(kHIDUsage_Keyboard2)] ?? false }
    var keyboard3 : Bool { return keys[HIDUsage(kHIDUsage_Keyboard3)] ?? false }
    var keyboard4 : Bool { return keys[HIDUsage(kHIDUsage_Keyboard4)] ?? false }
    var keyboard5 : Bool { return keys[HIDUsage(kHIDUsage_Keyboard5)] ?? false }
    var keyboard6 : Bool { return keys[HIDUsage(kHIDUsage_Keyboard6)] ?? false }
    var keyboard7 : Bool { return keys[HIDUsage(kHIDUsage_Keyboard7)] ?? false }
    var keyboard8 : Bool { return keys[HIDUsage(kHIDUsage_Keyboard8)] ?? false }
    var keyboard9 : Bool { return keys[HIDUsage(kHIDUsage_Keyboard9)] ?? false }
    var keyboard0 : Bool { return keys[HIDUsage(kHIDUsage_Keyboard0)] ?? false }
    var returnOrEnter : Bool { return keys[HIDUsage(kHIDUsage_KeyboardReturnOrEnter)] ?? false }
    var escape : Bool { return keys[HIDUsage(kHIDUsage_KeyboardEscape)] ?? false }
    var deleteOrBackspace : Bool { return keys[HIDUsage(kHIDUsage_KeyboardDeleteOrBackspace)] ?? false }
    var tab : Bool { return keys[HIDUsage(kHIDUsage_KeyboardTab)] ?? false }
    var spacebar : Bool { return keys[HIDUsage(kHIDUsage_KeyboardSpacebar)] ?? false }
    var hyphen : Bool { return keys[HIDUsage(kHIDUsage_KeyboardHyphen)] ?? false }
    var equalSign : Bool { return keys[HIDUsage(kHIDUsage_KeyboardEqualSign)] ?? false }
    var openBracket : Bool { return keys[HIDUsage(kHIDUsage_KeyboardOpenBracket)] ?? false }
    var closeBracket : Bool { return keys[HIDUsage(kHIDUsage_KeyboardCloseBracket)] ?? false }
    var backslash : Bool { return keys[HIDUsage(kHIDUsage_KeyboardBackslash)] ?? false }
    var nonUSPound : Bool { return keys[HIDUsage(kHIDUsage_KeyboardNonUSPound)] ?? false }
    var semicolon : Bool { return keys[HIDUsage(kHIDUsage_KeyboardSemicolon)] ?? false }
    var quote : Bool { return keys[HIDUsage(kHIDUsage_KeyboardQuote)] ?? false }
    var graveAccentAndTilde : Bool { return keys[HIDUsage(kHIDUsage_KeyboardGraveAccentAndTilde)] ?? false }
    var comma : Bool { return keys[HIDUsage(kHIDUsage_KeyboardComma)] ?? false }
    var period : Bool { return keys[HIDUsage(kHIDUsage_KeyboardPeriod)] ?? false }
    var slash : Bool { return keys[HIDUsage(kHIDUsage_KeyboardSlash)] ?? false }
    var capsLock : Bool { return keys[HIDUsage(kHIDUsage_KeyboardCapsLock)] ?? false }
    var f1 : Bool { return keys[HIDUsage(kHIDUsage_KeyboardF1)] ?? false }
    var f2 : Bool { return keys[HIDUsage(kHIDUsage_KeyboardF2)] ?? false }
    var f3 : Bool { return keys[HIDUsage(kHIDUsage_KeyboardF3)] ?? false }
    var f4 : Bool { return keys[HIDUsage(kHIDUsage_KeyboardF4)] ?? false }
    var f5 : Bool { return keys[HIDUsage(kHIDUsage_KeyboardF5)] ?? false }
    var f6 : Bool { return keys[HIDUsage(kHIDUsage_KeyboardF6)] ?? false }
    var f7 : Bool { return keys[HIDUsage(kHIDUsage_KeyboardF7)] ?? false }
    var f8 : Bool { return keys[HIDUsage(kHIDUsage_KeyboardF8)] ?? false }
    var f9 : Bool { return keys[HIDUsage(kHIDUsage_KeyboardF9)] ?? false }
    var f10 : Bool { return keys[HIDUsage(kHIDUsage_KeyboardF10)] ?? false }
    var f11 : Bool { return keys[HIDUsage(kHIDUsage_KeyboardF11)] ?? false }
    var f12 : Bool { return keys[HIDUsage(kHIDUsage_KeyboardF12)] ?? false }
    var printScreen : Bool { return keys[HIDUsage(kHIDUsage_KeyboardPrintScreen)] ?? false }
    var scrollLock : Bool { return keys[HIDUsage(kHIDUsage_KeyboardScrollLock)] ?? false }
    var pause : Bool { return keys[HIDUsage(kHIDUsage_KeyboardPause)] ?? false }
    var insert : Bool { return keys[HIDUsage(kHIDUsage_KeyboardInsert)] ?? false }
    var home : Bool { return keys[HIDUsage(kHIDUsage_KeyboardHome)] ?? false }
    var pageUp : Bool { return keys[HIDUsage(kHIDUsage_KeyboardPageUp)] ?? false }
    var deleteForward : Bool { return keys[HIDUsage(kHIDUsage_KeyboardDeleteForward)] ?? false }
    var end : Bool { return keys[HIDUsage(kHIDUsage_KeyboardEnd)] ?? false }
    var pageDown : Bool { return keys[HIDUsage(kHIDUsage_KeyboardPageDown)] ?? false }
    var rightArrow : Bool { return keys[HIDUsage(kHIDUsage_KeyboardRightArrow)] ?? false }
    var leftArrow : Bool { return keys[HIDUsage(kHIDUsage_KeyboardLeftArrow)] ?? false }
    var downArrow : Bool { return keys[HIDUsage(kHIDUsage_KeyboardDownArrow)] ?? false }
    var upArrow : Bool { return keys[HIDUsage(kHIDUsage_KeyboardUpArrow)] ?? false }
    var keypadNumLock : Bool { return keys[HIDUsage(kHIDUsage_KeypadNumLock)] ?? false }
    var keypadSlash : Bool { return keys[HIDUsage(kHIDUsage_KeypadSlash)] ?? false }
    var keypadAsterisk : Bool { return keys[HIDUsage(kHIDUsage_KeypadAsterisk)] ?? false }
    var keypadHyphen : Bool { return keys[HIDUsage(kHIDUsage_KeypadHyphen)] ?? false }
    var keypadPlus : Bool { return keys[HIDUsage(kHIDUsage_KeypadPlus)] ?? false }
    var keypadEnter : Bool { return keys[HIDUsage(kHIDUsage_KeypadEnter)] ?? false }
    var keypad1 : Bool { return keys[HIDUsage(kHIDUsage_Keypad1)] ?? false }
    var keypad2 : Bool { return keys[HIDUsage(kHIDUsage_Keypad2)] ?? false }
    var keypad3 : Bool { return keys[HIDUsage(kHIDUsage_Keypad3)] ?? false }
    var keypad4 : Bool { return keys[HIDUsage(kHIDUsage_Keypad4)] ?? false }
    var keypad5 : Bool { return keys[HIDUsage(kHIDUsage_Keypad5)] ?? false }
    var keypad6 : Bool { return keys[HIDUsage(kHIDUsage_Keypad6)] ?? false }
    var keypad7 : Bool { return keys[HIDUsage(kHIDUsage_Keypad7)] ?? false }
    var keypad8 : Bool { return keys[HIDUsage(kHIDUsage_Keypad8)] ?? false }
    var keypad9 : Bool { return keys[HIDUsage(kHIDUsage_Keypad9)] ?? false }
    var keypad0 : Bool { return keys[HIDUsage(kHIDUsage_Keypad0)] ?? false }
    var keypadPeriod : Bool { return keys[HIDUsage(kHIDUsage_KeypadPeriod)] ?? false }
    var nonUSBackslash : Bool { return keys[HIDUsage(kHIDUsage_KeyboardNonUSBackslash)] ?? false }
    var application : Bool { return keys[HIDUsage(kHIDUsage_KeyboardApplication)] ?? false }
    var power : Bool { return keys[HIDUsage(kHIDUsage_KeyboardPower)] ?? false }
    var keypadEqualSign : Bool { return keys[HIDUsage(kHIDUsage_KeypadEqualSign)] ?? false }
    var f13 : Bool { return keys[HIDUsage(kHIDUsage_KeyboardF13)] ?? false }
    var f14 : Bool { return keys[HIDUsage(kHIDUsage_KeyboardF14)] ?? false }
    var f15 : Bool { return keys[HIDUsage(kHIDUsage_KeyboardF15)] ?? false }
    var f16 : Bool { return keys[HIDUsage(kHIDUsage_KeyboardF16)] ?? false }
    var f17 : Bool { return keys[HIDUsage(kHIDUsage_KeyboardF17)] ?? false }
    var f18 : Bool { return keys[HIDUsage(kHIDUsage_KeyboardF18)] ?? false }
    var f19 : Bool { return keys[HIDUsage(kHIDUsage_KeyboardF19)] ?? false }
    var f20 : Bool { return keys[HIDUsage(kHIDUsage_KeyboardF20)] ?? false }
    var f21 : Bool { return keys[HIDUsage(kHIDUsage_KeyboardF21)] ?? false }
    var f22 : Bool { return keys[HIDUsage(kHIDUsage_KeyboardF22)] ?? false }
    var f23 : Bool { return keys[HIDUsage(kHIDUsage_KeyboardF23)] ?? false }
    var f24 : Bool { return keys[HIDUsage(kHIDUsage_KeyboardF24)] ?? false }
    var execute : Bool { return keys[HIDUsage(kHIDUsage_KeyboardExecute)] ?? false }
    var help : Bool { return keys[HIDUsage(kHIDUsage_KeyboardHelp)] ?? false }
    var menu : Bool { return keys[HIDUsage(kHIDUsage_KeyboardMenu)] ?? false }
    var select : Bool { return keys[HIDUsage(kHIDUsage_KeyboardSelect)] ?? false }
    var stop : Bool { return keys[HIDUsage(kHIDUsage_KeyboardStop)] ?? false }
    var again : Bool { return keys[HIDUsage(kHIDUsage_KeyboardAgain)] ?? false }
    var undo : Bool { return keys[HIDUsage(kHIDUsage_KeyboardUndo)] ?? false }
    var cut : Bool { return keys[HIDUsage(kHIDUsage_KeyboardCut)] ?? false }
    var copy : Bool { return keys[HIDUsage(kHIDUsage_KeyboardCopy)] ?? false }
    var paste : Bool { return keys[HIDUsage(kHIDUsage_KeyboardPaste)] ?? false }
    var find : Bool { return keys[HIDUsage(kHIDUsage_KeyboardFind)] ?? false }
    var mute : Bool { return keys[HIDUsage(kHIDUsage_KeyboardMute)] ?? false }
    var volumeUp : Bool { return keys[HIDUsage(kHIDUsage_KeyboardVolumeUp)] ?? false }
    var volumeDown : Bool { return keys[HIDUsage(kHIDUsage_KeyboardVolumeDown)] ?? false }
    var lockingCapsLock : Bool { return keys[HIDUsage(kHIDUsage_KeyboardLockingCapsLock)] ?? false }
    var lockingNumLock : Bool { return keys[HIDUsage(kHIDUsage_KeyboardLockingNumLock)] ?? false }
    var lockingScrollLock : Bool { return keys[HIDUsage(kHIDUsage_KeyboardLockingScrollLock)] ?? false }
    var keypadComma : Bool { return keys[HIDUsage(kHIDUsage_KeypadComma)] ?? false }
    var keypadEqualSignAS400 : Bool { return keys[HIDUsage(kHIDUsage_KeypadEqualSignAS400)] ?? false }
    var international1 : Bool { return keys[HIDUsage(kHIDUsage_KeyboardInternational1)] ?? false }
    var international2 : Bool { return keys[HIDUsage(kHIDUsage_KeyboardInternational2)] ?? false }
    var international3 : Bool { return keys[HIDUsage(kHIDUsage_KeyboardInternational3)] ?? false }
    var international4 : Bool { return keys[HIDUsage(kHIDUsage_KeyboardInternational4)] ?? false }
    var international5 : Bool { return keys[HIDUsage(kHIDUsage_KeyboardInternational5)] ?? false }
    var international6 : Bool { return keys[HIDUsage(kHIDUsage_KeyboardInternational6)] ?? false }
    var international7 : Bool { return keys[HIDUsage(kHIDUsage_KeyboardInternational7)] ?? false }
    var international8 : Bool { return keys[HIDUsage(kHIDUsage_KeyboardInternational8)] ?? false }
    var international9 : Bool { return keys[HIDUsage(kHIDUsage_KeyboardInternational9)] ?? false }
    var LANG1 : Bool { return keys[HIDUsage(kHIDUsage_KeyboardLANG1)] ?? false }
    var LANG2 : Bool { return keys[HIDUsage(kHIDUsage_KeyboardLANG2)] ?? false }
    var LANG3 : Bool { return keys[HIDUsage(kHIDUsage_KeyboardLANG3)] ?? false }
    var LANG4 : Bool { return keys[HIDUsage(kHIDUsage_KeyboardLANG4)] ?? false }
    var LANG5 : Bool { return keys[HIDUsage(kHIDUsage_KeyboardLANG5)] ?? false }
    var LANG6 : Bool { return keys[HIDUsage(kHIDUsage_KeyboardLANG6)] ?? false }
    var LANG7 : Bool { return keys[HIDUsage(kHIDUsage_KeyboardLANG7)] ?? false }
    var LANG8 : Bool { return keys[HIDUsage(kHIDUsage_KeyboardLANG8)] ?? false }
    var LANG9 : Bool { return keys[HIDUsage(kHIDUsage_KeyboardLANG9)] ?? false }
    var alternateErase : Bool { return keys[HIDUsage(kHIDUsage_KeyboardAlternateErase)] ?? false }
    var sysReqOrAttention : Bool { return keys[HIDUsage(kHIDUsage_KeyboardSysReqOrAttention)] ?? false }
    var cancel : Bool { return keys[HIDUsage(kHIDUsage_KeyboardCancel)] ?? false }
    var clear : Bool { return keys[HIDUsage(kHIDUsage_KeyboardClear)] ?? false }
    var prior : Bool { return keys[HIDUsage(kHIDUsage_KeyboardPrior)] ?? false }
    var returnKey : Bool { return keys[HIDUsage(kHIDUsage_KeyboardReturn)] ?? false }
    var separator : Bool { return keys[HIDUsage(kHIDUsage_KeyboardSeparator)] ?? false }
    var out : Bool { return keys[HIDUsage(kHIDUsage_KeyboardOut)] ?? false }
    var oper : Bool { return keys[HIDUsage(kHIDUsage_KeyboardOper)] ?? false }
    var clearOrAgain : Bool { return keys[HIDUsage(kHIDUsage_KeyboardClearOrAgain)] ?? false }
    var crSelOrProps : Bool { return keys[HIDUsage(kHIDUsage_KeyboardCrSelOrProps)] ?? false }
    var exSel : Bool { return keys[HIDUsage(kHIDUsage_KeyboardExSel)] ?? false }
    var leftControl : Bool { return keys[HIDUsage(kHIDUsage_KeyboardLeftControl)] ?? false }
    var leftShift : Bool { return keys[HIDUsage(kHIDUsage_KeyboardLeftShift)] ?? false }
    var leftAlt : Bool { return keys[HIDUsage(kHIDUsage_KeyboardLeftAlt)] ?? false }
    var leftGUI : Bool { return keys[HIDUsage(kHIDUsage_KeyboardLeftGUI)] ?? false }
    var rightControl : Bool { return keys[HIDUsage(kHIDUsage_KeyboardRightControl)] ?? false }
    var rightShift : Bool { return keys[HIDUsage(kHIDUsage_KeyboardRightShift)] ?? false }
    var rightAlt : Bool { return keys[HIDUsage(kHIDUsage_KeyboardRightAlt)] ?? false }
    var rightGUI : Bool { return keys[HIDUsage(kHIDUsage_KeyboardRightGUI)] ?? false }
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


let DEADZONE_THRESHOLD = 0.06

func gamepadEvent(_ context: UnsafeMutableRawPointer?, _ result: IOReturn, _ sender: UnsafeMutableRawPointer?, _ value: IOHIDValue) {
    let gamepad = context!.bindMemory(to: Gamepad.self, capacity: 1).pointee
    let element = IOHIDValueGetElement(value)
    let elementType = IOHIDElementGetType(element)
    let usage = IOHIDElementGetUsage(element)
    
    if elementType == kIOHIDElementTypeInput_Button {
        let pressed = (IOHIDValueGetIntegerValue(value) != 0)
        gamepad.buttons[usage] = pressed
    }
    else if elementType == kIOHIDElementTypeInput_Axis || elementType == kIOHIDElementTypeInput_Misc {
        
        let min = F64(IOHIDElementGetPhysicalMin(element))
        let max = F64(IOHIDElementGetPhysicalMax(element))
        let val = IOHIDValueGetScaledValue(value, U32(kIOHIDValueScaleTypePhysical))
        
        let numerator = val - min
        let denominator = max - min
        var scaledValue = (( numerator / denominator ) * 2.0) - 1.0
        if fabs(scaledValue) < DEADZONE_THRESHOLD {
            scaledValue = 0.0
        }
        
        gamepad.continuous[usage] = Float(scaledValue)
    }
    
    // TODO: Handle hatswitches correctly
    
}

func keyboardEvent(_ context: UnsafeMutableRawPointer?, _ result: IOReturn, _ sender: UnsafeMutableRawPointer?, _ value: IOHIDValue) {
    let element = IOHIDValueGetElement(value)
    let usage = IOHIDElementGetUsage(element)
    if usage < U32(kHIDUsage_KeyboardA) || usage > U32(kHIDUsage_KeyboardRightGUI) {
        return
    }
    
    let pressed = (IOHIDValueGetIntegerValue(value) != 0)
    controllers.keyboard.keys[usage] = pressed
}

func deviceAdded(_ inContext: UnsafeMutableRawPointer?, inResult: IOReturn, inSender: UnsafeMutableRawPointer?, deviceRef: IOHIDDevice!) {
    
    if IOHIDDeviceConformsTo(deviceRef, UInt32(kHIDPage_GenericDesktop), UInt32(kHIDUsage_GD_GamePad)) || IOHIDDeviceConformsTo(deviceRef, UInt32(kHIDPage_GenericDesktop), UInt32(kHIDUsage_GD_Joystick)) {
        
        print("gamepad added!")
        
        let gamepad = Gamepad(deviceRef)
        
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
        
        IOHIDDeviceRegisterInputValueCallback(deviceRef, gamepadEvent, &controllers.gamepads[idx])
        
    }
    else if IOHIDDeviceConformsTo(deviceRef, UInt32(kHIDPage_GenericDesktop), UInt32(kHIDUsage_GD_Keyboard)) || IOHIDDeviceConformsTo(deviceRef, UInt32(kHIDPage_GenericDesktop), UInt32(kHIDUsage_GD_Keypad)) {
        
        print("keyboard added!")
        
        IOHIDDeviceRegisterInputValueCallback(deviceRef, keyboardEvent, nil)

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
            break
        }
        gpIdx += 1
    }
        
    // Unregister value callback
    IOHIDDeviceRegisterInputValueCallback(inIOHIDDeviceRef, nil, nil)
    
}
