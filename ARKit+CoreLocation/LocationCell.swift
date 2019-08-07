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

class LocationCell: UITableViewCell {

    var locationManager: CLLocationManager?
    var locationUpdateTimer: Timer?

    var currentLocation: CLLocation? {
        return locationManager?.location
    }

    var mapItem: UserMKMapItem? {
        didSet {
            updateCell()
        }
    }

    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!

    override func prepareForReuse() {
        super.prepareForReuse()
        distanceLabel.text = nil
        titleLabel.text = nil
        locationUpdateTimer?.invalidate()
    }

}

// MARK: - Implementation

extension LocationCell {

    @objc
    func updateCell() {
        guard let mapItem = mapItem else {
            locationUpdateTimer?.invalidate()
            return
        }
        
        titleLabel.text = mapItem.titleText
        
        guard let currentLocation = currentLocation else {
            distanceLabel.text = "📡"
            return
        }
        guard let mapItemLocation = mapItem.placemark.location else {
            distanceLabel.text = "🤷‍♂️"
            return
        }

        distanceLabel.text = String(format: "%.0f ft", mapItemLocation.distance(from: currentLocation)*3.28084)
        locationUpdateTimer = Timer(timeInterval: 1, target: self, selector: #selector(updateCell), userInfo: nil, repeats: false)
        
        profileImageView.image = mapItem.profileImage
    }

}

private extension MKMapItem {

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
