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
    var travelLocationsMapViewController: TravelLocationsMapViewController!

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        dataController.load()

        injectDependencies()

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

    private func injectDependencies() {
        let navigationController = window?.rootViewController as! UINavigationController
        travelLocationsMapViewController = navigationController.topViewController as? TravelLocationsMapViewController

        travelLocationsMapViewController.dataController = dataController
        travelLocationsMapViewController.gateway = FlickrGateway()
    }

    private func saveMapRegion() {
        travelLocationsMapViewController?.saveMapRegion()
    }

    private func saveViewContext() {
        try? dataController.viewContext.save()
    }
}

