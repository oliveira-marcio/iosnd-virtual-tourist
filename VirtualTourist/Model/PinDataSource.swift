//
//  PinDataSource.swift
//  VirtualTourist
//
//  Created by Márcio Oliveira on 9/22/20.
//  Copyright © 2020 Márcio Oliveira. All rights reserved.
//

import CoreData
import UIKit

class PinDataSource: NSObject, NSFetchedResultsControllerDelegate {
    private var viewManagedObjectContext: NSManagedObjectContext!
    private var fetchedResultsController: NSFetchedResultsController<Pin>!
    private var onUpdate: (([Pin]) -> Void)?

    init(
        dataController: DataController,
        onUpdate: (([Pin]) -> Void)?
    ) {
        viewManagedObjectContext = dataController.viewContext

        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()

        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]

        self.onUpdate = onUpdate

        super.init()

        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "pins")

        fetchedResultsController.delegate = self

        do {
            try fetchedResultsController.performFetch()
            onUpdate?(fetchedResultsController.fetchedObjects ?? [])
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }

    func releaseFetchedResultsController() {
        fetchedResultsController = nil
    }

    // MARK: - Pin Data Manipulation

    func addPin(latitude: Double, longitude: Double) {
        let pin = Pin(context: viewManagedObjectContext)
        pin.latitude = latitude
        pin.longitude = longitude
        pin.creationDate = Date()

        try? viewManagedObjectContext.save()
    }

    func getPin(latitude: Double, longitude: Double) -> Pin? {
        guard let pins = fetchedResultsController.fetchedObjects else {
            return nil
        }

        return pins.first(where: {
            let expectedLat = latitude
            let currentLat = $0.latitude

            let expectedLong = longitude
            let currentLong = $0.longitude

            return expectedLat == currentLat && expectedLong == currentLong
        })
    }

    func deletePin(_ pin: Pin) {
        viewManagedObjectContext.delete(pin)
        try? viewManagedObjectContext.save()
    }

    // MARK: - Fetched Results Controller Delegate

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        onUpdate?(fetchedResultsController.fetchedObjects ?? [])
    }
}
