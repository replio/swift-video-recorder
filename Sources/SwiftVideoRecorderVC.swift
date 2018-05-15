//
//  Created by Максим Ефимов on 20.01.2018.
//

import UIKit
import AVFoundation

open class SwiftVideoRecorderVC: UIViewController, AVCaptureFileOutputRecordingDelegate {
    private static let MAX_DURATION = 60.0
    private static let INTERVAL = 1.0

    var captureSession: AVCaptureSession?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    let movieFileOutput = AVCaptureMovieFileOutput()
    var outputs = [URL]()
    var timer: Timer? = nil
    var time: Double = 0.0
    var isRecording: Bool = false

    public init() {
        super.init(nibName: nil, bundle: nil)
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
        print(#function)
        openCamera()
    }
    
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        UIApplication.shared.isStatusBarHidden = true
    }

    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.shared.isStatusBarHidden = false
    }

    override open func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }

    override open var prefersStatusBarHidden: Bool {
        return true
    }
    
    private func openCamera() {
        let videoAuthStatus = AVCaptureDevice.authorizationStatus(for: .video)
        let audioAuthStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        if videoAuthStatus == .authorized && audioAuthStatus == .authorized {
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
            
            captureSession?.addOutput(movieFileOutput)
            captureSession?.startRunning()
        }
        else if videoAuthStatus == .notDetermined {
            AVCaptureDevice.requestAccess(for: .video) { (granted) in
                if granted {
                    DispatchQueue.main.async {
                        self.openCamera()
                    }
                }
            }
        }
        else if videoAuthStatus == .authorized && audioAuthStatus == .notDetermined {
            AVCaptureDevice.requestAccess(for: .audio, completionHandler: { (granted) in
                if granted {
                    DispatchQueue.main.async {
                        self.openCamera()
                    }
                }
            })
        }
    }
    
    public func fileOutput(_ output:AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        print(#function, outputFileURL)
        outputs.append(outputFileURL)
        if !isRecording {
            mergeVideoClips()
        }
    }
    
    @objc func timerAction(){
        time+=SwiftVideoRecorderVC.INTERVAL
        print(#function, time)
        if time >= SwiftVideoRecorderVC.MAX_DURATION {
            stopRecording()
        }
    }
    
    public func startRecording() {
        print(#function)
        isRecording = true
        outputs.removeAll()
        timer = Timer.scheduledTimer(timeInterval: SwiftVideoRecorderVC.INTERVAL, target: self, selector: #selector(timerAction), userInfo: nil, repeats: true)
        time = 0.0
        resumeRecording()
    }
    
    public func stopRecording() {
        print(#function)
        isRecording = false
        if timer != nil {
            timer!.invalidate()
        }
        timer = nil
        movieFileOutput.stopRecording()
    }
    
    public func switchCamera() {
        print(#function)
        captureSession?.beginConfiguration()
        let newInput = try! AVCaptureDeviceInput(device: AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: isFacingFront() ? .back : .front).devices.first!)
        captureSession!.removeInput(captureSession!.inputs.first { input in
            (input as! AVCaptureDeviceInput).device.hasMediaType(.video)
         }!)
        captureSession!.addInput(newInput)
        captureSession?.commitConfiguration()
        
        if isRecording {
            resumeRecording()
        }
    }

    private func resumeRecording() {
        movieFileOutput.startRecording(to: URL(fileURLWithPath:generateNextOutputPath()) , recordingDelegate: self)
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

    private func mergeVideoClips() {
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
        
        let videoName = randomString(length: 5).appending(".mov")
        let videoExporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetMediumQuality)

        videoExporter?.outputURL = fileUrlForName(name: videoName)
        videoExporter?.shouldOptimizeForNetworkUse = true
        videoExporter?.outputFileType = AVFileType.mov
        videoExporter?.exportAsynchronously(completionHandler: { () -> Void in
            print("video exporting complete", self.fileUrlForName(name: videoName))
            DispatchQueue.main.async {
                self.complete(videoURL: self.fileUrlForName(name: videoName))
            }
        })
    }

    private func complete(videoURL: URL){
        print(#function)
        swiftVideoRecorder(didCompleteRecordingWithUrl: videoURL)
    }

    private func generateNextOutputPath() -> String {
        return NSTemporaryDirectory().appending(randomString(length: 5)).appending(".mov")
    }
    
    public func isFacingFront() -> Bool {
        return captureSession!.inputs.contains { input in
            (input as! AVCaptureDeviceInput).device.position == .front
         }
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
    
    private func randomString(length:Int) -> String {
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
    
    // Delegate methods
    open func swiftVideoRecorder(didCompleteRecordingWithUrl url: URL) {}
}
