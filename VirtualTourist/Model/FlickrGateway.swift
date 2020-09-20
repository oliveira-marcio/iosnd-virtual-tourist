//
//  FlickrGateway.swift
//  VirtualTourist
//
//  Created by Márcio Oliveira on 9/20/20.
//  Copyright © 2020 Márcio Oliveira. All rights reserved.
//

import Foundation

struct FlickrGateway {

    enum Endpoints {
        static let scheme = "https"
        static let host = "www.flickr.com"
        static let path = "/services/rest"

        static let apiKeyParam = "api_key"
        static let methodParam = "method"
        static let latitudeParam = "lat"
        static let longitudeParam = "lon"
        static let radiusParam = "radius"
        static let perPageParam = "per_page"
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

        case getLocationAlbum(Double, Double)
        case getImage(String)

        var url: URL {
            switch self {
            case .getLocationAlbum(let latitude, let longitude): return makeAlbumURL(latitude: latitude, longitude: longitude)
            case .getImage(let id): return makeImageURL(id: id)
            }
        }

        private func makeAlbumURL(latitude: Double, longitude: Double) -> URL {
            var urlComponent = URLComponents()

            urlComponent.scheme = Endpoints.scheme
            urlComponent.host = Endpoints.host
            urlComponent.path = Endpoints.path

            urlComponent.queryItems = [
                URLQueryItem(name: Endpoints.methodParam, value: Endpoints.searchMethodValue),
                URLQueryItem(name: Endpoints.apiKeyParam, value: Endpoints.apiKey),
                URLQueryItem(name: Endpoints.latitudeParam, value: "\(latitude)"),
                URLQueryItem(name: Endpoints.longitudeParam, value: "\(longitude)"),
                URLQueryItem(name: Endpoints.radiusParam, value: "\(Endpoints.radiusValue)"),
                URLQueryItem(name: Endpoints.perPageParam, value: "\(Endpoints.perPageValue)"),
                URLQueryItem(name: Endpoints.formatParam, value: Endpoints.formatValue),
                URLQueryItem(name: Endpoints.noJsonCallBackParam, value: "\(Endpoints.noJsonCallBackValue)")
            ]

            return urlComponent.url!
        }

        private func makeImageURL(id: String) -> URL {
            var urlComponent = URLComponents()

            urlComponent.scheme = Endpoints.scheme
            urlComponent.host = Endpoints.host
            urlComponent.path = Endpoints.path

            urlComponent.queryItems = [
                URLQueryItem(name: Endpoints.methodParam, value: Endpoints.getInfoMethodValue),
                URLQueryItem(name: Endpoints.apiKeyParam, value: Endpoints.apiKey),
                URLQueryItem(name: Endpoints.photoIdParam, value: "\(id)"),
                URLQueryItem(name: Endpoints.formatParam, value: Endpoints.formatValue),
                URLQueryItem(name: Endpoints.noJsonCallBackParam, value: "\(Endpoints.noJsonCallBackValue)")
            ]

            return urlComponent.url!
        }
    }

    func getLocationAlbum(latitude: Double, longitude: Double) {
        let request = URLRequest(url: Endpoints.getLocationAlbum(latitude, longitude).url)
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            guard let data = data,
                let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                let photos = json["photos"] as? [String: Any],
                let pages = photos["pages"] as? Int,
                let photo = photos["photo"] as? [[String: Any]]
            else {
                print("Invalid JSON")
                return
            }

            let ids: [String] = photo.compactMap {
                $0["id"] as? String
            }

            print("Pages: \(pages)")
            print("IDs: \(ids)")
        }
        task.resume()
    }

    func getImage(id: String) {
        let request = URLRequest(url: Endpoints.getImage(id).url)
        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            guard let data = data,
                let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                let photo = json["photo"] as? [String: Any],
                let farm = photo["farm"] as? Int,
                let server = photo["server"] as? String,
                let secret = photo["secret"] as? String
            else {
                print("Invalid JSON")
                return
            }

            let imageUrl = self.createImageURL(id: id, farm: farm, server: server, secret: secret)
            print(imageUrl)
        }
        task.resume()
    }

    private func createImageURL(id: String, farm: Int, server: String, secret: String) -> URL {
        let urlString = "https://farm\(farm).staticflickr.com/\(server)/\(id)_\(secret)_\(Endpoints.photoSizeParam).jpg"
        return URL(string: urlString)!
    }
}
