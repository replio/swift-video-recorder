//
//  Created by Максим Ефимов on 20.01.2018.
//

import UIKit
import AVFoundation

public protocol RecorderDelegate {
    func recorder(completeWithUrl url: URL)
}

open class RecorderVC: UIViewController {
    public var delegate: RecorderDelegate?
    public private(set) var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    public private(set) var isRecording: Bool = false
    
    private var captureSession: AVCaptureSession?
    
    private var assetWriter: AVAssetWriter!
    private var audioInput: AVAssetWriterInput!
    private var videoInput: AVAssetWriterInput!
    
    private var startTime: CMTime = kCMTimeInvalid
    private var duration: CMTime = kCMTimeZero

    public init() {
        super.init(nibName: nil, bundle: nil)
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
            //добавляем лэйер превью перед всеми лэйэрами
            if let sublayers = view.layer.sublayers, !sublayers.isEmpty {
                view.layer.insertSublayer(videoPreviewLayer!, below: sublayers[0])
            }
            else {
                view.layer.addSublayer(videoPreviewLayer!)
            }
            
            let output = AVCaptureVideoDataOutput()
            output.videoSettings = [
                String(kCVPixelBufferPixelFormatTypeKey) : Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)
            ]
            
            output.alwaysDiscardsLateVideoFrames = false
            
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
    
    public func startRecording() {
        print(#function)
        if !isRecording {
            let outputURL = URL(fileURLWithPath: NSTemporaryDirectory().appending(UUID().uuidString).appending(".mov"))
            do {
                assetWriter = try AVAssetWriter(outputURL: outputURL, fileType: .mov)
                assetWriter.shouldOptimizeForNetworkUse = true
                let settings: [String: Any] = [AVVideoCodecKey: AVVideoCodecH264, AVVideoHeightKey: 450, AVVideoWidthKey: 800]
                videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
                videoInput.transform = videoInput.transform.rotated(by: .pi / 2)
                videoInput.transform = videoInput.transform.scaledBy(x: 1, y: -1)
                videoInput.expectsMediaDataInRealTime = true
                if assetWriter.canAdd(videoInput) {
                    assetWriter.add(videoInput)
                } else {
                    print("recorder, could not add video input to session")
                }
                audioInput = AVAssetWriterInput(mediaType: .video, outputSettings: nil)
                audioInput.expectsMediaDataInRealTime = true
                if assetWriter.canAdd(audioInput) {
                    assetWriter.add(audioInput)
                } else {
                    print("recorder, could not add audio input to session")
                }
            } catch {
                print(error)
            }
            isRecording = true
        }
    }
    
    public func stopRecording() {
        print(#function)
        if isRecording {
            isRecording = false
            assetWriter.endSession(atSourceTime: duration + startTime)
            startTime = kCMTimeInvalid
            duration = kCMTimeZero
            assetWriter.finishWriting {
                DispatchQueue.main.async {
                    self.delegate?.recorder(completeWithUrl: self.assetWriter.outputURL)
                }
            }
        }
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

extension RecorderVC: AVCaptureVideoDataOutputSampleBufferDelegate {
    open func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        
        if self.isRecording && !self.startTime.isValid {
            startTime = timestamp
            assetWriter.startWriting()
            assetWriter.startSession(atSourceTime: timestamp)
        }
        duration = timestamp - startTime
        if self.isRecording && videoInput.isReadyForMoreMediaData {
            videoInput.append(sampleBuffer)
        }
    }
}
