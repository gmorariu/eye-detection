//
//  CaptureAnswersController.swift
//  retina
//
//  Created by George Morariu on 5/18/21.
//  Copyright © 2021 George Morariu. All rights reserved.
//

import UIKit
import AWSS3
import os.log

class CaptureAnswersController: UIViewController {
    
    var player: Player?
    var videoUrl: URL?
    
    @IBOutlet weak var rCognitiveLocation: UISwitch!
    @IBOutlet weak var rCognitiveBackwards: UISwitch!
    @IBOutlet weak var rSymptomNausea: UISwitch!
    @IBOutlet weak var rSymptomDizzy: UISwitch!
    @IBOutlet weak var rSymptomLightSensitivity: UISwitch!
    @IBOutlet weak var rSymptomSoundSensitivity: UISwitch!
    
    let model = DataModel.shared
    var alert: UIAlertController?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initAWSS3()
        // Do any additional setup after loading the view.
    }
    
    @IBAction func onSubmit(_ sender: Any) {
        /**/
        self.alert = AlertService.showProgressAlert()
        UIApplication.shared.beginIgnoringInteractionEvents()
        
        if (player != nil) {
            let incident = Incident(rCognitiveLocation: rCognitiveLocation.isOn, rCognitiveBackwards: rCognitiveBackwards.isOn, rSymptomNausea: rSymptomNausea.isOn, rSymptomDizzy: rSymptomDizzy.isOn, rSymptomLightSensitivity: rSymptomLightSensitivity.isOn, rSymptomSoundSensitivity: rSymptomSoundSensitivity.isOn)
            player!.addIncident(incident: incident)
            create_case(incident: incident, player: player!)
        } else {
            //TODO: Show some error here
        }
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
    
    private func create_case(incident: Incident, player: Player) {
        DispatchQueue.main.async {
            self.alert!.message = "Creating case..."
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy HH:mm"
        var params = [:] as Dictionary<String, AnyObject>
        params = ["subject_uuid": player.id, "timestamp": dateFormatter.string(from: incident.timestamp), "type": "test", "questions_answers": [["question":"Aware of location", "answer": (incident.rCognitiveLocation ? "yes" : "no")], ["question":"Can count or repeat words backwards", "answer":(incident.rCognitiveBackwards ? "yes" : "no")], ["question":"Nausea", "answer":(incident.rSymptomNausea ? "yes" : "no")], ["question":"Dizziness", "answer":(incident.rSymptomDizzy ? "yes" : "no")], ["question":"Sensitivity to light", "answer":(incident.rSymptomLightSensitivity ? "yes" : "no")], ["question":"Sensitivity to sound", "answer":(incident.rSymptomSoundSensitivity ? "yes" : "no")]]] as Dictionary<String, AnyObject>
        
        var request = URLRequest(url: URL(string: Constants.apiEndpoint + "cases")!)
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject: params, options: [])
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue((self.model.session?.idToken!.tokenString)!, forHTTPHeaderField: "Authorization")
        let session = URLSession.shared
        let task = session.dataTask(with: request, completionHandler: { data, response, error -> Void in
            do {
                let json = try JSONSerialization.jsonObject(with: data!) as! Dictionary<String, AnyObject>
                incident.id = json["id"] as? String
                os_log("Case crearted")
                AWSS3Manager.shared.uploadVideo(videoUrl: self.videoUrl!, key: "new/"+player.id+"/"+incident.id!+"/video.mp4", progress: { [weak self] (progress) in
                    
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
                        params1 = ["subject_uuid": player.id, "id": incident.id] as Dictionary<String, AnyObject>
                        var request1 = URLRequest(url: URL(string: Constants.apiEndpoint + "cases/process-video")!)
                        request1.httpMethod = "POST"
                        request1.httpBody = try? JSONSerialization.data(withJSONObject: params1, options: [])
                        request1.addValue("application/json", forHTTPHeaderField: "Content-Type")
                        request1.addValue((strongSelf.model.session?.idToken!.tokenString)!, forHTTPHeaderField: "Authorization")
                        let session1 = URLSession.shared
                        let task1 = session1.dataTask(with: request1, completionHandler: { data, response, error -> Void in
                            do {
                                let json = try JSONSerialization.jsonObject(with: data!) as! Dictionary<String, AnyObject>
                                incident.recordingURL = json["recording_link"] as? String
                                incident.thumbnailURL = json["thumbnail_link"] as? String
                                os_log("Video processed: %s", type: .debug, incident.recordingURL ?? "")
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
            /*if(aViewController is PlayerDetailsController){
               self.navigationController!.popToViewController(aViewController, animated: true);
            }*/
            if(aViewController is PlayerDetailsTabController){
                self.navigationController!.popToViewController(aViewController, animated: true);
            }
        }
    }

}
