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
    
    @IBOutlet weak var mapView: MKMapView!
    
    class func loadFromStoryboard() -> MapViewController {
        return UIStoryboard(name: "Main", bundle: nil)
            .instantiateViewController(withIdentifier: "MapViewController") as! MapViewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        mapView.showsUserLocation = true

        guard let annotations = self.mapSearchResults?.map( { (mapItem) -> UserPointAnnotation in
            return mapItem.annotation ?? UserPointAnnotation()
        }) else { return }
        
        mapView.addAnnotations(annotations)
        
//        if let userLocation = mapView.userLocation.location?.coordinate {
//            print("happening")
//            let region = MKCoordinateRegion(
//                center: userLocation, latitudinalMeters: 2000, longitudinalMeters: 2000)
//            mapView.setRegion(region, animated: true)
//        }
        
        mapView.userTrackingMode = .follow
    }
    
    func mapView(_ mapView: MKMapView, didUpdate
        userLocation: MKUserLocation) {
        let region = MKCoordinateRegion(
            center: userLocation.location!.coordinate, latitudinalMeters: 2000, longitudinalMeters: 2000)
        mapView.setRegion(region, animated: true)
    }
    
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
