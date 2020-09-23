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
    private var isFirstLoading = true
    private var isBatchInsert = false
    private var isBatchDelete = false

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
        guard let photos = fetchedResultsController.fetchedObjects else {
            completion(false)
            return
        }

        if isFirstLoading && photos.count > 0 {
            isFirstLoading = false
            completion(true)
            return
        }

        deletePhotos()
        gateway.getLocationAlbum(latitude: pin.latitude, longitude: pin.longitude) { imagesURLs in
            self.imagesURLs = imagesURLs
            self.addBlankPhotos()
            completion(imagesURLs.count > 0)
//            self.collectionView.reloadData()
//            gateway.getPhoto(from: imagesURLs[indexPath.row]) { image in
//                self.configureFunction(cell, image)
//            }
        }
    }

    private func addBlankPhotos() {
        viewManagedObjectContext.perform {
            self.isBatchInsert = true

            for  _ in self.imagesURLs {
                let photo = Photo(context: self.viewManagedObjectContext)
                photo.image = nil
                photo.creationDate = Date()
                photo.pin = self.pin
            }

            try? self.viewManagedObjectContext.save()
            self.isBatchInsert = false
        }
    }

    private func deletePhotos() {
        guard let photos = fetchedResultsController.fetchedObjects else {
            return
        }

        viewManagedObjectContext.perform {
            self.isBatchDelete = true

            for photo in photos {
                self.viewManagedObjectContext.delete(photo)
            }

            try? self.viewManagedObjectContext.save()
            self.isBatchDelete = false
        }

    }

    private func updatePhoto(photo: Photo, rawImage: Data) {
        viewManagedObjectContext.perform {
            photo.image = rawImage
            try? self.viewManagedObjectContext.save()
        }
    }

    // MARK: - Collection View data source

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return fetchedResultsController.sections?.count ?? 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCollectionViewCell", for: indexPath) as! PhotoCollectionViewCell

        let photo = fetchedResultsController.object(at: indexPath)
        configureFunction(cell, photo.image)

        return cell
    }

     // MARK: - Fetched Results Controller Delegate

    var operationQueue: [BlockOperation]!

    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        operationQueue = [BlockOperation]()
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if isBatchInsert || isBatchDelete {
            collectionView.reloadData()
        }

        for operation in operationQueue {
            operation.start()
        }

        operationQueue = nil
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            if self.isBatchInsert {
                return
            }

            let operation = BlockOperation(block: { () -> Void in
                guard let indexPath = newIndexPath else {
                    return
                }

                self.collectionView.insertItems(at: [indexPath])
            })

            operationQueue.append(operation)
        case .delete:
            if self.isBatchDelete {
                return
            }

            let operation = BlockOperation(block: { () -> Void in
                guard let indexPath = indexPath else {
                    return
                }

                self.collectionView.deleteItems(at: [indexPath])
            })

            operationQueue.append(operation)
        case .update:
            let operation = BlockOperation(block: { () -> Void in
                guard let indexPath = indexPath else {
                    return
                }

                guard let cell = self.collectionView.cellForItem(at: indexPath) as? PhotoCollectionViewCell else {
                    return
                }

                let photo = anObject as! Photo
                self.configureFunction(cell, photo.image)
            })
            operationQueue.append(operation)

        default:
            break
        }
    }
}
