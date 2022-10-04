//
//  DataModel.swift
//  retina
//
//  Created by George Morariu on 5/17/21.
//  Copyright © 2021 George Morariu. All rights reserved.
//

import Foundation
import AWSCognitoIdentityProvider

class DataModel {
    static let shared = DataModel()
    var players: [Player] = []
    
    //Properties below this are used by the local app and not persisted
    var awsInitialized: Bool = false
    var pool: AWSCognitoIdentityUserPool? = nil
    var credentialsProvider: AWSCognitoCredentialsProvider? = nil
    var user: AWSCognitoIdentityUser? = nil
    var session: AWSCognitoIdentityUserSession? = nil
    var userDetails: AWSCognitoIdentityUserGetDetailsResponse? = nil
    var identityId: String?
    var awsS3Initialized: Bool = false
    
    
    init () {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd-yyyy"
        
        
        /*let player1 = Player(number: 23, firstName: "Rudy", lastName: "Gonzales", dob: dateFormatter.date(from: "01-02-2010") ?? Date(), emergencyName: "Maria Gonzales", emergencyRelation: "Mother", emergencyPhone: "(123) 456-7890")
        let player2 = Player(number: 17, firstName: "Ervin", lastName: "Davis", dob: dateFormatter.date(from: "03-04-2010") ?? Date(), emergencyName: "John Davis", emergencyRelation: "Father", emergencyPhone: "(321) 456-7890")
        let player3 = Player(number: 56, firstName: "Don", lastName: "Hampton", dob: dateFormatter.date(from: "05-06-2010") ?? Date(), emergencyName: "Mark Hampton", emergencyRelation: "Father", emergencyPhone: "(213) 456-7890")
        */
        //self.players.append(player1)
        //self.players.append(player2)
        //self.players.append(player3)
    }
    
    func load(subjects: Array<Dictionary<String, AnyObject>>) {
        self.players.removeAll()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd-yyyy"
        
        for subject in subjects {
            let emergencyContact = subject["emergency_contact"] as! Dictionary<String, String>
            let player = Player(number: subject["team_number"] as? String ?? "", firstName: subject["first_name"] as? String ?? "", lastName: subject["last_name"] as? String ?? "", dob: dateFormatter.date(from: subject["dob"] as? String ?? "1/1/1800") ?? Date(), emergencyName: emergencyContact["name"] ?? "", emergencyRelation: emergencyContact["relation"] ?? "", emergencyPhone: emergencyContact["phone"] ?? "")
            player.id = subject["id"] as? String ?? ""
            player.gender = subject["gender"] as? String ?? ""
            player.getFaceData()
            self.players.append(player)
        }
    }
    
    func load_cases(player: Player, cases: Array<Dictionary<String, AnyObject>>) {
        player.incident.removeAll()
        for jcase in cases {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM-dd-yyyy HH:mm"
            var timestamp: Date? = nil
            
            
            if ((jcase["type"] as? String) == "baseline") {
                timestamp = dateFormatter.date(from: jcase["timestamp"] as? String ?? "")
                if timestamp == nil {
                    dateFormatter.dateFormat = "MM-dd-yyyy"
                    timestamp = dateFormatter.date(from: jcase["timestamp"] as? String ?? "")
                }
                if timestamp == nil {
                    dateFormatter.dateFormat = "MM-dd-yyyy"
                    timestamp = dateFormatter.date(from: "1/1/1800")
                }
                if player.baseline != nil {
                    if timestamp! > player.baseline!.timestamp {
                        let baseline = Baseline()
                        baseline.timestamp = timestamp!
                        baseline.id = jcase["id"] as? String
                        baseline.recordingURL = jcase["recording_link"] as? String
                        baseline.setThumbnail(url: jcase["thumbnail_link"] as? String ?? "")
                        let validated_result = jcase["validated_result"] as? String ?? ""
                        switch validated_result {
                            case "no_concussion":
                                baseline.resolution = .noConcussion
                                break
                            case "new":
                                baseline.resolution = .noConcussion
                                break
                            case "preprocess":
                                baseline.resolution = .preprocess
                                break
                            default:
                                baseline.resolution = .insufficientData
                        }
                        player.setBaseline(baseline: baseline)
                    }
                } else {
                    let baseline = Baseline()
                    baseline.timestamp = timestamp!
                    baseline.id = jcase["id"] as? String
                    baseline.recordingURL = jcase["recording_link"] as? String
                    baseline.setThumbnail(url: jcase["thumbnail_link"] as? String ?? "")
                    let validated_result = jcase["validated_result"] as? String ?? ""
                    switch validated_result {
                        case "no_concussion":
                            baseline.resolution = .noConcussion
                            break
                        case "new":
                            baseline.resolution = .noConcussion
                            break
                        case "preprocess":
                            baseline.resolution = .preprocess
                            break
                        default:
                            baseline.resolution = .insufficientData
                    }
                    player.setBaseline(baseline: baseline)
                }
                continue
            }
            let incident = Incident()
            incident.id = jcase["id"] as? String 
            let validated_result = jcase["validated_result"] as? String ?? ""
            switch validated_result {
                case "no_concussion":
                    incident.resolution = .noConcussion
                    break
                case "concussion":
                    incident.resolution = .concussion
                    break
                case "new":
                    incident.resolution = .new
                    break
                case "preprocess":
                    incident.resolution = .preprocess
                    break
                default:
                    incident.resolution = .insufficientData
            }
            
            timestamp = dateFormatter.date(from: jcase["timestamp"] as? String ?? "")
            if timestamp == nil {
                dateFormatter.dateFormat = "MM-dd-yyyy"
                timestamp = dateFormatter.date(from: jcase["timestamp"] as? String ?? "")
            }
            if timestamp == nil {
                dateFormatter.dateFormat = "MM-dd-yyyy"
                timestamp = dateFormatter.date(from: "1/1/1800")
            }
            incident.timestamp = timestamp!
            let qa_list = jcase["questions_answers"] as? Array<Dictionary<String, String>> ?? []
            for qa in qa_list {
                switch qa["question"] {
                    case "Aware of location":
                        incident.rCognitiveLocation = (qa["answer"] == "yes")
                        break
                    case "Can count or repeat words backwards":
                        incident.rCognitiveBackwards = (qa["answer"] == "yes")
                        break
                    case "Nausea":
                        incident.rSymptomNausea = (qa["answer"] == "yes")
                        break
                    case "Dizziness":
                        incident.rSymptomDizzy = (qa["answer"] == "yes")
                        break
                    case "Sensitivity to light":
                        incident.rSymptomLightSensitivity = (qa["answer"] == "yes")
                        break
                    case "Sensitivity to sound":
                        incident.rSymptomSoundSensitivity = (qa["answer"] == "yes")
                        break
                    default:
                        break
                }
            }
            incident.recordingURL = jcase["recording_link"] as? String
            incident.thumbnailURL = jcase["thumbnail_link"] as? String
            player.addIncident(incident: incident)
        }
        player.incident = player.incident.sorted(by: { $0.timestamp > $1.timestamp })
    }
    
    func addPlayer(player: Player) {
        self.players.append(player)
    }
    
    func deletePlayer(player: Player) {
        var i = 0
        for p in self.players {
            if (p.id == player.id) {
                self.players.remove(at: i)
                return
            }
            i = i + 1
        }
    }
    
    func signOut() {
        self.user?.signOut()
        self.session = nil
        self.identityId = nil
        self.credentialsProvider?.invalidateCachedTemporaryCredentials()
        self.credentialsProvider?.clearKeychain()
        self.credentialsProvider?.clearCredentials()
        self.pool?.clearAll()
        //self.clearLocalStorage()
        exit(-1)
    }
}
