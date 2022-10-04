//
//  ViewController.swift
//  retina
//
//  Created by George Morariu on 5/17/21.
//  Copyright © 2021 George Morariu. All rights reserved.
//

import UIKit
import os.log

class PlayersViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    
    var alert: UIAlertController?
    var players: [Player] = []
    let dataModel = DataModel.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.separatorColor = .clear
        players = dataModel.players
        tableView.delegate = self
        tableView.dataSource = self
        //get_subjects()
        //tableView.reloadData()
        //
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        players = dataModel.players
        get_subjects()
        //tableView.reloadData()
    }
    
    /*override func viewDidAppear(_ animated: Bool) {
        tableView.reloadData()
    }*/
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        /*if segue.identifier == "playerDetailsOld" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                let controller = segue.destination as! PlayerDetailsController
                controller.player = players[indexPath.row]
            }
        }*/
        if segue.identifier == "playerDetails" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                let controller = segue.destination as! PlayerDetailsTabController
                controller.player = players[indexPath.row]
            }
        }
        if segue.identifier == "addPlayerDetails" {
            let controller = segue.destination as! CreatePlayerBasicInfoVC
            controller.player = Player()
        }
    }
    
    @IBAction func onSettingsPressed(_ sender: Any) {
        
    }
    
    @IBAction func onAddPressed(_ sender: Any) {
        //self.performSegue(withIdentifier: "addPlayerOld", sender: self)
        self.performSegue(withIdentifier: "addPlayerDetails", sender: self)
    }
    
    private func get_subjects() {
        DispatchQueue.main.async {
            self.alert = AlertService.showProgressAlert(parentViewController: self)
            UIApplication.shared.beginIgnoringInteractionEvents()
        }
        var request = URLRequest(url: URL(string: Constants.apiEndpoint + "subjects")!)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue((dataModel.session?.idToken!.tokenString)!, forHTTPHeaderField: "Authorization")
        os_log("Requesting with authorization: %s", type: .debug, (dataModel.session?.idToken!.tokenString)!)
        let session = URLSession.shared
        let task = session.dataTask(with: request, completionHandler: { data, response, error -> Void in
            do {
                var json = [:] as Dictionary<String, AnyObject>
                if data != nil {
                    json = try JSONSerialization.jsonObject(with: data!) as! Dictionary<String, AnyObject>
                }
                //let json = try JSONSerialization.jsonObject(with: data!) as! Dictionary<String, AnyObject>
                if (json.keys.contains("Items")) {
                    let items = json["Items"] as! Array<Dictionary<String, AnyObject>>
                    self.dataModel.load(subjects: items)
                    self.players = self.dataModel.players
                    os_log("Got items")
                    DispatchQueue.main.async {
                        self.alert?.dismiss(animated: true, completion: {
                            self.alert = nil
                            os_log("Alert dismissed", type: .debug)
                            self.tableView.reloadData()
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

extension PlayersViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        players.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let player = players[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "playersCell") as! PlayersTableViewCell
        cell.setNumber(number: player.number)
        cell.setName(firstName: player.firstName, lastName: player.lastName)
        cell.setFace(faceData: player.faceData)
        return cell
    }
}
