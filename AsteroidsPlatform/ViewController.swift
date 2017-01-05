//
//  ViewController.swift
//  Asteroids
//
//  Created by Sean Hickey on 12/5/16.
//  Copyright © 2016 Sean Hickey. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        view.wantsLayer = true;
        inputSystemInit()
        audioInit()
        
    }

    override func viewDidAppear() {
        beginRendering(view)
    }


}

