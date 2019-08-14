//
//  MapViewController.swift
//  ARKit+CoreLocation
//
//  Created by Daniel Golman on 8/5/19.
//  Copyright © 2019 Project Dent. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController, MKMapViewDelegate {
    
    var mapSearchResults: [UserMKMapItem]?
    var myLocation: CLLocation?
    
    @IBOutlet weak var mapView: MKMapView!
    
    class func loadFromStoryboard() -> MapViewController {
        return UIStoryboard(name: "Main", bundle: nil)
            .instantiateViewController(withIdentifier: "MapViewController") as! MapViewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        mapView.showsUserLocation = true

        guard var annotations = self.mapSearchResults?.map( { (mapItem) -> UserPointAnnotation in
            return mapItem.annotation ?? UserPointAnnotation()
        }) else { return }
        
//        annotations
        let annotation = UserPointAnnotation()
        annotation.coordinate = myLocation?.coordinate ?? UserPointAnnotation().coordinate
        annotations.append(annotation)
        
        
//        mapView.addAnnotations(annotations)
        mapView.showAnnotations(annotations, animated: true)
        
        if let userLocation = myLocation {
            print("happening")
            
            let span = mapView.region.span
            let center = mapView.region.center
            let west = CLLocation(latitude: center.latitude - span.latitudeDelta * 0.5, longitude: center.longitude)
            let east = CLLocation(latitude: center.latitude + span.latitudeDelta * 0.5, longitude: center.longitude)
            let north = CLLocation(latitude: center.latitude, longitude: center.longitude + span.longitudeDelta * 0.5)
            let south = CLLocation(latitude: center.latitude, longitude: center.longitude - span.longitudeDelta * 0.5)
            
            let latitudinalMeters = east.distance(from: west) * 1.2
            let longitudinalMeters = north.distance(from: south) * 1.2
            
            let region = MKCoordinateRegion(
                center: mapView.centerCoordinate, latitudinalMeters: latitudinalMeters, longitudinalMeters: longitudinalMeters)
            mapView.setRegion(region, animated: true)
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
            annotationView!.canShowCallout = true
        } else {
            annotationView!.annotation = annotation
        }
        
        annotationView?.image = userPointAnnotation.pinUserImage
        
        return annotationView
        
    }
    
}
