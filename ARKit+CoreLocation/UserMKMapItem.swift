//
//  File.swift
//  ARKit+CoreLocation
//
//  Created by Daniel Golman on 7/2/19.
//  Copyright © 2019 Project Dent. All rights reserved.
//

import Foundation
import MapKit

open class UserMKMapItem: MKMapItem {
    
    //    var coordinate = CLLocationCoordinate2D()
    var profileImage: UIImage?
    var titleText: String?
    var roomID: String?
    var coordinate: CLLocationCoordinate2D?
    var annotation: UserPointAnnotation?
    
    init(coordinate: CLLocationCoordinate2D, profileFileURL: String, title: String, roomID: String) {
        
        var place: MKPlacemark!
        
        self.titleText = roomID
        
        self.coordinate = coordinate
        
        if #available(iOS 10.0, *) {
            place = MKPlacemark(coordinate: coordinate)
        } else {
            place = MKPlacemark(coordinate: coordinate, addressDictionary: nil)
        }
        
        super.init(placemark: place)
        //        self.coordinate = coordinate
        do {
            let url = URL(string: profileFileURL)!
            let data = try Data(contentsOf: url)
            self.profileImage = UIImage(data: data, scale: 3)
            
            // Reference annotation for mapView
            self.annotation = UserPointAnnotation()
            self.annotation?.coordinate = coordinate
            self.annotation?.title = title
            self.annotation?.pinUserImage = self.profileImage
            
            self.roomID = roomID
        }
        catch {
            //            bitmojiImage = SCSDKBitmojiIconView().defaultImage
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
