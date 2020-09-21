//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Márcio Oliveira on 9/16/20.
//  Copyright © 2020 Márcio Oliveira. All rights reserved.
//

import UIKit
import MapKit

class PhotoAlbumViewController: UIViewController, MKMapViewDelegate, UICollectionViewDataSource {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var photosCollectionView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!

    var gateway: FlickrGateway!
    var selectedPin: Pin!
    var imagesURLs = [URL]()

    var onDelete: (() -> Void)?

    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        mapView.delegate = self
        photosCollectionView.dataSource = self
        
        loadMapSelectedPin()
        computeFlowLayout()

        requestNewAlbumCollection()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        computeFlowLayout()
    }

    // MARK: - Compute Photo Album Flow Layout

    func computeFlowLayout() {
        let space: CGFloat = 2.0

        let isPortrait = UIDevice.current.orientation.isValidInterfaceOrientation
            ? UIDevice.current.orientation.isPortrait
            : (view.frame.size.width < view.frame.size.height)

        let numOfCols: CGFloat = isPortrait ? 3.0 : 5.0
        let spacesBetweenCols = numOfCols - 1

        let portraitViewWidth = min(view.frame.size.width, view.frame.size.height)
        let landscapeViewWidth = max(view.frame.size.width, view.frame.size.height)
        let horizontalViewDimension = isPortrait ? portraitViewWidth : landscapeViewWidth

        let dimension = (horizontalViewDimension - (spacesBetweenCols * space)) / numOfCols

        flowLayout.minimumInteritemSpacing = space
        flowLayout.minimumLineSpacing = space
        flowLayout.itemSize = CGSize(width: dimension, height: dimension)
    }

    // MARK: - Request Nwe Album Collection From API

    private func requestNewAlbumCollection() {
        gateway.getLocationAlbum(latitude: selectedPin.latitude, longitude: selectedPin.longitude) { imagesURLs in
            self.imagesURLs = imagesURLs
            self.photosCollectionView.reloadData()
        }
    }


    // MARK: - Load Map Selected Pin from TravelLocationMapViewController

    private func loadMapSelectedPin() {
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: selectedPin.latitude, longitude: selectedPin.longitude)

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

    // MARK: - Collection View Delegate

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imagesURLs.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCollectionViewCell", for: indexPath) as! PhotoCollectionViewCell

        // TODO: Just for testing purposes. Do the right implementation!
        cell.photoImageView.image = UIImage(named: "VirtualTourist_120")
        gateway.getPhoto(from: imagesURLs[indexPath.row]) { image in
            cell.photoImageView.image = image
        }

        return cell
    }

    // MARK: - Actions

    @IBAction func deleteLocation(_ sender: Any) {
        showDeleteAlert()
    }

    private func showDeleteAlert() {
        let alert = UIAlertController(title: "Delete Location?", message: "Are you sure you want to delete the current location?", preferredStyle: .alert)

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            guard let strongSelf = self else { return }
            strongSelf.onDelete?()
        }

        alert.addAction(cancelAction)
        alert.addAction(deleteAction)
        present(alert, animated: true, completion: nil)
    }

    @IBAction func getNewAlbumCollection(_ sender: Any) {
        requestNewAlbumCollection()
    }
}
