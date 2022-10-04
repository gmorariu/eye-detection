//
//  PlayersTableViewCell.swift
//  retina
//
//  Created by George Morariu on 5/17/21.
//  Copyright © 2021 George Morariu. All rights reserved.
//

import UIKit

class PlayersTableViewCell: UITableViewCell {

    @IBOutlet weak var lblNumber: UILabel!
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var btnFace: UIButton!
    
    override func layoutSubviews() {
        btnFace.imageView?.layer.cornerRadius = (btnFace.imageView?.frame.height)!/2;
        btnFace.imageView?.layer.masksToBounds = true;
        btnFace.imageView?.layer.borderWidth = 0;
    }
    
    func setNumber(number: String) {
        lblNumber.text = number
    }
    
    func setName(firstName: String, lastName: String) {
        lblName.text = firstName + " " + lastName
    }
    
    func setFace(faceData: Data?) {
        if faceData != nil {
            let faceImage = UIImage(data: (faceData!))
            btnFace.setImage(faceImage, for: .normal)
        }
    }

}
