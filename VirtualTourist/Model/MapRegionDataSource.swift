//
//  MapRegionDataSource.swift
//  VirtualTourist
//
//  Created by Márcio Oliveira on 9/22/20.
//  Copyright © 2020 Márcio Oliveira. All rights reserved.
//

import Foundation
import MapKit

struct MapRegionDataSource {

    static func saveMapRegion(_ mapRegion: MKCoordinateRegion?) {
        UserDefaults.standard.set(mapRegion?.center.latitude, forKey: "mapRegionCenterLatitude")
        UserDefaults.standard.set(mapRegion?.center.longitude, forKey: "mapRegionCenterLongitude")
        UserDefaults.standard.set(mapRegion?.span.latitudeDelta, forKey: "mapRegionLatitudeDelta")
        UserDefaults.standard.set(mapRegion?.span.longitudeDelta, forKey: "mapRegionLongitudeDelta")
    }

    static  func loadMapRegion() -> MKCoordinateRegion? {
        let centerLatitude = getCoordinatesFromPersistence(forKey: "mapRegionCenterLatitude", defaultValue: 38.707386065604652)
        let centerLongitude = getCoordinatesFromPersistence(forKey: "mapRegionCenterLongitude", defaultValue: -9.1548092420383398)
        let coordinate = CLLocationCoordinate2D(latitude: centerLatitude, longitude: centerLongitude)

        let latitudeDelta = getCoordinatesFromPersistence(forKey: "mapRegionLatitudeDelta", defaultValue: 0.088252179893437699)
        let longitudeDelta = getCoordinatesFromPersistence(forKey: "mapRegionLongitudeDelta", defaultValue: 0.088252179893437699)
        let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)

        return MKCoordinateRegion(center: coordinate, span: span)
    }

    private static func getCoordinatesFromPersistence(forKey: String, defaultValue: Float) -> CLLocationDegrees {
        let coordinate = UserDefaults.standard.float(forKey: forKey)
        return CLLocationDegrees(coordinate == 0 ? defaultValue : coordinate)
    }
}
