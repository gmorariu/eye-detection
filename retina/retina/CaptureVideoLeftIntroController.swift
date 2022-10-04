//
//  CaptureVideoController.swift
//  retina
//
//  Created by George Morariu on 5/18/21.
//  Copyright © 2021 George Morariu. All rights reserved.
//

import UIKit

class CaptureVideoLeftIntroController: UIViewController {

    @IBOutlet weak var imgVideo: UIImageView!
    @IBOutlet weak var btnNext: UIBarButtonItem!
    
    //@IBOutlet weak var progressView: UIProgressView!
    
    var originalPlayer : Player? = nil
    var modifiedPlayer : Player? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        var animationImages = [UIImage(named: "camera_animation_0.png")]
        for i in 1...48 {
            animationImages.append(UIImage(named: "camera_animation_"+String(i)+".png"))
        }
        //self.progressView.setProgress(0, animated: false)
        imgVideo.animationImages = (animationImages as! [UIImage])
        imgVideo.animationDuration = 2
        self.imgVideo.startAnimating()
        //imgVideo.animationRepeatCount = 1
        //self.btnNext.isEnabled = false

        
        // Do any additional setup after loading the view.
    }
    
    /*@IBAction func onRecTouchDown(_ sender: Any) {
        self.btnNext.isEnabled = false
        self.progressView.setProgress(0, animated: false)
        UIView.animate(withDuration: 4.0) {
            self.progressView.setProgress(1.0, animated: true)
            
            self.btnNext.isEnabled = true
        }
    }
    
    @IBAction func onRecTouchUp(_ sender: Any) {
        //imgVideo.stopAnimating()
    }*/
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showRecorder" {
            let controller = segue.destination as! CaptureVideoPreviewController
            controller.originalPlayer = self.originalPlayer
            controller.modifiedPlayer = self.modifiedPlayer
        } 
    }

}
