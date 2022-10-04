//
//  Incident.swift
//  retina
//
//  Created by George Morariu on 5/18/21.
//  Copyright © 2021 George Morariu. All rights reserved.
//

import Foundation

class Incident {
    enum Resolution {
        case concussion
        case new
        case preprocess
        case noConcussion
        case insufficientData
    }
    var timestamp :Date
    var resolution :Resolution
    var rCognitiveLocation :Bool
    var rCognitiveBackwards :Bool
    var rSymptomNausea :Bool
    var rSymptomDizzy :Bool
    var rSymptomLightSensitivity :Bool
    var rSymptomSoundSensitivity :Bool
    var recordingURL: String?
    var thumbnailURL: String?
    var id: String?
    
    init(rCognitiveLocation :Bool, rCognitiveBackwards :Bool, rSymptomNausea :Bool, rSymptomDizzy :Bool, rSymptomLightSensitivity :Bool, rSymptomSoundSensitivity :Bool) {
        self.timestamp = Date()
        self.resolution = .new
        self.rCognitiveLocation = rCognitiveLocation
        self.rCognitiveBackwards = rCognitiveBackwards
        self.rSymptomNausea = rSymptomNausea
        self.rSymptomDizzy = rSymptomDizzy
        self.rSymptomLightSensitivity = rSymptomLightSensitivity
        self.rSymptomSoundSensitivity = rSymptomSoundSensitivity
    }
    
    init() {
        self.timestamp = Date()
        self.resolution = .new
        self.rCognitiveLocation = false
        self.rCognitiveBackwards = false
        self.rSymptomNausea = false
        self.rSymptomDizzy = false
        self.rSymptomLightSensitivity = false
        self.rSymptomSoundSensitivity = false
    }
}


