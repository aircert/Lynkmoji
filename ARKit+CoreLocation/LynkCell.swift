//
//  LocationCell.swift
//  ARKit+CoreLocation
//
//  Created by Eric Internicola on 2/20/19.
//  Copyright © 2019 Project Dent. All rights reserved.
//

import CoreLocation
import MapKit
import UIKit
import VerticalCardSwiper

class LynkCell: CardCell {

    var locationManager: CLLocationManager?
    var locationUpdateTimer: Timer?

    @IBOutlet weak var mapView: MKMapView!
    
    var currentLocation: CLLocation? {
        return locationManager?.location
    }

    var mapItem: UserMKMapItem? {
        didSet {
            updateCell()
        }
    }

//    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!

    override func prepareForReuse() {
        super.prepareForReuse()
//        distanceLabel.text = nil
        titleLabel.text = nil
        locationUpdateTimer?.invalidate()
    }

}

// MARK: - Implementation

extension LynkCell {

    @objc
    func updateCell() {
        guard let mapItem = mapItem else {
            locationUpdateTimer?.invalidate()
            return
        }
        
        titleLabel.text = "\(mapItem.titleText!)"
        
        guard let currentLocation = currentLocation else {
            distanceLabel.text = "📡"
            return
        }
        
        guard let mapItemLocation = mapItem.annotation?.coordinate else {
            distanceLabel.text = "🤷‍♂️"
            return
        }

//        distanceLabel.text = String(format: "%.0f ft", mapItemLocation.distance(from: currentLocation)*3.28084)
        
        locationUpdateTimer = Timer(timeInterval: 1, target: self, selector: #selector(updateCell), userInfo: nil, repeats: false)
        
        mapView.addAnnotation(mapItem.annotation!)
        
        let region = MKCoordinateRegion(
            center: mapItem.annotation!.coordinate, latitudinalMeters: 200, longitudinalMeters: 200)
        mapView.setRegion(region, animated: true)
        
        profileImageView.image = mapItem.profileImage
    }

}

extension MKMapItem {

    var titleLabelText: String {
        var result = ""

        if let name = name {
            result += name
        }
        if let addressDictionary = placemark.addressDictionary {
            if let street = addressDictionary["Street"] as? String {
                result += "\n\(street)"
            }
            if let city = addressDictionary["City"] as? String,
                let state = addressDictionary["State"] as? String,
                let zip = addressDictionary["ZIP"] as? String {
                result += "\n\(city), \(state) \(zip)"
            }
        } else if let location = placemark.location {
            result += "\n\(location.coordinate)"
        }

        return result
    }

}
