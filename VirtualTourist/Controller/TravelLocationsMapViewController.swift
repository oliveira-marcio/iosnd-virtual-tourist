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
    var mapAnnotations = [MKPointAnnotation]()
    var selectedCoordinate: CLLocationCoordinate2D?

    override func viewDidLoad() {
        super.viewDidLoad()

        mapView.delegate = self

        loadMapAnnotations()
        loadMapRegion()
        addAnnotation(latitude: 38.714761, longitude: -9.1568121)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        saveMapRegion()
    }

    private func loadMapAnnotations() {
        // TODO: load from database
        mapView.addAnnotations(mapAnnotations)
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
        selectedCoordinate = mapView.selectedAnnotations.first?.coordinate
        performSegue(withIdentifier: "showPhotoAlbum", sender: nil)
        mapView.selectedAnnotations = []
    }

    func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
       currentMapRegion = mapView.region
    }

    @IBAction func handleMapLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            let touchPoint = gestureRecognizer.location(in: mapView)
            let coordinates = mapView.convert(touchPoint, toCoordinateFrom: mapView)
            addAnnotation(latitude: coordinates.latitude, longitude: coordinates.longitude)
        }
    }

    private func addAnnotation(latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)

        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate

        mapAnnotations.append(annotation)
        mapView.addAnnotation(annotation)
        // TODO: Save to database
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let photoAlbumViewController = segue.destination as! PhotoAlbumViewController
        photoAlbumViewController.selectedCoordinate = selectedCoordinate
    }
}

