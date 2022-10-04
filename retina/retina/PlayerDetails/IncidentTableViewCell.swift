//
//  IncidentTableViewCell.swift
//  retina
//
//  Created by George Morariu on 5/18/21.
//  Copyright © 2021 George Morariu. All rights reserved.
//

import UIKit

class IncidentTableViewCell: UITableViewCell {
    
    @IBOutlet weak var imgStatus: UIImageView!
    @IBOutlet weak var lblTimestamp: UILabel!
    
    func setStatus(status: Incident.Resolution) {
        switch status {
        case .concussion:
            imgStatus.image = UIImage(named: "brain-nok.png")
            break
        case .new:
            imgStatus.image = UIImage(named: "wait.png")
            break
        case .preprocess:
            imgStatus.image = UIImage(named: "wait.png")
            break
        case .noConcussion:
            imgStatus.image = UIImage(named: "brain-ok.png")
            break
        case .insufficientData:
            imgStatus.image = UIImage(named: "notokay.png")
            break
        default:
            imgStatus.image = UIImage()
        }
    }
    
    func setTimestamp(date: Date) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        lblTimestamp.text = dateFormatter.string(from: date)
    }

}
