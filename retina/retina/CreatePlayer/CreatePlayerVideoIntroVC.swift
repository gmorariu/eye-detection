//
//  CreatePlayerVideoIntroVC.swift
//  retina
//
//  Created by George Morariu on 9/21/21.
//  Copyright © 2021 George Morariu. All rights reserved.
//

import UIKit

class CreatePlayerVideoIntroVC: UIViewController {

    @IBOutlet weak var imgVideo: UIImageView!
    @IBOutlet weak var btnNext: UIBarButtonItem!
    var player : Player? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        var animationImages = [UIImage(named: "camera_animation_0.png")]
        for i in 1...48 {
            animationImages.append(UIImage(named: "camera_animation_"+String(i)+".png"))
        }
        imgVideo.animationImages = (animationImages as! [UIImage])
        imgVideo.animationDuration = 2
        self.imgVideo.startAnimating()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showRecorder" {
            let controller = segue.destination as! CreatePlayerVideoCaptureVC
            controller.player = self.player
        }
    }

}

