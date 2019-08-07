//
//  LoginViewController.swift
//  LoginKitSample
//
//  Created by Samuel Chow on 1/9/19.
//  Copyright © 2019 Snap Inc. All rights reserved.
//

import UIKit
import CoreLocation
import SCSDKLoginKit
import GeoFire
import Firebase

class LoginViewController: UIViewController, UITextViewDelegate {
    // MARK: - Properties
    
    fileprivate static let DefaultMessage = """
Welcome to Lynk. The world's first way to date in the future
"""
    
    @IBOutlet fileprivate weak var loginButton: UIButton?
    @IBOutlet fileprivate weak var messageLabel: UILabel?
    @IBOutlet fileprivate weak var loginView: UIView?
    @IBOutlet fileprivate weak var profileView: UIView?
    @IBOutlet fileprivate weak var avatarView: UIImageView?
    @IBOutlet fileprivate weak var nameLabel: UILabel?
    @IBOutlet fileprivate weak var logoutButton: UINavigationItem?
    @IBOutlet weak var statusTextView: UITextView!
    
    let locationManager = CLLocationManager()
    
    var geoFireRef: DatabaseReference?
    var geoFire: GeoFire?
}

// MARK: - Private Helpers

extension LoginViewController {
    fileprivate func displayForLogoutState() {
        // Needs to be on the main thread to control the UI.
        DispatchQueue.main.async {
            self.logoutButton?.rightBarButtonItem?.isEnabled = false
            self.loginView?.isHidden = false
            self.profileView?.isHidden = true
            self.messageLabel?.text = LoginViewController.DefaultMessage
        }
    }
    
    fileprivate func displayForLoginState() {
        // Needs to be on the main thread to control the UI.
        DispatchQueue.main.async {
            self.logoutButton?.rightBarButtonItem?.isEnabled = true
            self.loginView?.isHidden = true
            self.profileView?.isHidden = false
            self.messageLabel?.text = LoginViewController.DefaultMessage
        }
        
        displayProfile()
    }
    
    fileprivate func displayProfile() {
        let successBlock = { (response: [AnyHashable: Any]?) in
            guard let response = response as? [String: Any],
                let data = response["data"] as? [String: Any],
                let me = data["me"] as? [String: Any],
                let displayName = me["displayName"] as? String,
                let bitmoji = me["bitmoji"] as? [String: Any],
                let avatar = bitmoji["avatar"] as? String else {
                    return
            }
            
            Auth.auth().signInAnonymously() { (authResult, error) in
                self.geoFireRef?.child((authResult?.user.uid)!).setValue(response)
            }
            
            // Needs to be on the main thread to control the UI.
            DispatchQueue.main.async {
                self.loadAndDisplayAvatar(url: URL(string: avatar))
                self.nameLabel?.text = displayName
            }
        }
        
        let failureBlock = { (error: Error?, success: Bool) in
            if let error = error {
                print(String.init(format: "Failed to fetch user data. Details: %@", error.localizedDescription))
            }
        }
        
        let queryString = "{me{externalId, displayName, bitmoji{avatar}}}"
        DispatchQueue.global().async {
            SCSDKLoginClient.fetchUserData(withQuery: queryString,
                                       variables: nil,
                                       success: successBlock,
                                       failure: failureBlock)
        }
    }
    
    fileprivate func loadAndDisplayAvatar(url: URL?) {
        DispatchQueue.global().async {
            guard let url = url,
                let data = try? Data(contentsOf: url),
                let image = UIImage(data: data) else {
                    return
            }
            
            // Needs to be on the main thread to control the UI.
            DispatchQueue.main.async {
                self.avatarView?.image = image
            }
        }
        
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == UIColor.lightGray {
            textView.text = ""
            textView.textColor = UIColor.black
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if(text == "\n") {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text == "" {
            textView.text = "What is your best pick-up line?"
            textView.textColor = UIColor.lightGray
        }
    }
    
}

// MARK: - Action Handlers

extension LoginViewController {
    @IBAction func loginButtonDidTap(_ sender: UIButton) {
        SCSDKLoginClient.login(from: self.navigationController!) { (success: Bool, error: Error?) in
            if success {
                // Needs to be on the main thread to control the UI.
                self.displayForLoginState()
            }
            if let error = error {
                // Needs to be on the main thread to control the UI.
                DispatchQueue.main.async {
                    self.messageLabel?.text = String.init(format: "Login failed. Details: %@", error.localizedDescription)
                }
            }
        }
    }
    
    @IBAction func goOnlineButtonDidTap(_ sender: UIButton) {
        if CLLocationManager.locationServicesEnabled() {
            // go to settings view controller
            let settingsVC = UIStoryboard(name: "Main", bundle: nil)
                .instantiateViewController(withIdentifier: "SettingsViewController") as! SettingsViewController
            settingsVC.statusText = statusTextView.text
            self.navigationController?.pushViewController(settingsVC, animated: true)
        }
    }
    
    @IBAction func logoutButtonDidTap(_ sender: UIBarButtonItem) {
        SCSDKLoginClient.unlinkAllSessions { (success: Bool) in
            self.displayForLogoutState()
        }
    }
}

// MARK: - UIViewController

extension LoginViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        geoFireRef = Database.database().reference().child("users")
        geoFire = GeoFire(firebaseRef: geoFireRef!)
        
        statusTextView.delegate = self
        statusTextView.text = "What is your best pick-up line?"
        statusTextView.textColor = UIColor.lightGray
        statusTextView.layer.borderWidth = 1.0
        statusTextView.layer.borderColor = UIColor.lightGray.cgColor
        
        if SCSDKLoginClient.isUserLoggedIn {
            displayForLoginState()
        } else {
            displayForLogoutState()
        }
    }
}

