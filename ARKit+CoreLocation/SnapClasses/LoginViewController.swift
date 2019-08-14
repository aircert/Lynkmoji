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
import GooglePlacePicker
import GoogleMaps

class LoginViewController: UIViewController, UITextViewDelegate {
    // MARK: - Properties
    
    fileprivate static let DefaultMessage = """
The world's first way to hangout in the future
"""
    
    
    fileprivate static let DefaultMessageStatus = """
What we will do on the date is...
"""
    
    internal let kPlacesAPIKey = "AIzaSyCiKfvN9tKQdKYPi0fvUwcI2M8XYk3YYA0"
    
    @IBOutlet fileprivate weak var loginButton: UIButton?
    @IBOutlet fileprivate weak var messageLabel: UILabel?
    @IBOutlet fileprivate weak var loginView: UIView?
    @IBOutlet fileprivate weak var profileView: UIView?
    @IBOutlet fileprivate weak var avatarView: UIImageView?
    @IBOutlet weak var lynkAvatarView: UIImageView!
    @IBOutlet fileprivate weak var nameLabel: UILabel?
    @IBOutlet weak var lynkNameLabel: UILabel!
    @IBOutlet fileprivate weak var logoutButton: UINavigationItem?
    @IBOutlet weak var statusTextView: UITextView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var nearbyButton: UIBarButtonItem!
    
    @IBOutlet weak var letsLynkButton: UIButton!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var datePicker: UIDatePicker!
    
    let locationManager = CLLocationManager()
    
    var geoFireRef: DatabaseReference?
    var geoFire: GeoFire?
    var myQuery: GFQuery?
    
    var lynkDateTime: String?
    var lynkSubmitted: Bool?
    var lynkMapItem: MKMapItem?
    
    let userCache = NSCache<NSString, UserMKMapItem>()
    
    var lynks: [UserMKMapItem]? = []
    
    @IBAction func nearbyButtonTapped(_ sender: Any) {
        if CLLocationManager.locationServicesEnabled() {
            // go to settings view controller
            let settingsVC = UIStoryboard(name: "Main", bundle: nil)
                .instantiateViewController(withIdentifier: "SettingsViewController") as! SettingsViewController
            //            settingsVC.statusText = "room"
            self.navigationController?.pushViewController(settingsVC, animated: true)
        }
    }
    
    func createARVC() -> POIViewController {
        let arclVC = POIViewController.loadFromStoryboard()
        arclVC.showMap = true
        
        return arclVC
    }
    
    @objc func datePickerChanged(datePicker: UIDatePicker) {
        
        let dateFormatter = DateFormatter()
        
        dateFormatter.dateStyle = DateFormatter.Style.short
        
        dateFormatter.timeStyle = DateFormatter.Style.short
        
        let strDate = dateFormatter.string(from: datePicker.date)
        
        lynkDateTime = strDate
        
    }
}

// MARK: - Private Helpers

extension LoginViewController {
    fileprivate func displayForLogoutState() {
        // Needs to be on the main thread to control the UI.
        DispatchQueue.main.async {
            self.logoutButton?.rightBarButtonItem?.isEnabled = false
            self.loginView?.isHidden = false
            self.profileView?.isHidden = true
            self.nearbyButton.isEnabled = false
            self.mapView.isHidden = true
            self.messageLabel?.text = LoginViewController.DefaultMessage
        }
    }
    
    fileprivate func displayForLoginState(lynkSubmitted: Bool) {
        // Needs to be on the main thread to control the UI.
        DispatchQueue.main.async {
            self.logoutButton?.rightBarButtonItem?.isEnabled = true
            self.loginView?.isHidden = true
            self.nearbyButton.isEnabled  = true
            self.profileView?.isHidden = false
            self.mapView.isHidden = true
            self.messageLabel?.text = LoginViewController.DefaultMessage
            
            if(lynkSubmitted) {
                self.datePicker.isHidden = true
                if let dateTime = self.lynkDateTime {
                    self.dateLabel.text = "Lynk Set For \(dateTime)"
                }
                self.letsLynkButton.isHidden = true
                let annotation = UserPointAnnotation()
                annotation.coordinate = self.lynkMapItem!.placemark.coordinate
                self.mapView.isHidden = false
                self.mapView.showAnnotations([annotation], animated: true)
                
                
                print("lynk submitted")
            }
//            self.loadLynks()
        }
        
        
        
        Auth.auth().signInAnonymously() { (authResult, error) in
            self.displayProfile(uid: (authResult?.user.uid)!)
            //            self.selectLynk()
        }
        
        
        
       
    }
    
    fileprivate func displayProfile(uid: String) {
        let successBlock = { (response: [AnyHashable: Any]?) in
            guard let response = response as? [String: Any],
                let data = response["data"] as? [String: Any],
                let me = data["me"] as? [String: Any],
                let displayName = me["displayName"] as? String,
                let bitmoji = me["bitmoji"] as? [String: Any],
                let roomID = me["externalID"] as? String?,
                let avatar = bitmoji["avatar"] as? String else {
                    return
            }

            // Needs to be on the main thread to control the UI.
            DispatchQueue.main.async {
                self.loadAndDisplayAvatar(url: URL(string: avatar))
                self.nameLabel?.text = displayName
                self.geoFireRef?.child(uid).setValue(response)
//                self.geoFireRef?.child(uid).setValue(["roomID": roomID])
            }
//            self.loadLynks()
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
    
    fileprivate func loadLynks() {
        myQuery = geoFire?.query(at: CLLocation(coordinate: self.locationManager.location!.coordinate, altitude: 0.5), withRadius: 10)
        myQuery?.observe(.keyEntered, with: { (key, location) in
            Database.database().reference().child("users").child(key).observe(.value, with: { (snapshot) in
                let userDict = snapshot.value as? [String : AnyObject] ?? [:]
                if let data = userDict["data"] {
                    let me = data["me"] as! [String : AnyObject]
                    
                    if((self.userCache.object(forKey: key as NSString)) == nil && key != Auth.auth().currentUser?.uid) {
                        let lynk = UserMKMapItem(coordinate: location.coordinate, profileFileURL: me["bitmoji"]?["avatar"] as! String, title: me["displayName"] as! String, roomID: me["externalId"] as! String)
                        self.lynks?.append(lynk)
                        self.userCache.setObject(lynk, forKey: key as NSString)
                    } else if(key != Auth.auth().currentUser?.uid) {
//                        self.selectLynk()
                    }
                } else {
                    return
                }
                
            })
        })
        
        myQuery?.observeReady{
//            self.selectLynk()
        }
    }
    
    func selectLynk() {
        print("here")
        if self.lynks!.count > 0 {
            let lynk = lynks?.last
            avatarView?.image = lynk?.profileImage
            nameLabel?.text = lynk?.annotation?.title
//            mapView.addAnnotation(lynk!.annotation!)
            
//            let region = MKCoordinateRegion(
//                center: lynk!.annotation!.coordinate, latitudinalMeters: 200, longitudinalMeters: 200)
//            mapView.setRegion(region, animated: true)
//
//            let myAnnoation = MKPointAnnotation()
//            myAnnoation.coordinate = myLocation.coordinate
//            mapView.addAnnotation(myAnnoation)
//            mapView.setCenter(myLocation.coordinate, animated: true)
//            lynks?.removeLast()
        }
    }
    
    func getDirections(to mapLocation: UserMKMapItem, roomID: String) {
//        refreshControl.startAnimating()
        
        let request = MKDirections.Request()
        request.source = MKMapItem.forCurrentLocation()
        request.destination = mapLocation
        request.requestsAlternateRoutes = false
        
        let directions = MKDirections(request: request)
        
        directions.calculate(completionHandler: { response, error in
            defer {
                DispatchQueue.main.async { [weak self] in
//                    self?.refreshControl.stopAnimating()
                }
            }
            if let error = error {
                return print("Error getting directions: \(error.localizedDescription)")
            }
            guard let response = response else {
                return assertionFailure("No error, but no response, either.")
            }
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else {
                    return
                }
                
                let arclVC = self.createARVC()
                arclVC.routes = response.routes
                arclVC.targetUser = mapLocation
                arclVC.targetUser?.annotation = mapLocation.annotation
                
                //                let cameraVC = self.createCameraVC()
                //                cameraVC.roomID = roomID
                
                self.navigationController?.pushViewController(arclVC, animated: true)
            }
        })
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
            textView.text = "" //self.statusTextView.text
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
                self.displayForLoginState(lynkSubmitted: false)
            }
            if let error = error {
                // Needs to be on the main thread to control the UI.
                DispatchQueue.main.async {
                    self.messageLabel?.text = String.init(format: "Login failed. Details: %@", error.localizedDescription)
                }
            }
        }
    }
    
    @IBAction func nearbyButtonDidTap(_ sender: UIButton) {
        
        if CLLocationManager.locationServicesEnabled() {
            // go to settings view controller
            let settingsVC = UIStoryboard(name: "Main", bundle: nil)
                .instantiateViewController(withIdentifier: "SettingsViewController") as! SettingsViewController
            //            settingsVC.statusText = "room"
//            settingsVC.currentLocation = self.locationManager.location
            self.navigationController?.pushViewController(settingsVC, animated: true)
        }
    }
    
    @IBAction func goOnlineButtonDidTap(_ sender: UIButton) {
        
        if CLLocationManager.locationServicesEnabled() {
            // go to settings view controller
            let settingsVC = UIStoryboard(name: "Main", bundle: nil)
                .instantiateViewController(withIdentifier: "SearchResultTableViewController") as! SearchResultTableViewController
            settingsVC.lynkDateTime = self.lynkDateTime
            settingsVC.currentLocation = self.locationManager.location
            self.navigationController?.pushViewController(settingsVC, animated: true)
//            getDirections(to: lynks!.first!, roomID: "room")
        }
//        let config = GMSPlacePickerConfig(viewport: nil)
//        let placePicker = GMSPlacePickerViewController(config: config)
//
//        present(placePicker, animated: true, completion: nil)
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
        
        datePicker.addTarget(self, action: #selector(datePickerChanged), for: UIControl.Event.valueChanged)
        
//        GMSPlacesClient.provideAPIKey(kPlacesAPIKey)
//        GMSServices.provideAPIKey(kPlacesAPIKey)
        
//        geoFireRef = Database.database().reference().child("users")
//        geoFire = GeoFire(firebaseRef: geoFireRef!)
        
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.headingFilter = kCLHeadingFilterNone
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.delegate = self
        locationManager.startUpdatingHeading()
        locationManager.startUpdatingLocation()
        
//        statusTextView.delegate = self
//        statusTextView.text = LoginViewController.DefaultMessageStatus
//        statusTextView.textColor = UIColor.lightGray
//        statusTextView.layer.borderWidth = 1.0
//        statusTextView.layer.borderColor = UIColor.lightGray.cgColor
        
        if SCSDKLoginClient.isUserLoggedIn {
            locationManager.requestWhenInUseAuthorization()
            displayForLoginState(lynkSubmitted: lynkSubmitted ?? false)
        } else {
            displayForLogoutState()
        }
    }

}

@available(iOS 11.0, *)
extension LoginViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last,
            let userID = Auth.auth().currentUser?.uid
            else { return }
        self.geoFire?.setLocation(location, forKey: userID)
    }
}

