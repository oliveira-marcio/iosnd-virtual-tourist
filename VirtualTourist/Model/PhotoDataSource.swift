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
    private var configureFunction: (PhotoCollectionViewCell, Data?) -> Void

    private var imagesURLs = [URL]()

    init(
        dataController: DataController,
        pin: Pin,
        gateway: FlickrGateway,
        collectionView: UICollectionView,
        configure: @escaping (PhotoCollectionViewCell, Data?) -> Void
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
        self.configureFunction = configure

        super.init()

        let cacheName = "image from pin (\(pin.latitude), \(pin.longitude))"

        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: viewManagedObjectContext, sectionNameKeyPath: nil, cacheName: cacheName)

        fetchedResultsController.delegate = self

        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    func releaseFetchedResultsController() {
        fetchedResultsController = nil
    }

    // MARK: - Request New Album Collection From API

    func getNewAlbumCollection(completion: @escaping (Bool) -> Void) {
        gateway.getLocationAlbum(latitude: pin.latitude, longitude: pin.longitude) { imagesURLs in
            self.imagesURLs = imagesURLs
            completion(imagesURLs.count > 0)
            print(imagesURLs)
//            self.collectionView.reloadData()
//            gateway.getPhoto(from: imagesURLs[indexPath.row]) { image in
//                self.configureFunction(cell, image)
//            }
        }
    }

    // MARK: - Collection View Delegate

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCollectionViewCell", for: indexPath) as! PhotoCollectionViewCell

        let photo = fetchedResultsController.object(at: indexPath)
        configureFunction(cell, photo.image)

        return cell
    }
}
