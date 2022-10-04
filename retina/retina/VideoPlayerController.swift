//
//  VideoPlayerController.swift
//  retina
//
//  Created by George Morariu on 8/31/21.
//  Copyright © 2021 George Morariu. All rights reserved.
//

import AVKit
import os.log

class VideoPlayerController: AVPlayerViewController {
    var url: URL?
    func playVideo(url: URL){
        let player = AVPlayer(url: url)
        let playerController = AVPlayerViewController()

        playerController.player = player
        self.addChild(playerController)
        self.view.addSubview(playerController.view)
        playerController.view.frame = self.view.frame
        player.play()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        playVideo(url: url!)

    }
}
