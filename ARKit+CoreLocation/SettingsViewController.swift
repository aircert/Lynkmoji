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

    var geoFireRef: DatabaseReference?
    var geoFire: GeoFire?
    var myQuery: GFQuery?

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
        searchResultTable.estimatedRowHeight = 120
        
        searchForUsers()
        
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
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
                self?.searchForUsers()
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
        
        print("going here")
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
        getDirections(to: selectedMapItem)
    }

}

// MARK: - CLLocationManagerDelegate

@available(iOS 11.0, *)
extension SettingsViewController: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {

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

    func getDirections(to mapLocation: UserMKMapItem) {
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
                self.navigationController?.pushViewController(arclVC, animated: true)
            }
        })
    }
    
    func searchForUsers() {
//        showRouteDirections.isOn = true
//        toggledSwitch(showRouteDirections)
        
//        refreshControl.startAnimating()
        
        myQuery = geoFire?.query(at: CLLocation(coordinate: self.locationManager.location!.coordinate, altitude: 0.5), withRadius: 1000)
        
        print("building")
        print(self.locationManager.location!.coordinate)
        
        myQuery?.observe(.keyEntered, with: { (key, location) in
            print("in query")
            Firestore.firestore().collection("users").document(key).getDocument(completion: { (snapshot, error) in
                let userDict = snapshot.value as? [String : AnyObject] ?? [:]
                //                if (userDict["active"]! as! String != "false") {
                let snap_info = userDict["snap_info"] as! [String : AnyObject]
                
                print(snap_info)
                
                let destination = UserMKMapItem(coordinate: location.coordinate, profileFileURL: snap_info["bitmoji_url"] as! String, title: snap_info["display_name"] as! String)
                
                print(destination)
                self.mapSearchResults?.append(destination)
                DispatchQueue.main.async { [weak self] in
                    self?.searchResultTable.reloadData()
                }
               
                
                print("here")
            })
            
            //            self.resetARScene()
        })
    }

    /// Searches for the location that was entered into the address text
//    func searchForLocation() {
//        showRouteDirections.isOn = true
//        toggledSwitch(showRouteDirections)
//
//        refreshControl.startAnimating()
//        let request = MKLocalSearch.Request()
////        request.naturalLanguageQuery = addressText
//
//        let search = MKLocalSearch(request: request)
//        search.start { response, error in
//            defer {
//                DispatchQueue.main.async { [weak self] in
//                    self?.refreshControl.stopAnimating()
//                }
//            }
//            if let error = error {
////                return assertionFailure("Error searching for \(addressText): \(error.localizedDescription)")
//            }
//            guard let response = response, response.mapItems.count > 0 else {
//                return assertionFailure("No response or empty response")
//            }
//            DispatchQueue.main.async { [weak self] in
//                guard let self = self else {
//                    return
//                }
//                self.mapSearchResults = response.sortedMapItems(byDistanceFrom: self.locationManager.location)
//                self.searchResultTable.reloadData()
//            }
//        }
//    }
}

extension MKLocalSearch.Response {

    func sortedMapItems(byDistanceFrom location: CLLocation?) -> [MKMapItem] {
        guard let location = location else {
            return mapItems
        }

        return mapItems.sorted { (first, second) -> Bool in
            guard let d1 = first.placemark.location?.distance(from: location),
                let d2 = second.placemark.location?.distance(from: location) else {
                    return true
            }

            return d1 < d2
        }
    }

}
