//
//  ViewController.swift
//  SwiftVideoRecorder
//
//  Created by hapsidra on 05/15/2018.
//  Copyright (c) 2018 hapsidra. All rights reserved.
//

import UIKit
import SwiftVideoRecorder
import SwiftVideoPlayer
import AVKit

class ViewController: RecorderVC, RecorderDelegate {
    var recordButton: UIButton = {
        var button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("record", for: .normal)
        return button
    }()
    var switchButton: UIButton = {
        var button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("switch", for: .normal)
        return button
    }()
    
    init() {
        super.init(recorderType: .audioAndVideo)
        self.delegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(recordButton)
        view.addSubview(switchButton)
        
        recordButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20).isActive = true
        recordButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10).isActive = true
        recordButton.trailingAnchor.constraint(equalTo: view.centerXAnchor, constant: -10).isActive = true
        recordButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        switchButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10).isActive = true
        switchButton.leadingAnchor.constraint(equalTo: view.centerXAnchor, constant: 10).isActive = true
        switchButton.heightAnchor.constraint(equalTo: recordButton.heightAnchor).isActive = true
        switchButton.bottomAnchor.constraint(equalTo: recordButton.bottomAnchor).isActive = true
        
        recordButton.addTarget(self, action: #selector(recordButtonAction), for: .touchUpInside)
        switchButton.addTarget(self, action: #selector(switchButtonAction), for: .touchUpInside)
    }
    
    func recorder(completeWithUrl url: URL) {
        self.present(SwiftVideoPlayerVC([Item(videoURL: url, previewURL: nil)], videoGravity: .resizeAspectFill), animated: true, completion: nil)
    }
    
    @objc func recordButtonAction() {
        print(#function)
        if self.isRecording {
            self.stopRecording()
        }
        else {
            self.startRecording()
        }
        recordButton.setTitle(self.isRecording ? "stop" : "record", for: .normal)
    }
    
    @objc func switchButtonAction() {
        //self.switchCamera()
        self.show(UIViewController(nibName: nil, bundle: nil), sender: self)
    }
    var cnt = 0
    override func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        super.captureOutput(output, didOutput: sampleBuffer, from: connection)
        cnt+=1
        print("hello", cnt)
    }
}

