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

    var currentMapRegion: MKCoordinateRegion!

    override func viewDidLoad() {
        super.viewDidLoad()
        loadMapAnnotations()
        getMapRegion()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        UserDefaults.standard.set(currentMapRegion?.center.latitude, forKey: "mapRegionCenterLatitude")
        UserDefaults.standard.set(currentMapRegion?.center.longitude, forKey: "mapRegionCenterLongitude")
        UserDefaults.standard.set(currentMapRegion?.span.latitudeDelta, forKey: "mapRegionLatitudeDelta")
        UserDefaults.standard.set(currentMapRegion?.span.longitudeDelta, forKey: "mapRegionLongitudeDelta")
    }

    private func getMapRegion() {
        let lat = CLLocationDegrees(truncating: (UserDefaults.standard.value(forKey: "mapRegionCenterLatitude") as? NSNumber) ?? 38.714761)
        let long = CLLocationDegrees(truncating: (UserDefaults.standard.value(forKey: "mapRegionCenterLongitude") as? NSNumber) ?? -9.1568121)
        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)

        let latitudeDelta = CLLocationDegrees(truncating: (UserDefaults.standard.value(forKey: "mapRegionLatitudeDelta") as? NSNumber) ?? 0.083862955545754403)
        let longitudeDelta = CLLocationDegrees(truncating: (UserDefaults.standard.value(forKey: "mapRegionLongitudeDelta") as? NSNumber) ?? 0.057489037524248943)
        let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)

        currentMapRegion = MKCoordinateRegion(center: coordinate, span: span)

        mapView.setRegion(mapView.regionThatFits(currentMapRegion), animated: true)
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

