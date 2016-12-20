//
//  Platform.swift
//  Asteroids
//
//  Created by Sean Hickey on 12/19/16.
//  Copyright © 2016 Sean Hickey. All rights reserved.
//

open class GameMemory {
    open var permanentSize : Int = 0
    open var permanent : RawPtr! = nil
    
    open var transientSize : Int = 0
    open var transient : RawPtr! = nil
}
