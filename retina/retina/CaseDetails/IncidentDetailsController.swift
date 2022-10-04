//
//  IncidentDetailsController.swift
//  retina
//
//  Created by George Morariu on 5/18/21.
//  Copyright © 2021 George Morariu. All rights reserved.
//

import UIKit

class IncidentDetailsController: UIViewController {
    @IBOutlet weak var lblTimestamp: UILabel!
    @IBOutlet weak var lblStatus: UILabel!
    @IBOutlet weak var lblCognitiveLocation: UILabel!
    @IBOutlet weak var lblCognitiveBackwards: UILabel!
    @IBOutlet weak var lblSymptomNausea: UILabel!
    @IBOutlet weak var lblSymptomDizzy: UILabel!
    @IBOutlet weak var lblSymptomLightSensitivity: UILabel!
    @IBOutlet weak var lblSymptomSoundSensitivity: UILabel!
    @IBOutlet weak var btnViewVideo: UIButton!
    @IBOutlet weak var btnPlayVideo: UIButton!
    
    var incident :Incident?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if incident?.thumbnailURL != nil {
            let thumbURL = URL(string: (incident?.thumbnailURL)!)
            let thumbData = try? Data(contentsOf: thumbURL!)
            if thumbData != nil {
                let thumbImage = UIImage(data: thumbData!)
                btnViewVideo.setImage(thumbImage, for: .normal)
                btnViewVideo.isHidden = false
            } else {
                btnViewVideo.setImage(nil, for: .normal)
                btnViewVideo.isHidden = true
            }
            
        } else {
            btnViewVideo.setImage(nil, for: .normal)
            btnViewVideo.isHidden = true
        }
        btnPlayVideo.isHidden = btnViewVideo.isHidden

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        lblTimestamp.text = dateFormatter.string(from: incident!.timestamp)
        
        switch incident!.resolution {
        case .concussion:
            lblStatus.text = "Concussion Detected"
        case .preprocess:
            lblStatus.text = "Processing Video"
        case .new:
            lblStatus.text = "Waiting Evaluation"
        case .noConcussion:
            lblStatus.text = "No Concussion Detected"
        case .insufficientData:
            lblStatus.text = "Unknown - Insufficient data"
        default:
            lblStatus.text = ""
        }
        
        if (incident!.rCognitiveLocation == true) {
            lblCognitiveLocation.text = "Yes"
        } else {
            lblCognitiveLocation.text = "No"
        }
        
        if (incident!.rCognitiveBackwards == true) {
            lblCognitiveBackwards.text = "Yes"
        } else {
            lblCognitiveBackwards.text = "No"
        }
        
        if (incident!.rSymptomNausea == true) {
            lblSymptomNausea.text = "Yes"
        } else {
            lblSymptomNausea.text = "No"
        }
        
        if (incident!.rSymptomDizzy == true) {
            lblSymptomDizzy.text = "Yes"
        } else {
            lblSymptomDizzy.text = "No"
        }
        
        if (incident!.rSymptomLightSensitivity == true) {
            lblSymptomLightSensitivity.text = "Yes"
        } else {
            lblSymptomLightSensitivity.text = "No"
        }
        
        if (incident!.rSymptomSoundSensitivity == true) {
            lblSymptomSoundSensitivity.text = "Yes"
        } else {
            lblSymptomSoundSensitivity.text = "No"
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showVideoPlayer" {
            let controller = segue.destination as! VideoPlayerController
            controller.url = URL(string: incident!.recordingURL!)
        }
    }
    
    @IBAction func onViewVideoPressed(_ sender: Any) {
        if incident?.recordingURL != nil {
            self.performSegue(withIdentifier: "showVideoPlayer", sender: self)
        }
    }

}
