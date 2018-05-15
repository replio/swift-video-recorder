//
//  ViewController.swift
//  xprojects-without-storyboard
//
//  Created by Максим Ефимов on 20.01.2018.
//  Copyright © 2018 Platforma. All rights reserved.
//

import UIKit
import AVFoundation

public class RecorderVC: UIViewController, AVCaptureFileOutputRecordingDelegate {
    private static let MAX_DURATION = 60.0
    private static let INTERVAL = 1.0
    var progressView: UIProgressView = {
        var bar = UIProgressView(progressViewStyle: .bar)
        bar.translatesAutoresizingMaskIntoConstraints = false
        bar.backgroundColor = .harmony2_1
        bar.alpha = 0.5
        bar.tintColor = .color2
        return bar
    }()
    var recordButton: ActionButton2 = {
        var button = ActionButton2()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(NSLocalizedString("record", comment: ""), for: .normal)
        button.setTitle("", for: .disabled)
        button.addTarget(self, action: #selector(recordButtonAction), for: .touchUpInside)
        return button
    }()
    var closeButton: CloseButton = {
        var button = CloseButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(closeButtonAction), for: .touchUpInside)
        button.alpha = 0.75
        return button
    }()
    var switchButton: UIButton = {
        var button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .harmony2_1
        button.tintColor = .white
        button.setImage(UIImage(named: "camera_switch"), for: .normal)
        button.addTarget(self, action: #selector(switchButtonAction), for: .touchUpInside)
        return button
    }()
    var topGradientView: UIView = {
        var view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    var loadingView: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(activityIndicatorStyle: .white)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.hidesWhenStopped = true
        return view
    }()

    var captureSession: AVCaptureSession?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    let videoOutput = AVCaptureMovieFileOutput()
    var outputs = [URL]()
    var timer: Timer? = nil
    var time: Double = 0.0
    var completeListener: ((URL, URL, URL) -> ())!

    init(completeListener: @escaping (URL, URL, URL) -> ()) {
        super.init(nibName: nil, bundle: nil)
        self.completeListener = completeListener
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        print(#function)
        let captureDeviceVideoFront = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .front).devices.first
        let captureDeviceAudio = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInMicrophone], mediaType: .audio, position: .unspecified).devices.first
        
        do {
            captureSession = AVCaptureSession()
            let frontCaptureDeviceInput = try AVCaptureDeviceInput(device:captureDeviceVideoFront!)
            let audioCaptureDeviceInput = try AVCaptureDeviceInput(device:captureDeviceAudio!)
            captureSession?.addInput(frontCaptureDeviceInput)
            captureSession?.addInput(audioCaptureDeviceInput)
        } catch {
            print(error)
        }
        
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
        videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        videoPreviewLayer?.frame = view.layer.bounds
        view.layer.addSublayer(videoPreviewLayer!)

        captureSession?.addOutput(videoOutput)
        captureSession?.startRunning()

        setupViews()
    }
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        UIApplication.shared.isStatusBarHidden = true
    }

    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.shared.isStatusBarHidden = false
    }

    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        switchButton.makeCircle()
        topGradientView.addGradient([UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0).cgColor, UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.3).cgColor], [0.0, 1.0], CGPoint(x: 0, y: 1), CGPoint(x: 0, y: 0))
    }

    override public var prefersStatusBarHidden: Bool {
        return true
    }

    func setupViews() {
        view.addSubview(topGradientView)
        view.addSubview(closeButton)
        view.addSubview(progressView)
        view.addSubview(recordButton)
        view.addSubview(switchButton)
        recordButton.addSubview(loadingView)

        progressView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        progressView.heightAnchor.constraint(equalToConstant: 0.69).isActive = true

        recordButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        recordButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -16).isActive = true
        recordButton.widthAnchor.constraint(equalToConstant: 100).isActive = true

        switchButton.heightAnchor.constraint(equalTo: recordButton.heightAnchor, multiplier: 1).isActive = true
        switchButton.widthAnchor.constraint(equalTo: switchButton.heightAnchor, multiplier: 1).isActive = true
        switchButton.leadingAnchor.constraint(equalTo: recordButton.trailingAnchor, constant: 9).isActive = true
        switchButton.centerYAnchor.constraint(equalTo: recordButton.centerYAnchor).isActive = true

        closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -4).isActive = true
        closeButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 8).isActive = true
        closeButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        closeButton.widthAnchor.constraint(equalTo: closeButton.heightAnchor, multiplier: 1).isActive = true

        topGradientView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        topGradientView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        topGradientView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        topGradientView.heightAnchor.constraint(equalToConstant: 200).isActive = true

        loadingView.centerYAnchor.constraint(equalTo: recordButton.centerYAnchor).isActive = true
        loadingView.centerXAnchor.constraint(equalTo: recordButton.centerXAnchor).isActive = true
    }
    
    public func fileOutput(_ output:AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        print(#function, outputFileURL)
        outputs.append(outputFileURL)
        if !isRecording() {
            mergeVideoClips()
        }
    }
    
    @objc func recordButtonAction(sender:UIButton!) {
        print(#function)
        if isRecording() {
            stopRecording()
        }
        else{
            outputs.removeAll()
            //FileManager.default.clearTmpDirectory()
            timer = Timer.scheduledTimer(timeInterval: RecorderVC.INTERVAL, target: self, selector: #selector(timerAction), userInfo: nil, repeats: true)
            time = 0.0
            resumeRecording()
        }
    }
    
    @objc func switchButtonAction(sender:UIButton!){
        print(#function)
        captureSession?.beginConfiguration()
        let newInput = try! AVCaptureDeviceInput(device: AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: isFacingFront() ? .back : .front).devices.first!)
        captureSession!.removeInput(captureSession!.inputs.first { input in
            (input as! AVCaptureDeviceInput).device.hasMediaType(.video)
         }!)
        captureSession!.addInput(newInput)
        captureSession?.commitConfiguration()
        
        if isRecording() {
            resumeRecording()
        }
    }

    @objc func closeButtonAction() {
        print(#function)
        print(#function)
        if timer != nil {
            timer!.invalidate()
        }
        timer = nil
        videoOutput.stopRecording()
        self.dismiss(animated: true, completion: nil)
    }

    @objc func timerAction(){
        time+=RecorderVC.INTERVAL
        print(#function, time)
        progressView.setProgress(Float(time / RecorderVC.MAX_DURATION), animated: true)
        if time >= RecorderVC.MAX_DURATION {
            stopRecording()
        }
    }

    func resumeRecording(){
        recordButton.setTitle(NSLocalizedString("stop", comment: ""), for: .normal)
        videoOutput.startRecording(to: URL(fileURLWithPath:generateNextOutputPath()) , recordingDelegate: self)
    }
    
    func stopRecording(){
        print(#function)
        if timer != nil {
            timer!.invalidate()
        }
        timer = nil
        recordButton.isEnabled = false
        loadingView.startAnimating()
        videoOutput.stopRecording()
    }

    private func generateThumbnail(_ url : URL) -> UIImage? {
        print(#function)
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

    func mergeVideoClips() {
        let composition = AVMutableComposition()
        let videoTrack = composition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: kCMPersistentTrackID_Invalid)
        let audioTrack = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        var time: Double = 0.0
        
        for video in outputs {
            let asset = AVAsset(url: video)

            if let videoAssetTrack = asset.tracks(withMediaType: AVMediaType.video).first, let audioAssetTrack = asset.tracks(withMediaType: AVMediaType.audio).first {
                let atTime = CMTime(seconds:time, preferredTimescale: 0)
                do {
                    try videoTrack?.insertTimeRange(CMTimeRangeMake(kCMTimeZero, asset.duration), of: videoAssetTrack, at: atTime)
                    try audioTrack?.insertTimeRange(CMTimeRangeMake(kCMTimeZero, asset.duration), of: audioAssetTrack, at: atTime)
                } catch {
                    print("something bad happend I don't want to talk about it")
                }
                
                time+=asset.duration.seconds
            }
        }

        videoTrack?.preferredTransform = (videoTrack?.preferredTransform.rotated(by: .pi / 2))!
        videoTrack?.preferredTransform = (videoTrack?.preferredTransform.scaledBy(x: 1, y: -1))!
        //if outputs.count == 1 && isFacingFront() {
        //    videoTrack?.preferredTransform = (videoTrack?.preferredTransform.scaledBy(x: 1, y: -1))!
        //}
        //else {
        //    self.print("mirroring is unavailable")
        //}

        let videoName = randomString(length: 5).appending(".mov")
        let audioName = randomString(length: 5).appending(".m4a")
        let videoExporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetMediumQuality)
        let audioExporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A)

        var videoComplete = false
        var audioComplete = false

        videoExporter?.outputURL = fileUrlForName(name: videoName)
        videoExporter?.shouldOptimizeForNetworkUse = true
        videoExporter?.outputFileType = AVFileType.mov
        videoExporter?.exportAsynchronously(completionHandler: { () -> Void in
            videoComplete = true
            print("video exporting complete", self.fileUrlForName(name: videoName))
            if audioComplete {
                self.complete(videoURL: self.fileUrlForName(name: videoName), audioURL: self.fileUrlForName(name: audioName))
            }
        })
        
        audioExporter?.outputURL = fileUrlForName(name: audioName)
        audioExporter?.shouldOptimizeForNetworkUse = true
        audioExporter?.outputFileType = AVFileType.m4a
        audioExporter?.exportAsynchronously(completionHandler: { () -> Void in
            audioComplete = true
            print("audio exporting complete", self.fileUrlForName(name: audioName))
            if videoComplete {
                self.complete(videoURL: self.fileUrlForName(name: videoName), audioURL: self.fileUrlForName(name: audioName))
            }
        })
    }

    func complete(videoURL: URL, audioURL: URL){
        print(#function)
        DispatchQueue.main.async {
            let convertedAudioName = randomString(length: 5).appending(".wav")
            self.convertAudio(audioURL, outputURL: self.fileUrlForName(name: convertedAudioName))
            if let preview = self.generateThumbnail(videoURL), let previewData = UIImageJPEGRepresentation(preview, 1) {
                let previewName = randomString(length: 5).appending(".jpg")
                do {
                    try previewData.write(to: self.fileUrlForName(name: previewName))
                    self.dismiss(animated: true)
                    self.completeListener(videoURL, self.fileUrlForName(name: convertedAudioName), self.fileUrlForName(name: previewName))
                }
                catch {
                    print(error)
                }
            }
            else {
                print("thumbnail generating error")
            }
        }
    }

    func generateNextOutputPath() -> String {
        return NSTemporaryDirectory().appending(randomString(length: 5)).appending(".mov")
    }
    
    func isFacingFront() -> Bool {
        return captureSession!.inputs.contains { input in
            (input as! AVCaptureDeviceInput).device.position == .front
         }
    }
    
    func isRecording() -> Bool {
        return recordButton.titleLabel!.text == NSLocalizedString("stop", comment: "") && recordButton.isEnabled
    }

    //Convert from m4a to wav, готовый код
    fileprivate func convertAudio(_ url: URL, outputURL: URL) {
        var error : OSStatus = noErr
        var destinationFile: ExtAudioFileRef? = nil
        var sourceFile : ExtAudioFileRef? = nil

        var srcFormat : AudioStreamBasicDescription = AudioStreamBasicDescription()
        var dstFormat : AudioStreamBasicDescription = AudioStreamBasicDescription()

        ExtAudioFileOpenURL(url as CFURL, &sourceFile)

        var thePropertySize: UInt32 = UInt32(MemoryLayout.stride(ofValue: srcFormat))

        ExtAudioFileGetProperty(sourceFile!,
                kExtAudioFileProperty_FileDataFormat,
                &thePropertySize, &srcFormat)

        dstFormat.mSampleRate = 44100  //Set sample rate
        dstFormat.mFormatID = kAudioFormatLinearPCM
        dstFormat.mChannelsPerFrame = 1
        dstFormat.mBitsPerChannel = 16
        dstFormat.mBytesPerPacket = 2 * dstFormat.mChannelsPerFrame
        dstFormat.mBytesPerFrame = 2 * dstFormat.mChannelsPerFrame
        dstFormat.mFramesPerPacket = 1
        dstFormat.mFormatFlags = kLinearPCMFormatFlagIsPacked | kAudioFormatFlagIsSignedInteger

        // Create destination file

        error = ExtAudioFileCreateWithURL(
                outputURL as CFURL,
                kAudioFileWAVEType,
                &dstFormat,
                nil,
                AudioFileFlags.eraseFile.rawValue,
                &destinationFile)
        print("Error 1 in convertAudio: \(error.description)")

        error = ExtAudioFileSetProperty(sourceFile!,
                kExtAudioFileProperty_ClientDataFormat,
                thePropertySize,
                &dstFormat)
        print("Error 2 in convertAudio: \(error.description)")

        error = ExtAudioFileSetProperty(destinationFile!,
                kExtAudioFileProperty_ClientDataFormat,
                thePropertySize,
                &dstFormat)
        print("Error 3 in convertAudio: \(error.description)")

        let bufferByteSize : UInt32 = 32768
        var srcBuffer = [UInt8](repeating: 0, count: 32768)
        var sourceFrameOffset : ULONG = 0

        while(true){
            var fillBufList = AudioBufferList(
                    mNumberBuffers: 1,
                    mBuffers: AudioBuffer(
                            mNumberChannels: 2,
                            mDataByteSize: UInt32(srcBuffer.count),
                            mData: &srcBuffer
                    )
            )
            var numFrames : UInt32 = 0

            if(dstFormat.mBytesPerFrame > 0){
                numFrames = bufferByteSize / dstFormat.mBytesPerFrame
            }

            error = ExtAudioFileRead(sourceFile!, &numFrames, &fillBufList)
            print("Error 4 in convertAudio: \(error.description)")

            if(numFrames == 0){
                error = noErr;
                break;
            }

            sourceFrameOffset += numFrames
            error = ExtAudioFileWrite(destinationFile!, numFrames, &fillBufList)
            print("Error 5 in convertAudio: \(error.description)")
        }

        error = ExtAudioFileDispose(destinationFile!)
        print("Error 6 in convertAudio: \(error.description)")
        error = ExtAudioFileDispose(sourceFile!)
        print("Error 7 in convertAudio: \(error.description)")
    }

    deinit {
        print(#function)
        captureSession = nil
        videoPreviewLayer = nil
        outputs.removeAll()
        if timer != nil {
            timer!.invalidate()
        }
        timer = nil
        time = 0.0
    }

    private func fileUrlForName(name: String) -> URL {
        return URL(fileURLWithPath: NSTemporaryDirectory().appending(name))
    }
}

func randomString(length:Int) -> String {
    let characters:NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    let stringLength = UInt32(characters.length)
    var randomString = ""
    for _ in 0 ..< length {
        let rand = arc4random_uniform(stringLength)
        var nextChar = characters.character(at:Int(rand))
        randomString += NSString(characters: &nextChar, length:1) as String
    }
    return randomString
}
