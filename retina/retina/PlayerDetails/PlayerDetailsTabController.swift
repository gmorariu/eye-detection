//
//  PlayerDetailsTabController.swift
//  Pods
//
//  Created by George Morariu on 9/21/21.
//

import UIKit
import os.log

class PlayerDetailsTabController: UITabBarController, UITabBarControllerDelegate {
    var player :Player? = nil
    let model = DataModel.shared
    var alert: UIAlertController?
    @IBOutlet weak var btnEditPlayer: UIBarButtonItem!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
        if player != nil {
            //self.get_cases()
            self.selectedIndex = 1
            btnEditPlayer.title = "Add"
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if player != nil {
            self.get_cases()
        }
    }
    
    
    @IBAction func onEditPlayerPressed(_ sender: Any) {
        if btnEditPlayer.title == "Edit" {
            performSegue(withIdentifier: "showCreatePlayer", sender: self)
        } else {
            performSegue(withIdentifier: "incidentVideo", sender: self)
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showCreatePlayer" {
            let controller = segue.destination as! CreatePlayerBasicInfoVC
            controller.player = player
        }
        
        if segue.identifier == "incidentVideo" {
            let controller = segue.destination as! CaptureVideoLeftIntroController
            controller.originalPlayer = self.player
        }
        
    }
    
    func get_cases() {
        /*if self.player!.incident.isEmpty == true {
            
        }*/
        
        DispatchQueue.main.async {
            self.alert = AlertService.showProgressAlert(parentViewController: self)
            UIApplication.shared.beginIgnoringInteractionEvents()
        }
        
        var url = URLComponents(string: Constants.apiEndpoint + "cases")!

        url.queryItems = [
            URLQueryItem(name: "subject_uuid", value: self.player!.id)
        ]
        var request = URLRequest(url: url.url!)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue((model.session?.idToken!.tokenString)!, forHTTPHeaderField: "Authorization")
        os_log("Getting list of cases for player: %s", type: .debug, self.player!.id)
        
        let session = URLSession.shared
        let task = session.dataTask(with: request, completionHandler: { data, response, error -> Void in
            do {
                let json = try JSONSerialization.jsonObject(with: data!) as! Dictionary<String, AnyObject>
                if (json.keys.contains("Items")) {
                    os_log("List of cases for player %s received", type: .debug, self.player!.id)
                    let items = json["Items"] as! Array<Dictionary<String, AnyObject>>
                    os_log("Response parsed", type: .debug)
                    self.model.load_cases(player: self.player!, cases: items)
                    os_log("Model refreshed", type: .debug)
                    DispatchQueue.main.async {
                        self.alert?.dismiss(animated: true, completion: {
                            self.alert = nil
                            os_log("Alert dismissed", type: .debug)
                            if self.viewControllers != nil {
                                for vc in self.viewControllers! {
                                    vc.viewDidAppear(true)
                                    if vc is PlayerDetailsCasesVC {
                                        let pdvc = vc as! PlayerDetailsCasesVC
                                        pdvc.tblCases.reloadData()
                                    }
                                }
                            }
                            //self.btnEditPlayer.title = "Edit"
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
    
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        
        if viewController is PlayerDetailsVC {
            self.btnEditPlayer.title = "Edit"
        } else {
            self.btnEditPlayer.title = "Add"
        }
    }
}
