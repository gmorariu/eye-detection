//
//  PlayerDetailsController.swift
//  retina
//
//  Created by George Morariu on 5/18/21.
//  Copyright © 2021 George Morariu. All rights reserved.
//

/*import UIKit
import os.log

class PlayerDetailsController: UIViewController {
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var lblDOB: UILabel!
    @IBOutlet weak var lblNumber: UILabel!
    @IBOutlet weak var lblEmergencyName: UILabel!
    @IBOutlet weak var lblEmergencyRelation: UILabel!
    @IBOutlet weak var lblEmergencyPhone: UILabel!
    @IBOutlet weak var inicidentTableView: UITableView!
    
    let model = DataModel.shared
    var alert: UIAlertController?
    
    var player :Player? = nil
    var newPlayer :Bool = false
    var newVideoUrl: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if !newPlayer {
            self.alert = AlertService.showProgressAlert()
            UIApplication.shared.beginIgnoringInteractionEvents()
        }
        lblName.text = (player?.firstName ?? "") + " " + (player?.lastName ?? "")
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/YYYY"
        lblDOB.text = dateFormatter.string(from: player?.dob ?? Date())
        lblNumber.text = player?.number ?? ""
        lblEmergencyName.text = player?.emergencyName ?? ""
        lblEmergencyRelation.text = player?.emergencyRelation ?? ""
        lblEmergencyPhone.text = player?.emergencyPhone ?? ""
        inicidentTableView.delegate = self
        inicidentTableView.dataSource = self
        self.navigationItem.title = lblName.text
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        lblName.text = (player?.firstName ?? "") + " " + (player?.lastName ?? "")
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/YYYY"
        lblDOB.text = dateFormatter.string(from: player?.dob ?? Date())
        lblNumber.text = player?.number ?? ""
        lblEmergencyName.text = player?.emergencyName ?? ""
        lblEmergencyRelation.text = player?.emergencyRelation ?? ""
        lblEmergencyPhone.text = player?.emergencyPhone ?? ""
        if !newPlayer {
            get_cases()
        }
    }
    

    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //if segue.identifier == "playerEdit" {
         //   let controller = segue.destination as! AddPlayerController
         //   controller.originalPlayer = self.player
        //} else
        if segue.identifier == "incidentVideo" {
            let controller = segue.destination as! CaptureVideoLeftIntroController
            controller.originalPlayer = self.player
        } else if segue.identifier == "incidentDetails" {
            if let indexPath = self.inicidentTableView.indexPathForSelectedRow {
                let controller = segue.destination as! IncidentDetailsController
                controller.incident = player!.incident[indexPath.row]
            }
        }
    }
    
    private func get_cases() {
        let params = [:] as Dictionary<String, String>
        var url = URLComponents(string: Constants.apiEndpoint + "cases")!

        url.queryItems = [
            URLQueryItem(name: "subject_uuid", value: player?.id)
        ]
        var request = URLRequest(url: url.url!)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue((model.session?.idToken!.tokenString)!, forHTTPHeaderField: "Authorization")
        os_log("Getting list of cases for player: %s", type: .debug, player!.id)
        
        let session = URLSession.shared
        let task = session.dataTask(with: request, completionHandler: { data, response, error -> Void in
            do {
                let json = try JSONSerialization.jsonObject(with: data!) as! Dictionary<String, AnyObject>
                if (json.keys.contains("Items")) {
                    os_log("List of cases for player %s received", type: .debug, self.player!.id)
                    let items = json["Items"] as! Array<Dictionary<String, AnyObject>>
                    self.model.load_cases(player: self.player!, cases: items)
                    DispatchQueue.main.async {
                        self.inicidentTableView.reloadData()
                        self.alert?.dismiss(animated: true, completion: {
                            
                        })
                        UIApplication.shared.endIgnoringInteractionEvents()
                    }
                } else {
                    os_log("Error: %s", type: .error, json.debugDescription)
                    if (json.keys.contains("errorMessage")) {
                        let msg = json["errorMessage"] as? String
                        DispatchQueue.main.async {
                            self.alert?.dismiss(animated: true, completion: {
                                AlertService.showAlert(style: .alert, title: "Error", message: msg)
                            })
                            UIApplication.shared.endIgnoringInteractionEvents()
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.alert?.dismiss(animated: true, completion: {
                                AlertService.showAlert(style: .alert, title: "Error", message: Constants.access_account_error)
                            })
                            UIApplication.shared.endIgnoringInteractionEvents()
                        }
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.alert?.dismiss(animated: true, completion: {
                        AlertService.showAlert(style: .alert, title: "Error", message: Constants.access_account_error)
                    })
                    UIApplication.shared.endIgnoringInteractionEvents()
                }
            }
        })
        task.resume()
    }
}

extension PlayerDetailsController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.player!.incident.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let incident = self.player!.incident[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "incidentCell") as! IncidentTableViewCell
        cell.setStatus(status: incident.resolution)
        cell.setTimestamp(date: incident.timestamp)
        return cell
    }
}
*/

