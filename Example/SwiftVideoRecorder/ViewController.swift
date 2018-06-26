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

class ViewController: RecorderViewController, UIImagePickerControllerDelegate {
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
    var takePhotoButton: UIButton = {
        var button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("take photo", for: .normal)
        return button
    }()
    var lastPreview: UIImageView = {
        var view = UIImageView(frame: CGRect())
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    override init() {
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        recorder.videoListeners.append { (url) in
            self.saveToCameraRoll(url: url)
        }
        
        view.addSubview(recordButton)
        recordButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20).isActive = true
        recordButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        recordButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 1 / 3).isActive = true
        recordButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        recordButton.addTarget(self, action: #selector(recordButtonAction), for: .touchUpInside)
        
        view.addSubview(switchButton)
        switchButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8).isActive = true
        switchButton.widthAnchor.constraint(equalTo: recordButton.widthAnchor).isActive = true
        switchButton.heightAnchor.constraint(equalTo: recordButton.heightAnchor).isActive = true
        switchButton.bottomAnchor.constraint(equalTo: recordButton.bottomAnchor).isActive = true
        switchButton.addTarget(self, action: #selector(switchButtonAction), for: .touchUpInside)
        
        view.addSubview(takePhotoButton)
        takePhotoButton.leftAnchor.constraint(equalTo: view.leftAnchor, constant: -8).isActive = true
        takePhotoButton.heightAnchor.constraint(equalTo: recordButton.heightAnchor).isActive = true
        takePhotoButton.bottomAnchor.constraint(equalTo: recordButton.bottomAnchor).isActive = true
        takePhotoButton.widthAnchor.constraint(equalTo: recordButton.widthAnchor).isActive = true
        takePhotoButton.addTarget(self, action: #selector(takePhotoButtonAction), for: .touchUpInside)
        
        view.addSubview(lastPreview)
        lastPreview.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20).isActive = true
        lastPreview.topAnchor.constraint(equalTo: view.topAnchor, constant: 100).isActive = true
        lastPreview.heightAnchor.constraint(equalToConstant: 69).isActive = true
        lastPreview.widthAnchor.constraint(equalToConstant: 69).isActive = true
        lastPreview.contentMode = .scaleAspectFill
        lastPreview.clipsToBounds = true
        lastPreview.layer.cornerRadius = 5
    }
    
    @objc func takePhotoButtonAction() {
        if let image = recorder.takePhoto() {
            print(image)
            savePhotoToCameraRoll(image: image)
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
                    DispatchQueue.main.async {
                        self.lastPreview.image = self.generateThumbnail(url)
                    }
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
    
    func savePhotoToCameraRoll(image: UIImage) {
        if PHPhotoLibrary.authorizationStatus() == .authorized {
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }) { (saved, error) in
                if saved {
                    print(saved)
                    DispatchQueue.main.async {
                        self.lastPreview.image = image
                    }
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
                    self.savePhotoToCameraRoll(image: image)
                }
            }
        }
    }
    
    public func generateThumbnail(_ url : URL) -> UIImage? {
        let asset = AVURLAsset(url: url, options: nil)
        let imgGenerator = AVAssetImageGenerator(asset: asset)
        imgGenerator.appliesPreferredTrackTransform = true
        do {
            let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(0, 1), actualTime: nil)
            // !! check the error before proceeding
            let uiImage = UIImage(cgImage: cgImage)
            return uiImage
        }
        catch {
            print(error)
        }
        return nil
    }
}

