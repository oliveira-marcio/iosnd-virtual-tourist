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

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var photosCollectionView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var newCollectionButton: UIBarButtonItem!
    @IBOutlet weak var noImagesLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    var dataController: DataController!
    var photoDataSource: PhotoDataSource!
    var gateway: FlickrGateway!
    var selectedPin: Pin!

    var onDelete: (() -> Void)?

    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        mapView.delegate = self

        loadMapSelectedPin()
        computeFlowLayout()
        setupPhotoDataSource()

        photosCollectionView.isHidden = true
        noImagesLabel.isHidden = true
        loadingCollection(true)

        photoDataSource.getNewAlbumCollection(completion: handleGetNewAlbum(hasPhotos:))
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        computeFlowLayout()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        photoDataSource.releaseFetchedResultsController()
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

    // MARK: - Load Map Selected Pin from TravelLocationMapViewController

    private func loadMapSelectedPin() {
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: selectedPin.latitude, longitude: selectedPin.longitude)

        self.mapView.showAnnotations([annotation], animated: false)
    }

    // MARK: - Setup Photo Data Source

    func setupPhotoDataSource() {
        photoDataSource = PhotoDataSource(
            dataController: dataController,
            pin: selectedPin,
            gateway: gateway,
            collectionView: photosCollectionView,
            configure: configureCollectionViewCell(cell:data:)
        )

        photosCollectionView.dataSource = photoDataSource
    }

    private func configureCollectionViewCell(cell: PhotoCollectionViewCell, data: Data?) {
        if let data = data {
            cell.photoImageView.image = UIImage(data: data)
        } else {
            cell.photoImageView.image = UIImage(named: "VirtualTourist_120")
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
        loadingCollection(true)
        noImagesLabel.isHidden = true
        photoDataSource.getNewAlbumCollection(completion: handleGetNewAlbum(hasPhotos:))
    }

    func handleGetNewAlbum(hasPhotos: Bool) {
        loadingCollection(false)
        photosCollectionView.isHidden = hasPhotos
        noImagesLabel.isHidden = !hasPhotos
    }

    func loadingCollection(_ loading: Bool) {
        newCollectionButton.isEnabled = !loading
        loading ? activityIndicator.startAnimating() : activityIndicator.stopAnimating()
    }
}
