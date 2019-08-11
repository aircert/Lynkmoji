//
//  SettingsViewController.swift
//  ARKit+CoreLocation
//
//  Created by Eric Internicola on 2/19/19.
//  Copyright © 2019 Project Dent. All rights reserved.
//

import CoreLocation
import MapKit
import UIKit
import GeoFire
import Firebase

@available(iOS 11.0, *)
class SettingsViewController: UIViewController {

    @IBOutlet weak var showMapSwitch: UISwitch!
    @IBOutlet weak var showRouteDirections: UISwitch!
    @IBOutlet weak var searchResultTable: UITableView!
    @IBOutlet weak var refreshControl: UIActivityIndicatorView!

    var locationManager = CLLocationManager()

    var mapSearchResults: [UserMKMapItem]? = []
    
    var statusText: String?

    var geoFireRef: DatabaseReference?
    var geoFire: GeoFire?
    var myQuery: GFQuery?
    
    let userCache = NSCache<NSString, UserMKMapItem>()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.headingFilter = kCLHeadingFilterNone
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.delegate = self
        locationManager.startUpdatingHeading()
        locationManager.startUpdatingLocation()

        locationManager.requestWhenInUseAuthorization()
        
        geoFireRef = Database.database().reference().child("users")
        geoFire = GeoFire(firebaseRef: geoFireRef!)
        
        self.searchResultTable.delegate = self
        self.searchResultTable.dataSource = self
        
        searchResultTable.register(UINib(nibName: "LocationCell", bundle: nil), forCellReuseIdentifier: "LocationCell")
        
        searchResultTable.rowHeight = UITableView.automaticDimension
        searchResultTable.estimatedRowHeight = 100
        searchResultTable.rowHeight = 100.0
        
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        self.geoFireRef?.child(Auth.auth().currentUser!.uid).updateChildValues(["statusText": self.statusText])
        if let location = self.locationManager.location {
            searchForUsers(location: location)
        }
    }

    @IBAction
    func toggledSwitch(_ sender: UISwitch) {
       if sender == showRouteDirections {
            searchResultTable.reloadData()
        }
    }
}

// MARK: - UITextFieldDelegate

@available(iOS 11.0, *)
extension SettingsViewController: UITextFieldDelegate {

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {

        if string == "\n" {
            DispatchQueue.main.async { [weak self] in
//                self?.searchForUsers(location: CLLocation)
            }
        }

        return true
    }

}

// MARK: - DataSource

@available(iOS 11.0, *)
extension SettingsViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return mapSearchResults?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LocationCell", for: indexPath)
        guard let mapSearchResults = mapSearchResults,
            indexPath.row < mapSearchResults.count,
            let locationCell = cell as? LocationCell else {
                return cell
        }
        locationCell.locationManager = locationManager
        locationCell.mapItem = mapSearchResults[indexPath.row]
        
        return locationCell
    }
}

// MARK: - UITableViewDelegate

@available(iOS 11.0, *)
extension SettingsViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let mapSearchResults = mapSearchResults, indexPath.row < mapSearchResults.count else {
            return
        }
        let selectedMapItem = mapSearchResults[indexPath.row]
        getDirections(to: selectedMapItem, roomID: selectedMapItem.roomID!)
    }

}

// MARK: - CLLocationManagerDelegate

@available(iOS 11.0, *)
extension SettingsViewController: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last,
            let userID = Auth.auth().currentUser?.uid
            else { return }
        self.geoFire?.setLocation(location, forKey: userID)
        self.searchForUsers(location: location)
    }
}

// MARK: - Implementation

@available(iOS 11.0, *)
extension SettingsViewController {

    func createARVC() -> POIViewController {
        let arclVC = POIViewController.loadFromStoryboard()
        arclVC.showMap = true

        return arclVC
    }
    
    func createCameraVC () -> ViewController {
        let cameraVC = ViewController.loadFromStoryboard()
        cameraVC.autoConnect = true
        
        return cameraVC
    }
    
    @IBAction func mapButtonTapped(_ sender: Any) {
        let mapVC = MapViewController.loadFromStoryboard()
        mapVC.mapSearchResults = mapSearchResults
        self.navigationController?.pushViewController(mapVC, animated: true)
    }

    func getDirections(to mapLocation: UserMKMapItem, roomID: String) {
        refreshControl.startAnimating()

        let request = MKDirections.Request()
        request.source = MKMapItem.forCurrentLocation()
        request.destination = mapLocation
        request.requestsAlternateRoutes = false

        let directions = MKDirections(request: request)

        directions.calculate(completionHandler: { response, error in
            defer {
                DispatchQueue.main.async { [weak self] in
                    self?.refreshControl.stopAnimating()
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
    
    func searchForUsers(location: CLLocation) {
//        showRouteDirections.isOn = true
//        toggledSwitch(showRouteDirections)
        
//        refreshControl.startAnimating()
        myQuery = geoFire?.query(at: CLLocation(coordinate: location.coordinate, altitude: 0.5), withRadius: 10)
        
        myQuery?.observe(.keyEntered, with: { (key, location) in
            Database.database().reference().child("users").child(key).observe(.value, with: { (snapshot) in
                let userDict = snapshot.value as? [String : AnyObject] ?? [:]
                if let data = userDict["data"] {
                    let me = data["me"] as! [String : AnyObject]
                    
                    if((self.userCache.object(forKey: key as NSString)) == nil && key != Auth.auth().currentUser?.uid) {
                        let destination = UserMKMapItem(coordinate: location.coordinate, profileFileURL: me["bitmoji"]?["avatar"] as! String, title: me["externalId"]as! String, roomID: me["externalId"] as! String)
                        self.mapSearchResults?.append(destination)
                        DispatchQueue.main.async { [weak self] in
                            self?.searchResultTable.reloadData()
                        }
                        self.userCache.setObject(destination, forKey: key as NSString)
                    } else if(self.mapSearchResults!.count > 0) {
//                        self.geoFireRef?.child(Auth.auth().currentUser!.uid).updateChildValues(["matched": self.mapSearchResults!.last?.roomID])
//                        self.getDirections(to: self.mapSearchResults!.last!, roomID: me["externalId"] as! String)
                    }
                } else {
                   return
                }
                
            })
        })
        
        myQuery?.observeReady{
//            print("All initial data has been loaded and events have been fired for circle query!")
        }
    }
}
