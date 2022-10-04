//
//  CreatePlayerSummaryVC.swift
//  retina
//
//  Created by George Morariu on 9/21/21.
//  Copyright © 2021 George Morariu. All rights reserved.
//

import UIKit
import AWSS3
import os.log

class CreatePlayerSummaryVC: UIViewController {
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var lblDOB: UILabel!
    @IBOutlet weak var lblGender: UILabel!
    
    @IBOutlet weak var lblTeamNumber: UILabel!
    @IBOutlet weak var lblECName: UILabel!
    @IBOutlet weak var lblECRelation: UILabel!
    @IBOutlet weak var lblECPhone: UILabel!
    
    @IBOutlet weak var btnAction: UIBarButtonItem!
    @IBOutlet weak var navbar: UINavigationItem!
    
    
    let model = DataModel.shared
    var alert: UIAlertController?
    
    var player :Player? = nil
    var newVideoUrl: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initAWSS3()

        lblName.text = (player?.firstName ?? "") + " " + (player?.lastName ?? "")
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/YYYY"
        lblDOB.text = dateFormatter.string(from: player?.dob ?? Date())
        lblGender.text = player?.gender ?? ""
        lblTeamNumber.text = player?.number ?? ""
        lblECName.text = player?.emergencyName ?? ""
        lblECRelation.text = player?.emergencyRelation ?? ""
        lblECPhone.text = player?.emergencyPhone ?? ""
    }
    
    @IBAction func onPupilResponsePressed(_ sender: Any) {
    }
    
    private func initAWSS3() {
        if (!self.model.awsS3Initialized) {
            //let credentialsProvider = AWSStaticCredentialsProvider(accessKey:"AKIAW54F47N2TQ642MQF", secretKey: "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")
            //let cf1 = AWSServiceConfiguration(region: Constants.region, credentialsProvider: credentialsProvider)
            let cf1 = AWSServiceConfiguration(region: Constants.region, credentialsProvider: model.credentialsProvider)
            AWSServiceManager.default().defaultServiceConfiguration = cf1
            AWSS3TransferUtility.register(with: cf1!, forKey: "S3")
            self.model.awsS3Initialized = true
        }
    }
    
    @IBAction func onActionPressed(_ sender: Any) {
        self.alert = AlertService.showProgressAlert()
        UIApplication.shared.beginIgnoringInteractionEvents()
        self.create_subject(player: player!)
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    }
    
    private func create_subject(player: Player) {
        self.alert!.message = "Creating player..."
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/YYYY"
        var params = [:] as Dictionary<String, AnyObject>
        if (player.id.isEmpty) {
            DispatchQueue.main.async {
                self.alert!.message = "Creating player..."
            }
            
            params = ["subject": ["first_name": player.firstName, "last_name": player.lastName, "dob": dateFormatter.string(from: player.dob ), "team_number": player.number, "gender": player.gender, "emergency_contact": ["name": player.emergencyName, "phone": player.emergencyPhone, "relation": player.emergencyRelation]], "team": "My Team"] as Dictionary<String, AnyObject>
        } else {
            DispatchQueue.main.async {
                self.alert!.message = "Updating player..."
            }
            params = ["subject": ["id": player.id, "first_name": player.firstName, "last_name": player.lastName, "dob": dateFormatter.string(from: player.dob ), "team_number": player.number, "gender": player.gender, "emergency_contact": ["name": player.emergencyName, "phone": player.emergencyPhone, "relation": player.emergencyRelation]], "team": "My Team"] as Dictionary<String, AnyObject>
        }
        
        /*var params = ["subject": ["first_name": player.firstName, "last_name": player.lastName, "dob": dateFormatter.string(from: player.dob ?? Date()), "team_number": player.number, "gender": player.gender, "emergency_contact": ["name": player.emergencyName, "phone": player.emergencyPhone, "relation": player.emergencyRelation]], "team": "My Team"] as Dictionary<String, AnyObject>
        */
        var request = URLRequest(url: URL(string: Constants.apiEndpoint + "subjects")!)
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject: params, options: [])
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue((model.session?.idToken!.tokenString)!, forHTTPHeaderField: "Authorization")
        let session = URLSession.shared
        os_log("Creating/Updating player: %s", type: .debug, player.id)
        
        let task = session.dataTask(with: request, completionHandler: { data, response, error -> Void in
            do {
                if (player.id.isEmpty) {
                    self.model.addPlayer(player: self.player!)
                }
                let json = try JSONSerialization.jsonObject(with: data!) as! Dictionary<String, AnyObject>
                player.id = json["subject_id"] as! String
                os_log("Player %s created/updated", type: .debug, player.id)
                self.create_baseline(player: self.player!)
                /*DispatchQueue.main.async {
                    self.alert?.dismiss(animated: true, completion: {
                        self.returnToMainScreen()
                    })
                    UIApplication.shared.endIgnoringInteractionEvents()
                }*/
            } catch {
                DispatchQueue.main.async {
                    self.alert?.dismiss(animated: true, completion: {
                        AlertService.showAlert(style: .alert, title: "Error", message: Constants.add_player_error)
                    })
                    UIApplication.shared.endIgnoringInteractionEvents()
                }
            }
        })
        task.resume()
    }
    
    private func create_baseline(player: Player) {
        player.setBaseline(baseline: Baseline())
        DispatchQueue.main.async {
            self.alert!.message = "Creating baseline record..."
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy HH:mm"
        var params = [:] as Dictionary<String, AnyObject>
        params = ["subject_uuid": player.id, "timestamp": dateFormatter.string(from: player.baseline!.timestamp), "type": "baseline"] as Dictionary<String, AnyObject>
        var request = URLRequest(url: URL(string: Constants.apiEndpoint + "cases")!)
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject: params, options: [])
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue((self.model.session?.idToken!.tokenString)!, forHTTPHeaderField: "Authorization")
        let session = URLSession.shared
        let task = session.dataTask(with: request, completionHandler: { data, response, error -> Void in
            do {
                let json = try JSONSerialization.jsonObject(with: data!) as! Dictionary<String, AnyObject>
                player.baseline!.id = json["id"] as? String
                os_log("Case crearted")
                AWSS3Manager.shared.uploadVideo(videoUrl: self.newVideoUrl!, key: "new/"+player.id+"/"+player.baseline!.id!+"/video.mp4", progress: { [weak self] (progress) in
                    guard let strongSelf = self else { return }
                    DispatchQueue.main.async {
                        strongSelf.alert!.message = "Uploading video: "+String(Int(floor(Float(progress)*100)))+"%"
                    }
                    
                }) { [weak self] (uploadedFileUrl, error) in
                    guard let strongSelf = self else { return }
                    if let finalPath = uploadedFileUrl as? String {
                        os_log("Uploaded file url: %s", type: .debug, finalPath)
                        DispatchQueue.main.async {
                            strongSelf.alert!.message = "Processing video ..."
                        }
                        var params1 = [:] as Dictionary<String, AnyObject>
                        params1 = ["subject_uuid": player.id, "id": player.baseline!.id!] as Dictionary<String, AnyObject>
                        var request1 = URLRequest(url: URL(string: Constants.apiEndpoint + "cases/process-video")!)
                        request1.httpMethod = "POST"
                        request1.httpBody = try? JSONSerialization.data(withJSONObject: params1, options: [])
                        request1.addValue("application/json", forHTTPHeaderField: "Content-Type")
                        request1.addValue((strongSelf.model.session?.idToken!.tokenString)!, forHTTPHeaderField: "Authorization")
                        let session1 = URLSession.shared
                        let task1 = session1.dataTask(with: request1, completionHandler: { data, response, error -> Void in
                            do {
                                let json = try JSONSerialization.jsonObject(with: data!) as! Dictionary<String, AnyObject>
                                player.baseline!.recordingURL = json["recording_link"] as? String
                                player.baseline!.setThumbnail(url: json["thumbnail_link"] as? String ?? "")
                                os_log("Video processed: %s", type: .debug, player.baseline!.recordingURL ?? "")
                                DispatchQueue.main.async {
                                    strongSelf.alert?.dismiss(animated: true, completion: {
                                        strongSelf.returnToMainScreen()
                                    })
                                    UIApplication.shared.endIgnoringInteractionEvents()
                                }
                                
                            } catch {
                                DispatchQueue.main.async {
                                    strongSelf.alert?.dismiss(animated: true, completion: {
                                        AlertService.showAlert(style: .alert, title: "Error", message: Constants.add_player_error)
                                    })
                                    UIApplication.shared.endIgnoringInteractionEvents()
                                }
                            }
                        })
                        task1.resume()
                        
                        
                    } else {
                        DispatchQueue.main.async {
                            strongSelf.alert?.dismiss(animated: true, completion: {
                                AlertService.showAlert(style: .alert, title: "Error", message: Constants.add_player_error)
                            })
                            UIApplication.shared.endIgnoringInteractionEvents()
                        }
                        print("\(String(describing: error?.localizedDescription))")
                    }
                }
                
            } catch {
                DispatchQueue.main.async {
                    self.alert?.dismiss(animated: true, completion: {
                        AlertService.showAlert(style: .alert, title: "Error", message: Constants.add_player_error)
                    })
                    UIApplication.shared.endIgnoringInteractionEvents()
                }
            }
        })
        task.resume()
    }
    
    private func returnToMainScreen() {
        let viewControllers: [UIViewController] = self.navigationController!.viewControllers ;
        for aViewController in viewControllers {
            if(aViewController is PlayersViewController){
               self.navigationController!.popToViewController(aViewController, animated: true);
            }
        }
    }
}

