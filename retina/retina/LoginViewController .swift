//
//  LoginViewController.swift
//  retina
//
//  Created by George Morariu on 8/23/21.
//  Copyright © 2021 George Morariu. All rights reserved.
//

import UIKit
import os.log
import AWSCognitoIdentityProvider
import AWSS3

class LoginViewController: UIViewController {
    
    
    let model = DataModel.shared
    var alert: UIAlertController?
    var awsS3Initialized = false
    
    @IBOutlet weak var txtEmail: UITextField!
    @IBOutlet weak var txtPassword: UITextField!
    @IBOutlet weak var lblError: UILabel!
    @IBOutlet weak var txtSignupFirstName: UITextField!
    @IBOutlet weak var txtSignupLastName: UITextField!
    @IBOutlet weak var txtSignupPhone: UITextField!
    @IBOutlet weak var txtSignupEmail: UITextField!
    @IBOutlet weak var txtSignupPassword: UITextField!
    @IBOutlet weak var txtConfirmationCode: UITextField!
    @IBOutlet weak var formLogin: UIStackView!
    @IBOutlet weak var formSignup: UIStackView!
    @IBOutlet weak var formConfirm: UIStackView!
    
    @objc lazy var transferUtility = {
        AWSS3TransferUtility.default()
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        formLogin.isHidden = true
        formSignup.isHidden = true
        formConfirm.isHidden = true
        lblError.isHidden = true
        
        txtSignupFirstName.text = "George"
        txtSignupLastName.text = "Morariu"
        txtSignupPhone.text = "+14085477900"
        txtSignupEmail.text = "morariu.george+4@gmail.com"
        txtSignupPassword.text = "Test-1234"
        txtEmail.text = "morariu.george+3@gmail.com"
        //txtPassword.text = "Test-1234"
        
        /*let cognitoAuth = AWSCognitoAuth.default()
        cognitoAuth.getSession(self)  { (session:AWSCognitoAuthUserSession?, error:Error?) in
          if(error != nil) {
            print((error! as NSError).userInfo["error"] as? String)
           }else {
           //Do something with session
          }
        }*/
    }
    override func viewDidAppear(_ animated: Bool) {
        initAWS()
        if (model.user?.isSignedIn == true) {
            //self.model.signOut()
            login()
        } else {
            formLogin.isHidden = false
        }
        
    }
    
    
    @IBAction func onLoginPressed(_ sender: Any) {
        login()
    }

    
    @IBAction func onLoginSignupPressed(_ sender: Any) {
        formLogin.isHidden = true
        formSignup.isHidden = false
        formConfirm.isHidden = true
    }
    
    @IBAction func onSignupCancelPressed(_ sender: Any) {
        formLogin.isHidden = false
        formSignup.isHidden = true
        formConfirm.isHidden = true
    }
    
    @IBAction func onSignupPressed(_ sender: Any) {
        if (txtSignupFirstName.text?.isEmpty != false) {
            return
        }
        if (txtSignupLastName.text?.isEmpty != false) {
            return
        }
        if (txtSignupPhone.text?.isEmpty != false) {
            return
        }
        if (txtSignupEmail.text?.isEmpty != false) {
            return
        }
        if (txtSignupPassword.text?.isEmpty != false) {
            return
        }
        
        self.alert = AlertService.showProgressAlert()
        UIApplication.shared.beginIgnoringInteractionEvents()
        
        
        let attributes: [AWSCognitoIdentityUserAttributeType] = [AWSCognitoIdentityUserAttributeType(name: "email", value: txtSignupEmail.text!), AWSCognitoIdentityUserAttributeType(name: "given_name", value: txtSignupFirstName.text!), AWSCognitoIdentityUserAttributeType(name: "family_name", value: txtSignupLastName.text!), AWSCognitoIdentityUserAttributeType(name: "phone_number", value: txtSignupPhone.text!) ]
        let username = txtSignupEmail.text!.components(separatedBy: "@")[0]
        model.pool?.signUp(username, password: txtSignupPassword.text!, userAttributes: attributes, validationData: nil).continueWith(executor: AWSExecutor.mainThread(), block: { (task:AWSTask!) -> Any? in
            os_log("Sign up task: %s", type: .debug, task.debugDescription)
            UIApplication.shared.endIgnoringInteractionEvents()
            if task.error == nil {
                self.model.user = task.result?.user
                self.alert?.dismiss(animated: true, completion: {
                    self.formLogin.isHidden = true
                    self.formSignup.isHidden = true
                    self.formConfirm.isHidden = false
                    //self.performSegue(withIdentifier: "showConfirmation", sender: self)
                })
            } else {
                os_log("Sign up error: %s", type: .error, task.error.debugDescription )
                var s = task.error.debugDescription.components(separatedBy: "{")[1]
                s = s.components(separatedBy: "}")[0]
                s = s.components(separatedBy: "=")[2]
                self.alert?.dismiss(animated: true, completion: {
                    //self.txtError.text = s
                })
            }
            return nil
        })
        
    }
    @IBAction func onConfirmPressed(_ sender: Any) {
        if (txtConfirmationCode.text?.isEmpty != false) {
            return
        }
        self.alert = AlertService.showProgressAlert()
        UIApplication.shared.beginIgnoringInteractionEvents()
        model.user?.confirmSignUp(txtConfirmationCode.text!).continueWith(executor: AWSExecutor.mainThread(), block: { (task:AWSTask!) -> Any? in
            os_log("Confirmation task: %s", type: .debug, task.debugDescription)
            if task.error == nil {
                UIApplication.shared.endIgnoringInteractionEvents()
                self.alert?.dismiss(animated: true, completion: {
                    self.txtEmail = self.txtSignupEmail
                    self.txtPassword = self.txtSignupPassword
                    self.login()
                    //self.performSegue(withIdentifier: "showAuth2", sender: self)
                    
                })
            } else {
                os_log("Confirmation error: %s", type: .error, task.error.debugDescription )
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
    
    @IBAction func onConfirmCancelPressed(_ sender: Any) {
        formLogin.isHidden = false
        formConfirm.isHidden = true
    }
    

    private func initAWS() {
        if (!model.awsInitialized) {
            let cf = AWSServiceConfiguration.init(region: Constants.region, credentialsProvider: nil)
            AWSServiceManager.default().defaultServiceConfiguration = cf
            let config: AWSCognitoIdentityUserPoolConfiguration = AWSCognitoIdentityUserPoolConfiguration.init(clientId: Constants.clientId, clientSecret: Constants.clientSecret, poolId: Constants.poolId)
            AWSCognitoIdentityUserPool.register(with: cf, userPoolConfiguration: config, forKey: "UserPool")
            model.pool = AWSCognitoIdentityUserPool(forKey: "UserPool")
            model.credentialsProvider = AWSCognitoCredentialsProvider(regionType: Constants.region, identityPoolId: Constants.identityPoolId, identityProviderManager: model.pool)
            let cf1 = AWSServiceConfiguration(region: Constants.region, credentialsProvider: model.credentialsProvider)
            AWSServiceManager.default().defaultServiceConfiguration = cf1
            model.awsInitialized = true
        } else {
            model.pool = AWSCognitoIdentityUserPool(forKey: "UserPool")
            model.credentialsProvider = AWSCognitoCredentialsProvider(regionType: Constants.region, identityPoolId: Constants.identityPoolId, identityProviderManager: model.pool)
            let cf1 = AWSServiceConfiguration(region: Constants.region, credentialsProvider: model.credentialsProvider)
            AWSServiceManager.default().defaultServiceConfiguration = cf1
        }
        model.user = model.pool?.currentUser()
        os_log("User signed in: %s", type: .debug, model.user?.isSignedIn.description ?? "false")
    }
    
    private func login() {
        //txtError.text = ""
        var session = model.user?.getSession()
        if ((self.txtEmail.text?.isEmpty == false) && (self.txtPassword.text?.isEmpty == false)) {
            session = model.user?.getSession(self.txtEmail.text ?? "", password: self.txtPassword.text ?? "", validationData: nil)
        }
        os_log("Session status: %s", type: .debug, session.debugDescription)
        if (session?.isFaulted != false) {
            // We need a new session
            return
        }
        //viewForm.isHidden = true
        os_log("Show please wait 1", type: .debug)
        self.alert = AlertService.showProgressAlert()
        UIApplication.shared.beginIgnoringInteractionEvents()
        session?.continueWith(executor: AWSExecutor.mainThread(), block: { (task:AWSTask!) -> Any? in
            if task.error == nil {
                self.model.session = task.result
                //self.initAWSS3()
                self.getIdentityId()
                self.getUserDetails()
            } else {
                os_log("Login error: %s", type: .error, task.error.debugDescription )
                var s = task.error.debugDescription.components(separatedBy: "{")[1]
                s = s.components(separatedBy: "}")[0]
                let s1 = s.components(separatedBy: "=")
                if !s1.isEmpty {
                    
                    self.lblError.isHidden = false
                    self.lblError.text = s1.last
                }
                
                os_log("Hide please wait 1", type: .debug)
                self.alert?.dismiss(animated: true, completion: {
                    self.formLogin.isHidden = false
                    //self.viewForm.isHidden = false
                })
                UIApplication.shared.endIgnoringInteractionEvents()
                os_log("Error getting session: %s", type: .error, task.error.debugDescription)
            }
            return nil
        })
    }
    
    private func getUserDetails() {
        model.user?.getDetails().continueWith(executor: AWSExecutor.mainThread(), block: { (task:AWSTask!) -> Any? in
            if task.error == nil {
                self.model.userDetails = task.result
            } else {
                os_log("Error getting session: %s", type: .error, task.error.debugDescription)
            }
            return nil
        })
    }
    
    private func getIdentityId() {
        os_log("It's all good")
        model.credentialsProvider!.getIdentityId().continueWith(executor: AWSExecutor.mainThread(), block: { (task:AWSTask!) -> Any? in
            if task.error == nil {
                if (task.result != nil) {
                    self.model.identityId = String(task.result!)
                    self.launchMainScreen()
                    //self.model.load(completionHandler: self.launchMainScreen, errorHandler: self.networkError)
                    //self.get_subjects()
                    
                } else {
                    os_log("Error: IdentityId is empty", type: .error)
                }
            } else {
                os_log("Error getting IdentityId: %s", type: .error, task.error.debugDescription)
            }
            return nil
        })
    }
    
    
    
    private func launchMainScreen() {
        //initAWSS3()
        UIApplication.shared.endIgnoringInteractionEvents()
        os_log("Hide please wait 4", type: .debug)
        self.alert?.dismiss(animated: true, completion: {
            self.performSegue(withIdentifier: "showMainScreen", sender: self)
        })
        UIApplication.shared.endIgnoringInteractionEvents()
    }
    

    
}
