//
//  FlickrGateway.swift
//  VirtualTourist
//
//  Created by Márcio Oliveira on 9/20/20.
//  Copyright © 2020 Márcio Oliveira. All rights reserved.
//

import Foundation

class FlickrGateway {
    static let scheme = "https"
    static let host = "www.flickr.com"
    static let path = "/services/rest"

    static let apiKeyParam = "api_key"
    static let methodParam = "method"
    static let latitudeParam = "lat"
    static let longitudeParam = "lon"
    static let radiusParam = "radius"
    static let perPageParam = "per_page"
    static let pageParam = "page"
    static let formatParam = "format"
    static let noJsonCallBackParam = "nojsoncallback"

    static let searchMethodValue = "flickr.photos.search"
    static let radiusValue = 10
    static let perPageValue = 25

    static let getInfoMethodValue = "flickr.photos.getInfo"
    static let photoIdParam = "photo_id"
    static let photoSizeParam = "q" // Large Square

    static let formatValue = "json"
    static let noJsonCallBackValue = 1

    static var apiKey: String {
        if let path = Bundle.main.path(forResource: "Keys", ofType: "plist") {
            if let keys = NSDictionary(contentsOfFile: path) as? [String : AnyObject] {
                return (keys["FlickrApiKey"] as? String) ?? ""
            }
        }

        return ""
    }

    private var totalPages = 0
    private var randomPage: Int {
        // For some reason Flickr API always returns the first page when the requested page is big,
        // even if it is still smaller than returned total pages, so the randomization is lost.
        // So I've opted to use a fixed value to limit the requested page and ensure the randomization
        // Similar issue: https://stackoverflow.com/questions/44991024/python-flickrapi-search-photos-returns-the-same-picture-on-every-page
        1 + (totalPages > 0 ? Int(arc4random()) % 100 : totalPages)
    }

    func getLocationAlbum(latitude: Double, longitude: Double, completion: @escaping ([URL]) -> Void) {
        let url = getAlbumURL(latitude: latitude, longitude: longitude)
        let request = URLRequest(url: url)
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            guard let data = data,
                let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                let photos = json["photos"] as? [String: Any],
                let pages = photos["pages"] as? Int,
                let photo = photos["photo"] as? [[String: Any]]
            else {
                print("Invalid JSON")
                DispatchQueue.main.async {
                    completion([])
                }
                return
            }

            let imagesURLs: [URL] = photo.compactMap {
                self.getImageURL(photo: $0)
            }

            self.totalPages = pages

            DispatchQueue.main.async {
                completion(imagesURLs)
            }
        }
        task.resume()
    }

    private func getAlbumURL(latitude: Double, longitude: Double) -> URL {
        var urlComponent = URLComponents()

        urlComponent.scheme = FlickrGateway.scheme
        urlComponent.host = FlickrGateway.host
        urlComponent.path = FlickrGateway.path

        urlComponent.queryItems = [
            URLQueryItem(name: FlickrGateway.methodParam, value: FlickrGateway.searchMethodValue),
            URLQueryItem(name: FlickrGateway.apiKeyParam, value: FlickrGateway.apiKey),
            URLQueryItem(name: FlickrGateway.latitudeParam, value: "\(latitude)"),
            URLQueryItem(name: FlickrGateway.longitudeParam, value: "\(longitude)"),
            URLQueryItem(name: FlickrGateway.radiusParam, value: "\(FlickrGateway.radiusValue)"),
            URLQueryItem(name: FlickrGateway.perPageParam, value: "\(FlickrGateway.perPageValue)"),
            URLQueryItem(name: FlickrGateway.pageParam, value: "\(randomPage)"),
            URLQueryItem(name: FlickrGateway.formatParam, value: FlickrGateway.formatValue),
            URLQueryItem(name: FlickrGateway.noJsonCallBackParam, value: "\(FlickrGateway.noJsonCallBackValue)")
        ]

        return urlComponent.url!
    }

    private func getImageURL(photo: [String: Any]) -> URL? {
        guard let id = photo["id"] as? String,
            let farm = photo["farm"] as? Int,
            let server = photo["server"] as? String,
            let secret = photo["secret"] as? String else {
                return nil
        }

        let urlString = "https://farm\(farm).staticflickr.com/\(server)/\(id)_\(secret)_\(FlickrGateway.photoSizeParam).jpg"
        return URL(string: urlString)!
    }
}
