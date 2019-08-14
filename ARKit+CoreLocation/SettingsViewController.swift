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
import VerticalCardSwiper

@available(iOS 11.0, *)
class SettingsViewController: UIViewController {

    @IBOutlet weak var showMapSwitch: UISwitch!
    @IBOutlet weak var showRouteDirections: UISwitch!
    @IBOutlet weak var searchResultTable: UITableView!
    @IBOutlet weak var refreshControl: UIActivityIndicatorView!

    var locationManager = CLLocationManager()

    var mapSearchResults: [UserMKMapItem]? = []
    
    var statusText: String?

    var userGeoFireRef: DatabaseReference?
    var userGeoFire: GeoFire?
    
    var lynkGeoFireRef: DatabaseReference?
    var lynkGeoFire: GeoFire?
    var myQuery: GFQuery?
    
    private var cardSwiper: VerticalCardSwiper!
    
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
    
        lynkGeoFireRef = Database.database().reference().child("lynks")
        lynkGeoFire = GeoFire(firebaseRef: lynkGeoFireRef!)
        
        userGeoFireRef = Database.database().reference().child("users")
        userGeoFire = GeoFire(firebaseRef: userGeoFireRef!)
        
//        self.searchResultTable.delegate = self
//        self.searchResultTable.dataSource = self
        
//        searchResultTable.register(UINib(nibName: "LocationCell", bundle: nil), forCellReuseIdentifier: "LocationCell")
//
//        searchResultTable.rowHeight = UITableView.automaticDimension
//        searchResultTable.estimatedRowHeight = 100
//        searchResultTable.rowHeight = 100.0
        
        cardSwiper = VerticalCardSwiper(frame: self.view.bounds)
        view.addSubview(cardSwiper)
        
        cardSwiper.datasource = self
        cardSwiper.delegate = self
        
        // register cardcell for storyboard use
        cardSwiper.register(nib: UINib(nibName: "LynkCell", bundle: nil), forCellWithReuseIdentifier: "LynkCell")
        
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
//            searchResultTable.reloadData()
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
extension SettingsViewController: VerticalCardSwiperDatasource {
    func numberOfCards(verticalCardSwiperView: VerticalCardSwiperView) -> Int {
        return self.mapSearchResults?.count ?? 0
    }
    

//    func numberOfSections(in tableView: UITableView) -> Int {
//        return 1
//    }
//
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return mapSearchResults?.count ?? 0
//    }

//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = tableView.dequeueReusableCell(withIdentifier: "LocationCell", for: indexPath)
//        guard let mapSearchResults = mapSearchResults,
//            indexPath.row < mapSearchResults.count,
//            let locationCell = cell as? LocationCell else {
//                return cell
//        }
//        locationCell.locationManager = locationManager
//        locationCell.mapItem = mapSearchResults[indexPath.row]
//
//        return locationCell
//    }
    
    func cardForItemAt(verticalCardSwiperView: VerticalCardSwiperView, cardForItemAt index: Int) -> CardCell {
        let cell = verticalCardSwiperView.dequeueReusableCell(withReuseIdentifier: "LynkCell", for: index)
        guard let mapSearchResults = mapSearchResults,
            index < mapSearchResults.count,
            let locationCell = cell as? LynkCell else {
                return cell as! CardCell
        }
        locationCell.locationManager = locationManager
        locationCell.mapItem = mapSearchResults[index]
        
        return locationCell
    }
}

// MARK: - UITableViewDelegate

@available(iOS 11.0, *)
extension SettingsViewController: VerticalCardSwiperDelegate {

//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        guard let mapSearchResults = mapSearchResults, indexPath.row < mapSearchResults.count else {
//            return
//        }
//        let selectedMapItem = mapSearchResults[indexPath.row]
//        getDirections(to: selectedMapItem, roomID: selectedMapItem.roomID!)
//    }
    
    func willSwipeCardAway(card: CardCell, index: Int, swipeDirection: SwipeDirection) {
    
        // called right before the card animates off the screen (optional).
        self.mapSearchResults?.remove(at: index)
    }
    
    func didSwipeCardAway(card: CardCell, index: Int, swipeDirection: SwipeDirection) {
    
        // handle swipe gestures (optional).
    }
    
    func sizeForItem(verticalCardSwiperView: VerticalCardSwiperView, index: Int) -> CGSize {
    
        // Allows you to return custom card sizes (optional).
        return CGSize(width: verticalCardSwiperView.frame.width, height: verticalCardSwiperView.frame.height)
    }
    
    func didScroll(verticalCardSwiperView: VerticalCardSwiperView) {
    
        // Tells the delegate when the user scrolls through the cards (optional).
    }
    
    func didEndScroll(verticalCardSwiperView: VerticalCardSwiperView) {
    
        // Tells the delegate when scrolling through the cards came to an end (optional).
    }
    
    func didDragCard(card: CardCell, index: Int, swipeDirection: SwipeDirection) {
    
        // Called when the user starts dragging a card to the side (optional).
    }
    
    func didTapCard(verticalCardSwiperView: VerticalCardSwiperView, index: Int) {
    
        guard let mapSearchResults = mapSearchResults, index < mapSearchResults.count else {
            return
        }
        let selectedMapItem = mapSearchResults[index]
        getDirections(to: selectedMapItem, roomID: selectedMapItem.roomID!)
    }
    
    func didHoldCard(verticalCardSwiperView: VerticalCardSwiperView, index: Int, state: UIGestureRecognizer.State) {
    
        // Tells the delegate when the user holds a card (optional).
    }

}

// MARK: - CLLocationManagerDelegate

@available(iOS 11.0, *)
extension SettingsViewController: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last,
            let userID = Auth.auth().currentUser?.uid
            else { return }
        self.userGeoFire?.setLocation(location, forKey: userID)
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
        mapVC.myLocation = locationManager.location
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
        myQuery = lynkGeoFire?.query(at: CLLocation(coordinate: location.coordinate, altitude: 0.5), withRadius: 10)
        
        myQuery?.observe(.keyEntered, with: { (key, location) in
            Database.database().reference().child("users").child(key).observe(.value, with: { (snapshot) in
                let userDict = snapshot.value as? [String : AnyObject] ?? [:]
                if let data = userDict["data"] {
                    let me = data["me"] as! [String : AnyObject]
                    
                    if((self.userCache.object(forKey: key as NSString)) == nil && key == Auth.auth().currentUser?.uid) {
                        Database.database().reference().child("lynks").child(key).observe(.value, with: { (snapshot) in
                            let lynkDict = snapshot.value as? [String : AnyObject] ?? [:]
                            let destination = UserMKMapItem(coordinate: location.coordinate, profileFileURL: me["bitmoji"]?["avatar"] as! String, title: lynkDict["dateTime"] as! String, roomID: me["externalId"] as! String)
                            self.mapSearchResults?.append(destination)
                            DispatchQueue.main.async { [weak self] in
                                self?.cardSwiper.reloadData()
                            }
                            self.userCache.setObject(destination, forKey: key as NSString)
                        })
                        
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
