//
//  MapViewController.swift
//  ARKit+CoreLocation
//
//  Created by Daniel Golman on 8/5/19.
//  Copyright © 2019 Project Dent. All rights reserved.
//

import UIKit
import MapKit
import Firebase
import GeoFire

class MapViewController: UIViewController, MKMapViewDelegate {
    
    var mapSearchResults: [UserPointAnnotation]? = []
    var myLocation: CLLocation?
    
    var userGeoFireRef: DatabaseReference?
    var userGeoFire: GeoFire?
    
    var lynkGeoFireRef: DatabaseReference?
    var lynkGeoFire: GeoFire?
    var myQuery: GFQuery?
    
    let userCache = NSCache<NSString, UserMKMapItem>()
    
    @IBOutlet weak var mapView: MKMapView!
    
    class func loadFromStoryboard() -> MapViewController {
        return UIStoryboard(name: "Main", bundle: nil)
            .instantiateViewController(withIdentifier: "MapViewController") as! MapViewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        mapView.showsUserLocation = true
        
        lynkGeoFireRef = Database.database().reference().child("lynks")
        lynkGeoFire = GeoFire(firebaseRef: lynkGeoFireRef!)
        
        userGeoFireRef = Database.database().reference().child("users")
        userGeoFire = GeoFire(firebaseRef: userGeoFireRef!)
        
        if let userLocation = myLocation {
            
            searchForUsers(location: userLocation)
            print("happening")
//
//
//            userLocation.distance(from: <#T##CLLocation#>)
//            mapItemLocation.distance(from: currentLocation)
        }
        
//        mapView.userTrackingMode = .follow
    }
    
//    func mapView(_ mapView: MKMapView, didUpdate
//        userLocation: MKUserLocation) {
//        let region = MKCoordinateRegion(
//            center: userLocation.location!.coordinate, latitudinalMeters: 2000, longitudinalMeters: 2000)
//        mapView.setRegion(region, animated: true)
//    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard annotation is UserPointAnnotation else { return nil }
        
        
        // Supposed to elimante myself
        if let userLocation = annotation as? MKUserLocation {
            userLocation.title = ""
            return nil
        }
        
        let identifier = "Annotation"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        
        let userPointAnnotation = annotation as! UserPointAnnotation
        
        if annotationView == nil {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView?.image = userPointAnnotation.pinUserImage
            annotationView!.isEnabled = true
            annotationView!.canShowCallout = true
            
            annotationView?.annotation = userPointAnnotation
            
            let btn = UIButton(type: .detailDisclosure)
            annotationView!.rightCalloutAccessoryView = btn
            return annotationView
        } else {
            annotationView!.annotation = annotation
        }
        
        annotationView?.image = userPointAnnotation.pinUserImage
        
        return annotationView
        
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
//        let capital = view.annotation as! UserPointAnnotation
//        let placeName = capital.title
//        let placeInfo = capital.title
//
//        let ac = UIAlertController(title: placeName, message: placeInfo, preferredStyle: .alert)
//        ac.addAction(UIAlertAction(title: "OK", style: .default))
//        present(ac, animated: true)
        
        let arclVC = self.createARVC()
        arclVC.routes = nil
//        arclVC.targetUser = MKMapItem(placemark: MKPlacemark(coordinate: view.annotation!.coordinate)) as! UserMKMapItem
        arclVC.targetAnnotation = view.annotation as? UserPointAnnotation
        present(arclVC, animated: true)
        
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
    
    func createARVC() -> POIViewController {
        let arclVC = POIViewController.loadFromStoryboard()
        arclVC.showMap = true
        
        return arclVC
    }
    
    func searchForUsers(location: CLLocation) {
        //        showRouteDirections.isOn = true
        //        toggledSwitch(showRouteDirections)
        
        //        refreshControl.startAnimating()
        myQuery = lynkGeoFire?.query(at: CLLocation(coordinate: location.coordinate, altitude: 0.5), withRadius: 10)
        
        myQuery?.observeReady({
            
//            guard var annotations = self.mapSearchResults?.map( { (mapItem) -> UserPointAnnotation in
//                return mapItem.annotation ?? UserPointAnnotation()
//            }) else { return }
    
//            annotations
            let annotation = UserPointAnnotation()
            annotation.coordinate = self.myLocation?.coordinate ?? UserPointAnnotation().coordinate
            self.mapSearchResults?.append(annotation)
    
    
//            self.mapView.addAnnotations(self.)
            self.mapView.showAnnotations(self.mapSearchResults!, animated: true)
            
            let span = self.mapView.region.span
            let center = self.mapView.region.center
            let west = CLLocation(latitude: center.latitude - span.latitudeDelta * 0.5, longitude: center.longitude)
            let east = CLLocation(latitude: center.latitude + span.latitudeDelta * 0.5, longitude: center.longitude)
            let north = CLLocation(latitude: center.latitude, longitude: center.longitude + span.longitudeDelta * 0.5)
            let south = CLLocation(latitude: center.latitude, longitude: center.longitude - span.longitudeDelta * 0.5)
            
            let latitudinalMeters = east.distance(from: west) * 1.2
            let longitudinalMeters = north.distance(from: south) * 1.2
            
            let region = MKCoordinateRegion(
                center: self.mapView.centerCoordinate, latitudinalMeters: latitudinalMeters, longitudinalMeters: longitudinalMeters)
            self.mapView.setRegion(region, animated: true)
        })
        
        myQuery?.observe(.keyEntered, with: { (key, location) in
            Database.database().reference().child("lynks").child(key).observeSingleEvent(of: .value, with: {
                (snapshot) in
                let lynkDict = snapshot.value as? [String : AnyObject] ?? [:]
                Database.database().reference().child("users").child(lynkDict["uid"] as! String).observeSingleEvent(of: .value, with: { (userSnapshot) in
                    let userDict = userSnapshot.value as? [String : AnyObject] ?? [:]
                    if let data = userDict["data"] {
                        let me = data["me"] as! [String : AnyObject]
                        
                        if((self.userCache.object(forKey: key as! NSString)) == nil && key != Auth.auth().currentUser?.uid) {
                            let destination = UserMKMapItem(coordinate: location.coordinate, profileFileURL: me["bitmoji"]?["avatar"] as! String, title: "\(lynkDict["location"]!) \(lynkDict["dateTime"]!)" as! String, roomID: key)
//                            destination
                            destination.annotation!.roomID = key
                            self.mapSearchResults?.append(destination.annotation!)
                            self.userCache.setObject(destination, forKey: key as NSString)
                            DispatchQueue.main.async { [weak self] in
                                self?.mapView.showAnnotations(self!.mapSearchResults!, animated: true)
                            }
                            self.myQuery?.removeObserver(withFirebaseHandle: UInt(key) ?? 1)
                        } else if(self.mapSearchResults!.count > 0) {
                            //                        self.geoFireRef?.child(Auth.auth().currentUser!.uid).updateChildValues(["matched": self.mapSearchResults!.last?.roomID])
                            //                        self.getDirections(to: self.mapSearchResults!.last!, roomID: me["externalId"] as! String)
                        }
                    } else {
                        return
                    }
                    
                })
            })
        })
    }
    
}
