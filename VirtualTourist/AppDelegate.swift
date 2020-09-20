//
//  AppDelegate.swift
//  VirtualTourist
//
//  Created by Márcio Oliveira on 9/14/20.
//  Copyright © 2020 Márcio Oliveira. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    let dataController = DataController(modelName: "VirtualTourist")

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        dataController.load()

        let navigationController = window?.rootViewController as! UINavigationController
        let travelLocationsMapViewController = navigationController.topViewController as! TravelLocationsMapViewController
        travelLocationsMapViewController.dataController = dataController
        travelLocationsMapViewController.gateway = FlickrGateway()

        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        saveMapRegion()
        saveViewContext()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        saveMapRegion()
        saveViewContext()
    }

    private func saveMapRegion() {
        let navigationController = window?.rootViewController as! UINavigationController
        let travelLocationsMapViewController = navigationController.topViewController as? TravelLocationsMapViewController
        travelLocationsMapViewController?.saveMapRegion()
    }

    private func saveViewContext() {
        try? dataController.viewContext.save()
    }
}

