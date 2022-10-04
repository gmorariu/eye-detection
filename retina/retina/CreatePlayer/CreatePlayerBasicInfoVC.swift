//
//  CreatePlayerBasicInfoVC.swift
//  retina
//
//  Created by George Morariu on 9/17/21.
//  Copyright © 2021 George Morariu. All rights reserved.
//

import UIKit
import os.log

class CreatePlayerBasicInfoVC: UITableViewController {
    private let genderPickerChoices = ["Choose...", "Male", "Female"]
    
    var player : Player? = nil
    let model = DataModel.shared
    var alert: UIAlertController?
    
    @IBOutlet weak var txtFirstName: UITextField!
    @IBOutlet weak var txtLastName: UITextField!
    @IBOutlet weak var pickerDOB: UIDatePicker!
    @IBOutlet weak var txtTeamNumber: UITextField!
    @IBOutlet weak var btnNext: UIBarButtonItem!
    @IBOutlet weak var pickerGender: UIPickerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        pickerGender.dataSource = self
        pickerGender.delegate = self
        txtFirstName.text = player!.firstName
        txtLastName.text = player!.lastName
        pickerDOB.date = player!.dob
        txtTeamNumber.text = player!.number
        if player!.gender.lowercased() == "male" {
            pickerGender.selectRow(1, inComponent: 0, animated: true)
        } else {
            pickerGender.selectRow(2, inComponent: 0, animated: true)
        }
    }
    
    @IBAction func onNextPressed(_ sender: Any) {
        player!.firstName = txtFirstName.text ?? ""
        player!.lastName = txtLastName.text ?? ""
        player!.dob = pickerDOB.date
        player!.number = txtTeamNumber.text ?? ""
        if pickerGender.selectedRow(inComponent: 0) > 0 {
            player!.gender = genderPickerChoices[pickerGender.selectedRow(inComponent: 0)]
        }
        self.performSegue(withIdentifier: "addPlayerEmContact", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "addPlayerEmContact" {
            let controller = segue.destination as! CreatePlayerEmergencyContactVC
            controller.player = self.player
        }
    }
    
}

extension CreatePlayerBasicInfoVC: UIPickerViewDataSource, UIPickerViewDelegate {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return genderPickerChoices.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return genderPickerChoices[row]
    }
}
