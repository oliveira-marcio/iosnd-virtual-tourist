//
//  ImageDataSource.swift
//  VirtualTourist
//
//  Created by Márcio Oliveira on 9/20/20.
//  Copyright © 2020 Márcio Oliveira. All rights reserved.
//

import CoreData
import UIKit

class PhotoDataSource: NSObject, NSFetchedResultsControllerDelegate, UICollectionViewDataSource {
    private var viewManagedObjectContext: NSManagedObjectContext!
    private var backgroundManagedObjectContext: NSManagedObjectContext!
    private var fetchedResultsController: NSFetchedResultsController<Photo>!
    private var gateway: FlickrGateway!
    private var collectionView: UICollectionView!
    private var pin: Pin!

    private var imagesURLs = [URL]()

    init(
        dataController: DataController,
        pin: Pin,
        gateway: FlickrGateway,
        collectionView: UICollectionView
    ) {
        viewManagedObjectContext = dataController.viewContext
        backgroundManagedObjectContext = dataController.backgroundContext

        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()

        let predicate = NSPredicate(format: "pin == %@", pin)
        fetchRequest.predicate = predicate

        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]

        self.collectionView = collectionView
        self.gateway = gateway
        self.pin = pin

        super.init()

        let cacheName = "image from pin (\(pin.latitude), \(pin.longitude))"

        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: viewManagedObjectContext, sectionNameKeyPath: nil, cacheName: cacheName)

        fetchedResultsController.delegate = self

        do {
            try fetchedResultsController.performFetch()
            getNewAlbumCollection()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    func releaseFetchedResultsController() {
        fetchedResultsController = nil
    }

    // MARK: - Request New Album Collection From API

    func getNewAlbumCollection() {
        gateway.getLocationAlbum(latitude: pin.latitude, longitude: pin.longitude) { imagesURLs in
            self.imagesURLs = imagesURLs
            self.collectionView.reloadData()
        }
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
}
