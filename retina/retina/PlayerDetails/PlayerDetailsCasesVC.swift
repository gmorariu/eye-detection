//
//  PlayerDetailsCasesVC.swift
//  retina
//
//  Created by George Morariu on 9/21/21.
//  Copyright © 2021 George Morariu. All rights reserved.
//

import UIKit
import AWSS3
import os.log

class PlayerDetailsCasesVC: UIViewController {
    
    @IBOutlet weak var tblCases: UITableView!
    
    let model = DataModel.shared
    var alert: UIAlertController?
    var player :Player? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tabBarItem.selectedImage = UIImage(named: "diagnose")!.withRenderingMode(.alwaysOriginal)
        self.player = (self.parent as! PlayerDetailsTabController).player
        
        tblCases.delegate = self
        tblCases.dataSource = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //(self.parent as! PlayerDetailsTabController).btnEditPlayer.title = "Add"
    }
    
    @IBAction func addIncidentPressed(_ sender: Any) {
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        /*if segue.identifier == "playerEdit" {
            let controller = segue.destination as! AddPlayerController
            controller.originalPlayer = self.player
        } else*/
        
        if segue.identifier == "incidentVideo" {
            let controller = segue.destination as! CaptureVideoLeftIntroController
            controller.originalPlayer = self.player
        } else if segue.identifier == "incidentDetails" {
            if let indexPath = self.tblCases.indexPathForSelectedRow {
                let controller = segue.destination as! IncidentDetailsController
                controller.incident = player!.incident[indexPath.row]
            }
        }
    }
    
}

extension PlayerDetailsCasesVC: UITableViewDataSource, UITableViewDelegate {
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
