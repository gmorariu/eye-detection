//
//  AccountVC.swift
//  retina
//
//  Created by George Morariu on 10/4/21.
//  Copyright © 2021 George Morariu. All rights reserved.
//

import UIKit
import os.log
import AWSCognitoIdentityProvider

class AccountVC: UIViewController {

    
    @IBOutlet weak var btnSignOut: UIButton!
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var txtPhone: UITextField!
    @IBOutlet weak var btnSave: UIBarButtonItem!
    
    var alert: UIAlertController?
    
    let dataModel = DataModel.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let attrs = dataModel.userDetails!.userAttributes!
        var fn:String = ""
        var ln:String = ""
        for a in attrs {
            if a.name == "given_name" {
                fn = a.value!
            }
            if a.name == "family_name" {
                ln = a.value!
            }
            if a.name == "phone_number" {
                txtPhone.text = a.value
            }
        }
        lblName.text = fn + " " + ln
        btnSave.isEnabled = false
        btnSave.tintColor = .clear
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        /*if segue.identifier == "showVideoPlayer" {
            let controller = segue.destination as! VideoPlayerController
            controller.url = URL(string: incident!.recordingURL!)
        }*/
    }
    
    @IBAction func onSignOutPressed(_ sender: Any) {
        dataModel.signOut()
    }
    
    @IBAction func onPhoneChanged(_ sender: Any) {
        btnSave.isEnabled = true
        btnSave.tintColor = nil
    }
    
    @IBAction func onSavePressed(_ sender: Any) {
        updateUserAttributes()
    }
    
    private func updateUserAttributes() {
        self.alert = AlertService.showProgressAlert()
        UIApplication.shared.beginIgnoringInteractionEvents()
        
        var attrs:[AWSCognitoIdentityUserAttributeType] = []
        attrs.append(AWSCognitoIdentityUserAttributeType(name: "phone_number", value: txtPhone.text!))
        dataModel.user?.update(attrs).continueWith(executor: AWSExecutor.mainThread(), block: { (task:AWSTask!) -> Any? in
            os_log("Update task: %s", type: .debug, task.debugDescription)
            if task.error == nil {
                UIApplication.shared.endIgnoringInteractionEvents()
                self.alert?.dismiss(animated: true, completion: {
                    self.getUserDetails()
                    self.navigationController?.popViewController(animated: true)
                })
            } else {
                os_log("Update error: %s", type: .error, task.error.debugDescription )
                var s = task.error.debugDescription.components(separatedBy: "{")[1]
                s = s.components(separatedBy: "}")[0]
                s = s.components(separatedBy: "=")[2]
                //self.txtError.text = s
                self.alert?.dismiss(animated: true, completion: {
                    //self.txtError.text = s
                })
            }
            return nil
        })
    }
    
    private func getUserDetails() {
        dataModel.user?.getDetails().continueWith(executor: AWSExecutor.mainThread(), block: { (task:AWSTask!) -> Any? in
            if task.error == nil {
                self.dataModel.userDetails = task.result
            } else {
                os_log("Error getting session: %s", type: .error, task.error.debugDescription)
            }
            return nil
        })
    }
}

