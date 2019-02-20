//
//  Client.swift
//  VirtualTourist
//
//  Created by Ashish Nautiyal on 2/15/19.
//  Copyright © 2019 Ashish  Nautiyal. All rights reserved.
//

import Foundation
class Client {
    static let parseApiKey = "QuWThTdiRmTux3YaDseUSEpUKo7aBYM737yKd4gY"
    static let parseApplicationId = "QrX47CA9cyuGewLdsL7o5Eb8iug6Em8ye0dnAbIr"
    
    
    enum Endpoints {
        static let baseURLParse = "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=3f9181949a823bc69f117632b0af9a92&per_page=20&extras=url_m&format=json&nojsoncallback=1&page="
        case getApi(Double,Double,Int)
        var stringValue : String {
            switch self {
            case .getApi(let lat, let lon, let pageNumber):
                return Client.Endpoints.baseURLParse + "\(pageNumber)&lat=\(lat)&lon=\(lon)"
        
            }
        }
        var url: URL {
            return URL(string: stringValue)!
        }
    }
    
    class func getImages(latitude: Double, longitude : Double,_ pageNumber : Int,completion: @escaping (LocationResponse?,Error?) -> Void){
        taskForGETRequest(url: Endpoints.getApi(latitude, longitude,pageNumber).url, responseType: LocationResponse.self, completion: {
            (response, error)
            in
            
            if let response = response {
               completion(response,nil)
            }
            else {
               completion(nil,error)
            }
            
        })
    }
    
    
    class func taskForGETRequest<ResponseType: Decodable>(url: URL, responseType: ResponseType.Type, completion: @escaping (ResponseType?, Error?) -> Void)-> URLSessionTask{
        let request = URLRequest(url: url)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            let decoder = JSONDecoder()
            do {
                let responseObject = try decoder.decode(ResponseType.self, from: data)
                DispatchQueue.main.async {
                    completion(responseObject, nil)
                }
            } catch {
                do{
                    let errorResponse = try decoder.decode(ErrorResponse.self, from: data)
                    DispatchQueue.main.async {
                        completion(nil,errorResponse)
                    }
                }
                catch{
                    DispatchQueue.main.async {
                        completion(nil, error)
                    }}
            }
        }
        task.resume()
        return task
    }
    
    class func downloadImage(imagePath: String, completion: @escaping (Data?, Error?) -> Void) {
        let task = URLSession.shared.dataTask(with: URL(string: imagePath)!){
            (data,response,error)
            in
            DispatchQueue.main.async {
                guard let data = data else {
                    
                    completion(nil,error)
                    return
                }
                completion(data,nil)
                return
            }
        }
        task.resume()
    }
    
}
