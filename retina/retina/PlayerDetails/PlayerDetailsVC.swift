//
//  PlayerDetailsVC.swift
//  retina
//
//  Created by George Morariu on 9/21/21.
//  Copyright © 2021 George Morariu. All rights reserved.
//

import UIKit
import AWSS3
import os.log

class PlayerDetailsVC: UIViewController {
    @IBOutlet weak var btnFace: UIButton!
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var lblDOB: UILabel!

    @IBOutlet weak var btnMale: UIButton!
    @IBOutlet weak var btnFemale: UIButton!
    
    @IBOutlet weak var lblTeamNumber: UILabel!
    @IBOutlet weak var lblECName: UILabel!
    @IBOutlet weak var lblECRelation: UILabel!
    @IBOutlet weak var lblECPhone: UILabel!
    @IBOutlet weak var btnCallECPhone: UIButton!
    //@IBOutlet weak var lblPupilReponse: UILabel!
    @IBOutlet weak var btnPupilResponseVideo: UIButton!
    @IBOutlet weak var btnPupilResponsePlay: UIButton!
    @IBOutlet weak var btnRecordPupilResponse: UIButton!
    
    @IBOutlet weak var lblProccesingVideo: UILabel!
    
    @IBOutlet weak var btnAction: UIBarButtonItem!
    @IBOutlet weak var navbar: UINavigationItem!
    
    @IBOutlet weak var btnTabItem: UITabBarItem!
    
    
    let model = DataModel.shared
    var alert: UIAlertController?
    var player :Player? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.btnMale.setImage(UIImage(named: "male")!.withRenderingMode(.alwaysTemplate), for: .normal)
        self.btnFemale.setImage(UIImage(named: "female")!.withRenderingMode(.alwaysTemplate), for: .normal)
        btnMale.tintColor = .gray
        btnFemale.tintColor = .gray
        self.tabBarItem.selectedImage = UIImage(named: "player")!.withRenderingMode(.alwaysOriginal)
        self.player = (self.parent as! PlayerDetailsTabController).player
        
        navbar.title = (player?.firstName ?? "") + " " + (player?.lastName ?? "")
        //btnAction.title = "Edit"
        lblName.text = (player?.firstName ?? "") + " " + (player?.lastName ?? "")
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/YYYY"
        lblDOB.text = dateFormatter.string(from: player?.dob ?? Date())
        if player?.gender.lowercased() == "male" {
            btnMale.isSelected = true
            btnFemale.isSelected = false
        } else {
            btnMale.isSelected = false
            btnFemale.isSelected = true
        }
        lblTeamNumber.text = player?.number ?? ""
        lblECName.text = player?.emergencyName ?? ""
        lblECRelation.text = player?.emergencyRelation ?? ""
        lblECPhone.text = formatPhone(phone: player?.emergencyPhone ?? "")
        //self.lblPupilReponse.isHidden = true
        self.btnPupilResponseVideo.isHidden = true
        
        btnFace.imageView?.layer.cornerRadius = (btnFace.imageView?.frame.height)!/2;
        btnFace.imageView?.layer.masksToBounds = true;
        btnFace.imageView?.layer.borderWidth = 0;
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if self.btnPupilResponseVideo == nil {
            return
        }
        self.btnPupilResponseVideo.setImage(nil, for: .normal)
        self.btnPupilResponseVideo.isHidden = true
        btnRecordPupilResponse.isHidden = true
        lblProccesingVideo.text = "Proccessing video..."
        if self.player?.baseline?.resolution == .noConcussion {
            if self.player?.baseline?.thumbnailURL != nil {
                if self.player?.baseline?.thumbnailData != nil {
                    let thumbImage = UIImage(data: (self.player?.baseline?.thumbnailData!)!)
                    self.btnPupilResponseVideo.setImage(thumbImage, for: .normal)
                    self.btnPupilResponseVideo.isHidden = false
                    self.btnRecordPupilResponse.isHidden = false
                }
            }
        } else {
            if self.player?.baseline?.resolution == .insufficientData {
                lblProccesingVideo.text = "Low quality video. Please record the baseline video again."
                self.btnRecordPupilResponse.isHidden = false
            }
        }
        
        btnPupilResponsePlay.isHidden = btnPupilResponseVideo.isHidden
        lblProccesingVideo.isHidden = !btnPupilResponseVideo.isHidden
        
        if self.player?.faceData != nil {
            let faceImage = UIImage(data: (self.player?.faceData!)!)
            self.btnFace.setImage(faceImage, for: .normal)
        }
        //(self.parent as! PlayerDetailsTabController).btnEditPlayer.title = "Edit"
        self.view.layoutIfNeeded()
    }
    
    @IBAction func onPupilResponsePressed(_ sender: Any) {
        if player?.baseline?.recordingURL != nil {
            self.performSegue(withIdentifier: "showVideoPlayer", sender: self)
        }
    }
    @IBAction func onDeletePressed(_ sender: Any) {
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { (action) in
            self.alert = AlertService.showProgressAlert()
            UIApplication.shared.beginIgnoringInteractionEvents()
            self.delete_subject(player: self.player!)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        AlertService.showAlert(style: .alert, title: "Are you sure?", message: "Deleting this player will remove it from the team", actions: [deleteAction, cancelAction], completion: nil)
    }
    
    @IBAction func onActionPressed(_ sender: Any) {
        //self.alert = AlertService.showProgressAlert()
        //UIApplication.shared.beginIgnoringInteractionEvents()
        returnToMainScreen()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showVideoPlayer" {
            let controller = segue.destination as! VideoPlayerController
            controller.url = URL(string: player!.baseline!.recordingURL!)
        }
    }
    
    private func returnToMainScreen() {
        let viewControllers: [UIViewController] = self.navigationController!.viewControllers ;
        for aViewController in viewControllers {
            if(aViewController is PlayersViewController){
               self.navigationController!.popToViewController(aViewController, animated: true);
            }
        }
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
                os_log("Player deleted")
                DispatchQueue.main.async {
                    self.alert?.dismiss(animated: true, completion: {
                        self.model.deletePlayer(player: player)
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
    
    @IBAction func onMalePressed(_ sender: Any) {
        /*if !btnMale.isSelected {
            btnMale.isSelected = true
            btnFemale.isSelected = false
        }*/
    }
    
    
    
    @IBAction func onFemalePressed(_ sender: Any) {
        /*if !btnFemale.isSelected {
            btnMale.isSelected = false
            btnFemale.isSelected = true
        }*/
    }
    
    func formatPhone(phone: String) -> String {
        if phone.count != 10 {
            return phone
        }
        var p = phone
        p.insert("(", at: p.startIndex)
        p.insert(")", at: p.index(phone.startIndex, offsetBy: 4))
        p.insert(" ", at: p.index(phone.startIndex, offsetBy: 5))
        p.insert("-", at: p.index(phone.startIndex, offsetBy: 9))
        return p
    }
    
    @IBAction func onRecordPupilResponsePressed(_ sender: Any) {
        //let page = CreatePlayerVideoIntroVC()
        
        let storyBoard: UIStoryboard = UIStoryboard(name: "CreatePlayer", bundle: nil)
        let page = storyBoard.instantiateViewController(withIdentifier: "CreatePlayerVideoIntro") as! CreatePlayerVideoIntroVC
        page.player = self.player
                //self.present(newViewController, animated: true, completion: nil)
        self.navigationController?.pushViewController(page, animated: true)
        //self.navigationController?.pushViewController(newViewController, animated: true)
        //present(page, animated: true, completion: nil)
    }
    
    @IBAction func onCallECPhone(_ sender: Any) {
        let urlstr = "telprompt://\(player?.emergencyPhone ?? "")"
        if let phoneCallURL = URL(string: urlstr) {
            let application:UIApplication = UIApplication.shared
            if (application.canOpenURL(phoneCallURL)) {
                if #available(iOS 10.0, *) {
                    application.open(phoneCallURL, options: [:], completionHandler: nil)
                } else {
                    // Fallback on earlier versions
                     application.openURL(phoneCallURL as URL)
                }
            }
        }
    }
    
}
