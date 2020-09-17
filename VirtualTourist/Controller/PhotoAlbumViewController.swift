//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Márcio Oliveira on 9/16/20.
//  Copyright © 2020 Márcio Oliveira. All rights reserved.
//

import UIKit
import MapKit

class PhotoAlbumViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var mapView: MKMapView!

    var selectedCoordinate: CLLocationCoordinate2D!

    override func viewDidLoad() {
        super.viewDidLoad()

        mapView.delegate = self
        loadMapResults()

        label.text = "\(selectedCoordinate.latitude), \(selectedCoordinate.longitude)"
    }
    
    private func loadMapResults() {
        let annotation = MKPointAnnotation()
        annotation.coordinate = selectedCoordinate

        self.mapView.showAnnotations([annotation], animated: false)
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

}
