//
//  Player.swift
//  retina
//
//  Created by George Morariu on 5/17/21.
//  Copyright © 2021 George Morariu. All rights reserved.
//

import Foundation

class Player {
    var id: String
    var number: String
    var firstName: String
    var lastName: String
    var dob: Date
    var emergencyName: String
    var emergencyRelation: String
    var emergencyPhone: String
    var gender: String
    var incident: [Incident]
    var baseline: Baseline?
    var faceData: Data?
    
    init() {
        self.id=""
        self.number = ""
        self.firstName = ""
        self.lastName = ""
        self.dob = Date()
        self.gender = "male"
        self.emergencyName = ""
        self.emergencyRelation = ""
        self.emergencyPhone = ""
        self.incident = []
    }
    
    init(number: String, firstName: String, lastName: String, dob: Date, emergencyName: String, emergencyRelation: String, emergencyPhone: String) {
        self.id=""
        self.number = number
        self.firstName = firstName
        self.lastName = lastName
        self.dob = dob
        self.gender = "male"
        self.emergencyName = emergencyName
        self.emergencyRelation = emergencyRelation
        self.emergencyPhone = emergencyPhone
        self.incident = []
        
        
    }
    func addIncident(incident: Incident) {
        self.incident.append(incident)
    }
    
    func setBaseline(baseline: Baseline) {
        self.baseline = baseline
    }
    
    func getFaceData(){
        let url = URL(string: "https://camcussion.s3.us-west-2.amazonaws.com/cases/"+self.id+"/face.jpeg")
        faceData = try? Data(contentsOf: url ?? URL(fileURLWithPath: ""))
    }
    
}
