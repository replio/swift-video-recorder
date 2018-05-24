//
//  Created by Максим Ефимов on 20.01.2018.
//

import UIKit
import AVFoundation

public protocol RecorderDelegate {
    func recorder(completeWithUrl url: URL)
}

public enum WriterType: String {
    case audioAndVideo, onlyVideo, onlyAudio
}

open class RecorderVC: UIViewController {
    public var delegate: RecorderDelegate?
    public private(set) var isRecording: Bool = false
    public private(set) var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    public var captureSession: AVCaptureSession?
    
    private var assetWriter: AVAssetWriter? = nil
    private var audioInput: AVAssetWriterInput? = nil
    private var videoInput: AVAssetWriterInput? = nil
    
    private var startTime: CMTime = kCMTimeInvalid
    private var duration: CMTime = kCMTimeZero
    
    private var writerType: WriterType = .audioAndVideo

    public init(recorderType: WriterType = .audioAndVideo) {
        super.init(nibName: nil, bundle: nil)
        self.writerType = recorderType
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
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
                captureSession!.beginConfiguration()
                let frontCaptureDeviceInput = try AVCaptureDeviceInput(device:captureDeviceVideoFront!)
                let audioCaptureDeviceInput = try AVCaptureDeviceInput(device:captureDeviceAudio!)
                captureSession!.addInput(frontCaptureDeviceInput)
                captureSession!.addInput(audioCaptureDeviceInput)
            } catch {
                print(error)
            }
            
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
            videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
            videoPreviewLayer?.frame = view.layer.bounds
            //добавляем лэйер превью перед всеми лэйэрами
            if let sublayers = view.layer.sublayers, !sublayers.isEmpty {
                view.layer.insertSublayer(videoPreviewLayer!, below: sublayers[0])
            }
            else {
                view.layer.addSublayer(videoPreviewLayer!)
            }
            
            let videoOutput = AVCaptureVideoDataOutput()
            videoOutput.videoSettings = [
                String(kCVPixelBufferPixelFormatTypeKey) : Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)
            ]
            videoOutput.alwaysDiscardsLateVideoFrames = false
            if captureSession!.canAddOutput(videoOutput) {
                captureSession!.addOutput(videoOutput)
            }
            else {
                print("can't add video output")
            }
            videoOutput.connections.forEach { (connection) in
                if connection.isVideoOrientationSupported {
                    connection.videoOrientation = AVCaptureVideoOrientation.portrait
                }
                if connection.isVideoMirroringSupported {
                    connection.isVideoMirrored = true
                }
            }
            
            let audioOutput = AVCaptureAudioDataOutput()
            audioOutput.recommendedAudioSettingsForAssetWriter(writingTo: .mov)
            if captureSession!.canAddOutput(audioOutput) {
                captureSession!.addOutput(audioOutput)
            }
            else {
                print("can't add audio output")
            }
            
            captureSession?.commitConfiguration()
            
            let queue = DispatchQueue(label: "output.queue")
            videoOutput.setSampleBufferDelegate(self, queue: queue)
            audioOutput.setSampleBufferDelegate(self, queue: queue)
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
    
    public func startRecording() {
        print(#function, writerType.rawValue)
        if !isRecording {
            let outputURL = URL(fileURLWithPath: NSTemporaryDirectory().appending(UUID().uuidString).appending(".mp4"))
            do {
                assetWriter = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
            } catch {
                print(error)
            }
            assetWriter!.shouldOptimizeForNetworkUse = true
            if writerType == .audioAndVideo || writerType == .onlyVideo {
                let settings: [String: Any] = [AVVideoCodecKey: AVVideoCodecH264, AVVideoHeightKey: 800, AVVideoWidthKey: 450]
                videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
                videoInput!.expectsMediaDataInRealTime = true
                if assetWriter!.canAdd(videoInput!) {
                    assetWriter!.add(videoInput!)
                } else {
                    videoInput = nil
                    print("recorder, could not add video input to session")
                }
            }
            if writerType == .audioAndVideo || writerType == .onlyAudio {
                let settings: [String: Any] = [AVFormatIDKey: kAudioFormatMPEG4AAC, AVSampleRateKey: 44100.0, AVNumberOfChannelsKey: 1]
                audioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: settings)
                audioInput!.expectsMediaDataInRealTime = true
                if assetWriter!.canAdd(audioInput!) {
                    assetWriter!.add(audioInput!)
                } else {
                    audioInput = nil
                    print("recorder, could not add audio input to session")
                }
            }
            isRecording = true
        }
    }
    
    public func stopRecording() {
        print(#function)
        if isRecording {
            if startTime.isValid {
                isRecording = false
                videoInput?.markAsFinished()
                audioInput?.markAsFinished()
                assetWriter!.endSession(atSourceTime: duration + startTime)
                startTime = kCMTimeInvalid
                duration = kCMTimeZero
                assetWriter!.finishWriting {
                    DispatchQueue.main.async {
                        self.delegate?.recorder(completeWithUrl: self.assetWriter!.outputURL)
                    }
                }
            }
            else {
                //если запись началась, но startSession еще не вызван, повторяем это метод с небольшой паузой
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    self.stopRecording()
                }
            }
        }
    }
    
    public func switchCamera() {
        print(#function)
        captureSession!.beginConfiguration()
        let newInput = try! AVCaptureDeviceInput(device: AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: isFacingFront() ? .back : .front).devices.first!)
        captureSession!.removeInput(captureSession!.inputs.first { input in
            (input as! AVCaptureDeviceInput).device.hasMediaType(.video)
         }!)
        captureSession!.addInput(newInput)
        captureSession!.outputs.forEach { (output) in
            output.connections.forEach { (connection) in
                if connection.isVideoOrientationSupported {
                    connection.videoOrientation = AVCaptureVideoOrientation.portrait
                }
                if connection.isVideoMirroringSupported {
                    connection.isVideoMirrored = isFacingFront()
                }
            }
        }
        captureSession!.commitConfiguration()
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
    }
}

extension RecorderVC: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    open func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        /*
        if let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer) {
            if let audioStreamBasicDescription = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription) {
                print(audioStreamBasicDescription.pointee)
            }
        }
        */
    
        if self.isRecording {
            let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            if !self.startTime.isValid {
                assetWriter!.startWriting()
                assetWriter!.startSession(atSourceTime: timestamp)
                startTime = timestamp
            }
            duration = timestamp - startTime
            if output is AVCaptureVideoDataOutput {
                if videoInput != nil && videoInput!.isReadyForMoreMediaData {
                    videoInput!.append(sampleBuffer)
                }
            }
            else if output is AVCaptureAudioDataOutput {
                if audioInput != nil && audioInput!.isReadyForMoreMediaData {
                    audioInput!.append(sampleBuffer)
                }
            }
        }
    }
}
