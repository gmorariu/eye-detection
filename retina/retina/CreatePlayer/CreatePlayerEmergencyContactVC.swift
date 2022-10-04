//
//  CreatePlayerEmergencyContactVC.swift
//  retina
//
//  Created by George Morariu on 9/17/21.
//  Copyright © 2021 George Morariu. All rights reserved.
//

import UIKit
import os.log

class CreatePlayerEmergencyContactVC: UITableViewController {
    private let relationPickerChoices = ["Choose...", "Parent", "Spouse", "Sibling", "Relative", "Other"]
    
    var player : Player? = nil
    let model = DataModel.shared
    var alert: UIAlertController?
    
    @IBOutlet weak var txtName: UITextField!
    @IBOutlet weak var pickerRelation: UIPickerView!
    @IBOutlet weak var txtPhone: UITextField!
    @IBOutlet weak var btnNext: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        pickerRelation.dataSource = self
        pickerRelation.delegate = self
        txtName.text = player!.emergencyName
        txtPhone.text = player!.emergencyPhone
        switch player!.emergencyRelation {
        case relationPickerChoices[1]:
            pickerRelation.selectRow(1, inComponent: 0, animated: true)
            break
        case relationPickerChoices[2]:
            pickerRelation.selectRow(2, inComponent: 0, animated: true)
            break
        case relationPickerChoices[3]:
            pickerRelation.selectRow(3, inComponent: 0, animated: true)
            break
        case relationPickerChoices[4]:
            pickerRelation.selectRow(4, inComponent: 0, animated: true)
            break
        case relationPickerChoices[5]:
            pickerRelation.selectRow(5 , inComponent: 0, animated: true)
            break
        default:
            pickerRelation.selectRow(0, inComponent: 0, animated: true)
            
        }
    }
    
    @IBAction func onNextPressed(_ sender: Any) {
        player!.emergencyName = txtName.text ?? ""
        player!.emergencyPhone = txtPhone.text ?? ""
        if pickerRelation.selectedRow(inComponent: 0) > 0 {
            player!.emergencyRelation = relationPickerChoices[pickerRelation.selectedRow(inComponent: 0)]
        }
        self.performSegue(withIdentifier: "addPlayerBaseVideo", sender: self)
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "addPlayerBaseVideo" {
            let controller = segue.destination as! CreatePlayerVideoIntroVC
            controller.player = self.player
        }
    }
}

extension CreatePlayerEmergencyContactVC: UIPickerViewDataSource, UIPickerViewDelegate {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return relationPickerChoices.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return relationPickerChoices[row]
    }
}
