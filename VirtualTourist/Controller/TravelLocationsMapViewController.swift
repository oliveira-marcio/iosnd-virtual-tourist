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
    
    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        mapView.delegate = self

        currentMapRegion = MapRegionDataSource.loadMapRegion()

        if let currentMapRegion = currentMapRegion {
            mapView.setRegion(mapView.regionThatFits(currentMapRegion), animated: true)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        setupPinDataSource()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        MapRegionDataSource.saveMapRegion(currentMapRegion)
        pinDataSource.releaseFetchedResultsController()
    }

    // MARK: - Setup Fetched Results Controller

    private func setupPinDataSource() {
        pinDataSource = PinDataSource(dataController: dataController, onUpdate: { pins in
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
}
