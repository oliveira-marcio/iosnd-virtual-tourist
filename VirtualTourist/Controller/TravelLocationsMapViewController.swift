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

class TravelLocationsMapViewController: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate {

    @IBOutlet weak var mapView: MKMapView!

    var dataController: DataController!
    var fetchedResultsController: NSFetchedResultsController<Pin>!

    var currentMapRegion: MKCoordinateRegion?
    var selectedPin: Pin?

    var gateway: FlickrGateway!

    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        mapView.delegate = self

        loadMapRegion()
    }

    override func viewWillAppear(_ animated: Bool) {
        setupFetchedResultsController()
        gateway.getLocationAlbum(latitude: 38.707386065604652, longitude: -9.1548092420383398)
        gateway.getImage(id: "50340310746")
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        saveMapRegion()
        fetchedResultsController = nil
    }

    // MARK: - Setup Fetched Results Controller

    private func setupFetchedResultsController() {
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()

        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]

        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "pins")

        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
            loadMapPins()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
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
            let pins = fetchedResultsController.fetchedObjects,
            let selectedPin = pins.first(where: {
                let expectedLat = selectedAnnotation.coordinate.latitude
                let currentLat = $0.latitude

                let expectedLong = selectedAnnotation.coordinate.longitude
                let currentLong = $0.longitude

                return expectedLat == currentLat && expectedLong == currentLong
            }) else { return }


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
            addMapPin(latitude: coordinates.latitude, longitude: coordinates.longitude)
        }
    }

    // MARK: - Prepare For Segue

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let photoAlbumViewController = segue.destination as! PhotoAlbumViewController
        photoAlbumViewController.selectedPin = selectedPin

        photoAlbumViewController.onDelete = { [weak self] in
            if let selectedPin = self?.selectedPin {
                self?.deleteMapPin(selectedPin)
                self?.navigationController?.popViewController(animated: true)
            }
        }
    }

    // MARK: - Map Data Handling

    private func loadMapPins() {
        guard let pins = fetchedResultsController.fetchedObjects else { return }

        var annotations = [MKPointAnnotation]()

        for pin in pins {
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
            annotations.append(annotation)
        }

        mapView.removeAnnotations(mapView.annotations)
        mapView.addAnnotations(annotations)
    }

    private func addMapPin(latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        // Workaround to retrieve map control after long press gesture
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        mapView.setCenter(coordinate, animated: true)

        let pin = Pin(context: dataController.viewContext)
        pin.latitude = latitude
        pin.longitude = longitude
        pin.creationDate = Date()

        try? dataController.viewContext.save()
    }

    private func deleteMapPin(_ pin: Pin) {
        dataController.viewContext.delete(pin)
        try? dataController.viewContext.save()
    }

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

    // MARK: - Fetched Results Controller Delegate

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        loadMapPins()
    }
}

