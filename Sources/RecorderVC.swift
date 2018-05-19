//
//  Created by Максим Ефимов on 20.01.2018.
//

import UIKit
import AVFoundation
public protocol RecorderDelegate {
    func swiftVideoRecorder(didCompleteRecordingWithUrl url: URL)
}
open class RecorderVC: UIViewController, AVCaptureFileOutputRecordingDelegate {
    private static let MAX_DURATION = 60.0
    private static let INTERVAL = 1.0

    var captureSession: AVCaptureSession?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    let movieFileOutput = AVCaptureMovieFileOutput()
    var outputs = [URL]()
    var timer: Timer? = nil
    var time: Double = 0.0
    public var delegate: RecorderDelegate?
    public private(set) var isRecording: Bool = false

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
    }

    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    override open func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    private func openCamera() {
        let videoAuthStatus = AVCaptureDevice.authorizationStatus(for: .video)
        let audioAuthStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        if videoAuthStatus == .authorized && audioAuthStatus == .authorized {
            let captureDeviceVideoFront = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .front).devices.first
            let captureDeviceAudio = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInMicrophone], mediaType: .audio, position: .unspecified).devices.first
            
            do {
                captureSession = AVCaptureSession()
                captureSession?.beginConfiguration()
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
            //добавляем layer превью перед всеми лэйэрами
            if let sublayers = view.layer.sublayers, !sublayers.isEmpty {
                view.layer.insertSublayer(videoPreviewLayer!, below: sublayers[0])
            }
            else {
                view.layer.addSublayer(videoPreviewLayer!)
            }
            //captureSession?.addOutput(movieFileOutput)
            
            let output = AVCaptureVideoDataOutput()
            output.videoSettings = [
                String(kCVPixelBufferPixelFormatTypeKey) : Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)
            ]
            
            output.alwaysDiscardsLateVideoFrames = true
            
            if (captureSession?.canAddOutput(output))! {
                captureSession?.addOutput(output)
            }
            else {
                print("can't add output")
            }
            captureSession?.commitConfiguration()
            
            let queue = DispatchQueue(label: "output.queue")
            output.setSampleBufferDelegate(self, queue: queue)
            
            
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
    
    @objc func timerAction() {
        time+=RecorderVC.INTERVAL
        print(#function, time)
        if time >= RecorderVC.MAX_DURATION {
            stopRecording()
        }
    }
    
    public func startRecording() {
        print(#function)
        if !isRecording {
            isRecording = true
            outputs.removeAll()
            timer = Timer.scheduledTimer(timeInterval: RecorderVC.INTERVAL, target: self, selector: #selector(timerAction), userInfo: nil, repeats: true)
            time = 0.0
            resumeRecording()
        }
    }
    
    public func stopRecording() {
        print(#function)
        if isRecording {
            isRecording = false
            if timer != nil {
                timer!.invalidate()
            }
            timer = nil
            movieFileOutput.stopRecording()
        }
    }
    
    private func resumeRecording() {
        let path = NSTemporaryDirectory().appending(UUID().uuidString).appending(".mov")
        movieFileOutput.startRecording(to: URL(fileURLWithPath: path) , recordingDelegate: self)
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
    
    public func isFacingFront() -> Bool {
        return captureSession!.inputs.contains { input in
            (input as! AVCaptureDeviceInput).device.position == .front
        }
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
        
        let videoName = UUID().uuidString.appending(".mov")
        let videoExporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetMediumQuality)

        let outputURL = URL(fileURLWithPath: NSTemporaryDirectory().appending(videoName))
        videoExporter?.outputURL = outputURL
        videoExporter?.shouldOptimizeForNetworkUse = true
        videoExporter?.outputFileType = AVFileType.mov
        videoExporter?.exportAsynchronously(completionHandler: { () -> Void in
            print("video exporting complete", outputURL)
            DispatchQueue.main.async {
                self.delegate?.swiftVideoRecorder(didCompleteRecordingWithUrl: outputURL)
            }
        })
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
}

extension RecorderVC: AVCaptureVideoDataOutputSampleBufferDelegate {
    open func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        print("pod")
    }
}
