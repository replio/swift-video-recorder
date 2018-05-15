//
//  ViewController.swift
//  SwiftVideoRecorder
//
//  Created by hapsidra on 05/15/2018.
//  Copyright (c) 2018 hapsidra. All rights reserved.
//

import UIKit
import SwiftVideoRecorder

class ViewController: SwiftVideoRecorderVC {

    override init() {
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func swiftVideoRecorder(didCompleteRecordingWithUrl url: URL) {
        print(#function)
    }

}

