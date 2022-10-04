//
//  AddPlayerController.swift
//  retina
//
//  Created by George Morariu on 5/17/21.
//  Copyright © 2021 George Morariu. All rights reserved.
//

/*import UIKit
import os.log

class AddPlayerController: UITableViewController {
    @IBOutlet weak var txtFirstName: UITextField!
    @IBOutlet weak var txtLastName: UITextField!
    @IBOutlet weak var dateDOB: UIDatePicker!
    @IBOutlet weak var txtNumber: UITextField!
    @IBOutlet weak var txtEmergencyName: UITextField!
    @IBOutlet weak var txtEmergencyRelation: UITextField!
    @IBOutlet weak var txtEmergencyPhone: UITextField!
    @IBOutlet weak var btnDelete: UIButton!
    
    
    var originalPlayer : Player? = nil
    
    let model = DataModel.shared
    var alert: UIAlertController?
    
    @IBAction func onSavePressed(_ sender: Any) {
        if (originalPlayer != nil) {
            originalPlayer!.firstName = txtFirstName.text ?? ""
            originalPlayer!.lastName = txtLastName.text ?? ""
            originalPlayer!.dob = dateDOB.date
            originalPlayer!.number = txtNumber.text ?? ""
            originalPlayer!.emergencyName = txtEmergencyName.text ?? ""
            originalPlayer!.emergencyRelation = txtEmergencyRelation.text ?? ""
            originalPlayer!.emergencyPhone = txtEmergencyPhone.text ?? ""
            self.alert = AlertService.showProgressAlert()
            UIApplication.shared.beginIgnoringInteractionEvents()
            self.create_subject(player: originalPlayer!)
            //self.navigationController?.popViewController(animated: true)
        } else {
            btnDelete.isHidden = true
            let player = Player(number: txtNumber.text ?? "", firstName: txtFirstName.text ?? "", lastName: txtLastName.text ?? "", dob: dateDOB.date, emergencyName: txtEmergencyName.text ?? "", emergencyRelation: txtEmergencyRelation.text ?? "", emergencyPhone: txtEmergencyPhone.text ?? "")
            model.addPlayer(player: player)
            self.alert = AlertService.showProgressAlert()
            UIApplication.shared.beginIgnoringInteractionEvents()
            self.create_subject(player: player)
        }
    }
    
    @IBAction func onDeletePressed(_ sender: Any) {
        self.alert = AlertService.showProgressAlert()
        UIApplication.shared.beginIgnoringInteractionEvents()
        self.model.deletePlayer(player: originalPlayer!)
        self.delete_subject(player: originalPlayer!)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        btnDelete.isHidden = true
        if (originalPlayer != nil) {
            btnDelete.isHidden = false
            txtFirstName.text = originalPlayer!.firstName
            txtLastName.text = originalPlayer!.lastName
            dateDOB.date = originalPlayer!.dob
            txtNumber.text = String(originalPlayer!.number)
            txtEmergencyName.text = originalPlayer!.emergencyName
            txtEmergencyRelation.text = originalPlayer!.emergencyRelation
            txtEmergencyPhone.text = originalPlayer!.emergencyPhone
        }
    }
    
    private func create_subject(player: Player) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/YYYY"
        var params = [:] as Dictionary<String, AnyObject>
        if (player.id.isEmpty) {
            params = ["subject": ["first_name": player.firstName, "last_name": player.lastName, "dob": dateFormatter.string(from: player.dob ?? Date()), "team_number": player.number, "gender": player.gender, "emergency_contact": ["name": player.emergencyName, "phone": player.emergencyPhone, "relation": player.emergencyRelation]], "team": "My Team"] as Dictionary<String, AnyObject>
        } else {
            params = ["subject": ["id": player.id, "first_name": player.firstName, "last_name": player.lastName, "dob": dateFormatter.string(from: player.dob ?? Date()), "team_number": player.number, "gender": player.gender, "emergency_contact": ["name": player.emergencyName, "phone": player.emergencyPhone, "relation": player.emergencyRelation]], "team": "My Team"] as Dictionary<String, AnyObject>
        }
        var request = URLRequest(url: URL(string: Constants.apiEndpoint + "subjects")!)
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject: params, options: [])
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue((model.session?.idToken!.tokenString)!, forHTTPHeaderField: "Authorization")
        let session = URLSession.shared
        os_log("Creating/Updating player: %s", type: .debug, player.id)
        
        let task = session.dataTask(with: request, completionHandler: { data, response, error -> Void in
            do {
                let json = try JSONSerialization.jsonObject(with: data!) as! Dictionary<String, AnyObject>
                player.id = json["subject_id"] as! String
                os_log("Player %s created/updated", type: .debug, player.id)
                DispatchQueue.main.async {
                    self.alert?.dismiss(animated: true, completion: {
                        self.navigationController?.popViewController(animated: true)
                    })
                    UIApplication.shared.endIgnoringInteractionEvents()
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
    
    private func delete_subject(player: Player) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/YYYY"
        var params = [:] as Dictionary<String, AnyObject>
        if (!player.id.isEmpty) {
            params = ["subject": player.id] as Dictionary<String, AnyObject>
        }
        var request = URLRequest(url: URL(string: Constants.apiEndpoint + "subjects")!)
        request.httpMethod = "DELETE"
        request.httpBody = try? JSONSerialization.data(withJSONObject: params, options: [])
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue((model.session?.idToken!.tokenString)!, forHTTPHeaderField: "Authorization")
        let session = URLSession.shared
        let task = session.dataTask(with: request, completionHandler: { data, response, error -> Void in
            do {
                //let json = try JSONSerialization.jsonObject(with: data!) as! Dictionary<String, AnyObject>
                //player.id = json["subject_id"] as! String
                os_log("Got items")
                DispatchQueue.main.async {
                    self.alert?.dismiss(animated: true, completion: {
                        self.navigationController?.popViewController(animated: true)
                        self.navigationController?.popViewController(animated: true)
                    })
                    UIApplication.shared.endIgnoringInteractionEvents()
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

}
*/
