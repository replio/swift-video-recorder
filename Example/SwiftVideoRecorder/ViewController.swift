//
//  ViewController.swift
//  SwiftVideoRecorder
//
//  Created by hapsidra on 05/15/2018.
//  Copyright (c) 2018 hapsidra. All rights reserved.
//

import UIKit
import SwiftVideoRecorder
import AVKit
import Photos

class ViewController: RecorderViewController {
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
    
    override init() {
        super.init()
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
        
        recorder.videoListeners.append { (url) in
            self.saveToCameraRoll(url: url)
        }
    }
    
    @objc func recordButtonAction() {
        print(#function)
        if recorder.isRecording {
            recorder.stopRecording()
        }
        else {
            recorder.startRecording()
        }
        recordButton.setTitle(recorder.isRecording ? "stop" : "record", for: .normal)
    }
    
    @objc func switchButtonAction() {
        recorder.isFacingFront = !recorder.isFacingFront
    }
    
    func saveToCameraRoll(url: URL) {
        if PHPhotoLibrary.authorizationStatus() == .authorized {
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            }) { (saved, error) in
                if saved {
                    print(saved)
                } else if error != nil {
                    print(error!.localizedDescription)
                }
            }
        }
        else if PHPhotoLibrary.authorizationStatus() == .denied {
            let alertController = UIAlertController(title: nil, message: NSLocalizedString("photo_library_permission", comment: ""), preferredStyle: .alert)
            let settingsAction = UIAlertAction(title: NSLocalizedString("settings", comment: ""), style: .default) { (_) -> Void in
                guard let settingsUrl = URL(string: UIApplicationOpenSettingsURLString) else {
                    return
                }
                if UIApplication.shared.canOpenURL(settingsUrl) {
                    UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                        print("Settings opened: \(success)")
                    })
                }
            }
            let cancelAction = UIAlertAction(title: NSLocalizedString("close", comment: ""), style: .cancel, handler: nil)
            alertController.addAction(cancelAction)
            alertController.addAction(settingsAction)
            self.present(alertController, animated: true)
        }
        else {
            PHPhotoLibrary.requestAuthorization { status in
                if status == .authorized {
                    self.saveToCameraRoll(url: url)
                }
            }
        }
    }
}

