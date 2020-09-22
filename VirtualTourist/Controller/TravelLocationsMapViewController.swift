//
//  ViewController.swift
//  VirtualTourist
//
//  Created by Márcio Oliveira on 9/14/20.
//  Copyright © 2020 Márcio Oliveira. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class TravelLocationsMapViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!

    var dataController: DataController!
    var pinDataSource: PinDataSource!
    var gateway: FlickrGateway!

    var currentMapRegion: MKCoordinateRegion?
    var selectedPin: Pin?
    var pins = [Pin]()
    
    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        mapView.delegate = self

        loadMapRegion()
    }

    override func viewWillAppear(_ animated: Bool) {
        setupFetchedResultsController()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        saveMapRegion()
        pinDataSource.releaseFetchedResultsController()
    }

    // MARK: - Setup Fetched Results Controller

    private func setupFetchedResultsController() {
        pinDataSource = PinDataSource(dataController: dataController, onUpdate: { pins in
            self.pins = pins
            var annotations = [MKPointAnnotation]()

            for pin in pins {
                let annotation = MKPointAnnotation()
                annotation.coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
                annotations.append(annotation)
            }

            self.mapView.removeAnnotations(self.mapView.annotations)
            self.mapView.addAnnotations(annotations)
        })
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
        guard let selectedAnnotation = mapView.selectedAnnotations.first,
            let selectedPin = pinDataSource.getPin(latitude: selectedAnnotation.coordinate.latitude, longitude: selectedAnnotation.coordinate.longitude)
            else { return }

        self.selectedPin = selectedPin
        performSegue(withIdentifier: "showPhotoAlbum", sender: nil)
        mapView.selectedAnnotations = []
    }

    func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
        currentMapRegion = mapView.region
    }

    // MARK: - Actions

    @IBAction func handleMapLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            let touchPoint = gestureRecognizer.location(in: mapView)
            let coordinates = mapView.convert(touchPoint, toCoordinateFrom: mapView)

            // Workaround to retrieve map control after long press gesture
            mapView.setCenter(coordinates, animated: true)

            pinDataSource.addPin(latitude: coordinates.latitude, longitude: coordinates.longitude)
        }
    }

    // MARK: - Prepare For Segue

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let photoAlbumViewController = segue.destination as! PhotoAlbumViewController
        photoAlbumViewController.gateway = gateway
        photoAlbumViewController.selectedPin = selectedPin
        photoAlbumViewController.dataController = dataController

        photoAlbumViewController.onDelete = { [weak self] in
            if let selectedPin = self?.selectedPin {
                self?.pinDataSource.deletePin(selectedPin)
                self?.navigationController?.popViewController(animated: true)
            }
        }
    }

    // MARK: - Map Region Data Handling

    func saveMapRegion() {
        UserDefaults.standard.set(currentMapRegion?.center.latitude, forKey: "mapRegionCenterLatitude")
        UserDefaults.standard.set(currentMapRegion?.center.longitude, forKey: "mapRegionCenterLongitude")
        UserDefaults.standard.set(currentMapRegion?.span.latitudeDelta, forKey: "mapRegionLatitudeDelta")
        UserDefaults.standard.set(currentMapRegion?.span.longitudeDelta, forKey: "mapRegionLongitudeDelta")
    }

    private func loadMapRegion() {
        let centerLatitude = getCoordinatesFromPersistence(forKey: "mapRegionCenterLatitude", defaultValue: 38.707386065604652)
        let centerLongitude = getCoordinatesFromPersistence(forKey: "mapRegionCenterLongitude", defaultValue: -9.1548092420383398)
        let coordinate = CLLocationCoordinate2D(latitude: centerLatitude, longitude: centerLongitude)

        let latitudeDelta = getCoordinatesFromPersistence(forKey: "mapRegionLatitudeDelta", defaultValue: 0.088252179893437699)
        let longitudeDelta = getCoordinatesFromPersistence(forKey: "mapRegionLongitudeDelta", defaultValue: 0.088252179893437699)
        let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)

        currentMapRegion = MKCoordinateRegion(center: coordinate, span: span)

        if let currentMapRegion = currentMapRegion {
            mapView.setRegion(mapView.regionThatFits(currentMapRegion), animated: true)
        }
    }

    private func getCoordinatesFromPersistence(forKey: String, defaultValue: Float) -> CLLocationDegrees {
        let coordinate = UserDefaults.standard.float(forKey: forKey)
        return CLLocationDegrees(coordinate == 0 ? defaultValue : coordinate)
    }
}
