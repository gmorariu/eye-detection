//
//  Baseline.swift
//  retina
//
//  Created by George Morariu on 9/21/21.
//  Copyright © 2021 George Morariu. All rights reserved.
//

import Foundation

class Baseline {
    enum Resolution {
        case noConcussion
        case preprocess
        case insufficientData
    }
    var timestamp :Date
    var resolution : Resolution
    var recordingURL: String?
    var thumbnailURL: String?
    var thumbnailData: Data?
    var id: String?
    
    init() {
        self.timestamp = Date()
        self.resolution = .insufficientData
    }
    
    func setThumbnail(url: String){
        thumbnailURL = url
        let turl = URL(string: thumbnailURL!)
        thumbnailData = try? Data(contentsOf: turl ?? URL(fileURLWithPath: ""))
    }
}

