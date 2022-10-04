//
//  ViewController.swift
//  retina
//
//  Created by George Morariu on 6/4/21.
//  Copyright © 2021 George Morariu. All rights reserved.
//

import UIKit
import AVFoundation

class CaptureVideoPreviewController: UIViewController, AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        toggleFlash()
        UISaveVideoAtPathToSavedPhotosAlbum(outputFileURL.path, nil, nil, nil)
        
    }
    
    var session: AVCaptureSession?
    let output = AVCaptureMovieFileOutput()
    let preview = AVCaptureVideoPreviewLayer()
    var originalPlayer : Player? = nil
    var modifiedPlayer : Player? = nil
    var videoUrl: URL?
    
        /*let recordButton = UIButton(type: UIButton.ButtonType.custom) as UIButton
    recordButton.frame = CGRectMake(100, 100, 100, 100)
    recordButton.setImage(image, forState: .Normal)
    button.addTarget(self, action: "btnTouched:", forControlEvents:.TouchUpInside)
    self.view.addSubview(button)
    */
 
    private let recordButton: UIButton = {
        let image = UIImage(named: "record") as UIImage?
        let button = UIButton(type: UIButton.ButtonType.custom)
        button.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        button.setImage(image, for: .normal)
        return button
    }()
    
    private let faceContour: UIImageView = {
        let image = UIImage(named: "face_contour") as UIImage?
        let imageView = UIImageView(image: image)
        imageView.frame = CGRect(x: 0, y: 0, width: 160, height: 200)
        return imageView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        checkCameraPermissions()
        self.view.layer.addSublayer(preview)
        self.view.addSubview(faceContour)
        faceContour.translatesAutoresizingMaskIntoConstraints = false
        faceContour.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        faceContour.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        faceContour.widthAnchor.constraint(equalToConstant: view.frame.width).isActive = true
        //faceContour.heightAnchor.constraint(equalToConstant: view.frame.width).isActive = true
        self.view.addSubview(recordButton)
        recordButton.addTarget(self, action: #selector(didTapRecord), for: .touchUpInside)
        output.maxRecordedDuration = CMTimeMake(value: 3, timescale: 1)
        //videoUrl = tempURL()
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //videoUrl = tempURL()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        session?.stopRunning()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        preview.frame = view.bounds
        //faceContour.center = CGPoint(x: view.frame.size.width/2, y: 100)
        recordButton.center = CGPoint(x: view.frame.size.width/2, y: view.frame.size.height-50)
    }
    
    private func checkCameraPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        
        case .notDetermined:
            //Request permission
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { [weak self] granted in
                guard granted else {
                    return
                }
                DispatchQueue.main.async {
                    self?.setUpCamera()
                }
            })
        case .restricted:
            break
        case .denied:
            break
        case .authorized:
            setUpCamera()
        @unknown default:
            break
        }
    }
    
    private func setUpCamera() {
        let session = AVCaptureSession()
        if let device = AVCaptureDevice.default(for: .video) {
            do {
                let input = try AVCaptureDeviceInput(device: device)
                if session.canAddInput(input) {
                    session.addInput(input)
                }
                if session.canAddOutput(output) {
                    session.addOutput(output)
                }
                
                preview.videoGravity = .resizeAspectFill
                preview.session = session
                session.startRunning()
                self.session = session
                
                
            } catch {
                print(error)
            }
        }
    }
    
    @objc private func didTapRecord() {
        let directory = URL(fileURLWithPath: NSTemporaryDirectory())
        self.videoUrl = directory.appendingPathComponent(NSUUID().uuidString + ".mp4")
        toggleFlash()
    }
    
    func toggleFlash() {
        guard let device = AVCaptureDevice.default(for: AVMediaType.video) else { return }
        guard device.hasTorch else { return }

        do {
            try device.lockForConfiguration()
            device.exposureMode = .locked
            //device.automaticallyEnablesLowLightBoostWhenAvailable = false
            device.whiteBalanceMode = .locked
            if (device.torchMode == AVCaptureDevice.TorchMode.on) {
                device.torchMode = AVCaptureDevice.TorchMode.off
                stopRecording()
                if (originalPlayer != nil) {
                    performSegue(withIdentifier: "showQuestions", sender: self)
                } else {
                    //performSegue(withIdentifier: "showPlayerDetails", sender: nil)
                    //performSegue(withIdentifier: "showNewPlayerDetails", sender: nil)
                    performSegue(withIdentifier: "showNewPlayerSummary", sender: self)
                    
                }
            } else {
                do {
                    try device.setTorchModeOn(level: 1.0)
                } catch {
                    print(error)
                }
                recordVideo()
                
            }

            device.unlockForConfiguration()
        } catch {
            print(error)
        }
    }
    
    func recordVideo() {
        output.startRecording(to: videoUrl!, recordingDelegate: self)
    }
    
    func stopRecording() {
        output.stopRecording()
    }

    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showQuestions" {
            let controller = segue.destination as! CaptureAnswersController
            controller.player = self.originalPlayer
            controller.videoUrl = self.videoUrl
        }
        if segue.identifier == "showNewPlayerSummary" {
            let controller = segue.destination as! PlayerDetailsVC
            controller.player = self.modifiedPlayer
        }
    }

}
