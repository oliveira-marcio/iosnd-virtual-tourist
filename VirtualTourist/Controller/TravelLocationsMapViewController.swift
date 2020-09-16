//
//  ViewController.swift
//  VirtualTourist
//
//  Created by Márcio Oliveira on 9/14/20.
//  Copyright © 2020 Márcio Oliveira. All rights reserved.
//

import UIKit
import MapKit

class TravelLocationsMapViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!

    var currentMapRegion: MKCoordinateRegion?

    override func viewDidLoad() {
        super.viewDidLoad()
        loadMapAnnotations()
        loadMapRegion()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        saveMapRegion()
    }

    func saveMapRegion() {
        UserDefaults.standard.set(currentMapRegion?.center.latitude, forKey: "mapRegionCenterLatitude")
        UserDefaults.standard.set(currentMapRegion?.center.longitude, forKey: "mapRegionCenterLongitude")
        UserDefaults.standard.set(currentMapRegion?.span.latitudeDelta, forKey: "mapRegionLatitudeDelta")
        UserDefaults.standard.set(currentMapRegion?.span.longitudeDelta, forKey: "mapRegionLongitudeDelta")
    }

    private func loadMapRegion() {
        let centerLatitude = getCoordinateFromPersistence(forKey: "mapRegionCenterLatitude", defaultValue: 38.714761)
        let centerLongitude = getCoordinateFromPersistence(forKey: "mapRegionCenterLongitude", defaultValue: -9.1568121)
        let coordinate = CLLocationCoordinate2D(latitude: centerLatitude, longitude: centerLongitude)

        let latitudeDelta = getCoordinateFromPersistence(forKey: "mapRegionLatitudeDelta", defaultValue: 0.083862955545754403)
        let longitudeDelta = getCoordinateFromPersistence(forKey: "mapRegionLongitudeDelta", defaultValue: 0.057489037524248943)
        let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)

        currentMapRegion = MKCoordinateRegion(center: coordinate, span: span)

        if let currentMapRegion = currentMapRegion {
            mapView.setRegion(mapView.regionThatFits(currentMapRegion), animated: true)
        }
    }

    private func getCoordinateFromPersistence(forKey: String, defaultValue: Float) -> CLLocationDegrees {
        let coordinate = UserDefaults.standard.float(forKey: forKey)
        return CLLocationDegrees(coordinate == 0 ? defaultValue : coordinate)
    }

    private func loadMapAnnotations() {
        mapView.delegate = self

        let lat = CLLocationDegrees(38.714761)
        let long = CLLocationDegrees(-9.1568121)
        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)

        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate

        var annotations = [MKPointAnnotation]()
        annotations.append(annotation)

        mapView.removeAnnotations(mapView.annotations)
        mapView.showAnnotations(annotations, animated: true)
    }

    // MARK: - Map View Delegate

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {

        let reuseId = "pin"

        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView

        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = false
            pinView!.pinTintColor = .red
            pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }
        else {
            pinView!.annotation = annotation
        }

        return pinView
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        performSegue(withIdentifier: "showPhotoAlbum", sender: nil)
        mapView.selectedAnnotations = []
    }

    func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
       currentMapRegion = mapView.region
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let photoAlbumViewController = segue.destination as! PhotoAlbumViewController
        photoAlbumViewController.test = "Yay"
    }
}

