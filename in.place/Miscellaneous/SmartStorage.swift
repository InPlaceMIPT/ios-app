//
//  SmartStorage.swift
//  in.place
//
//  Created by Дмитрий Ткаченко on 07/04/2018.
//  Copyright © 2018 in.place. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON
import MapKit

class SmartStorage : NSObject {
    
    var userAnswers = [Int]()
    var currentSet = 0
    var placesData : Data!
    var placesJSON : JSON!
    var placesIDs = [Int]()
    var picData : Data!
    var picJSON : JSON!
    var places = [JSON]()
    
    var setIDs = [[Int]]()
    
    var images = [UIImage](repeating: UIImage(), count: 20)
    
    var specificPlacesData : Data!
    var specificPlacesJSON : JSON!
    
    var delegate : SmartStorageDelegate?
    
    override init() {
        super.init()
        self.delegate = nil
    }
    
    func fetchPictures() {
        DispatchQueue.global(qos: .utility).async {
            Alamofire.request("https://inplace-api.herokuapp.com/api/images/set/").responseData(completionHandler: { (response) in
                if let data = response.result.value {
                    self.picData = data
                    DispatchQueue.main.async {
                        self.parsePictures()
                    }
                }
            })
        }
    }
    
    func parsePictures() {
        do {
            try self.picJSON = JSON(data: self.picData)
        } catch {
            print("PLOHA")
        }
        self.prepareImageSets()
    }
    
    func prepareImageSets() {
        let group = DispatchGroup()
        for i in 0..<5 {
            group.enter()
            
            Alamofire.request("https://inplace-api.herokuapp.com/api/images/4set/ids/?group=\(i)").responseString(completionHandler: { (response) in
                if let string = response.result.value {
                    let substrings = string.components(separatedBy: CharacterSet.decimalDigits.inverted)
                    let IDs = substrings.flatMap { return Int($0) }
                    self.setIDs.append(IDs)
                    group.leave()
                }
            })
            
            
        }
        
        group.notify(queue: DispatchQueue.main, execute: {
            print("Prepare sets group done")
            self.downloadImages()
        })
    }
    
    func downloadImages() {
        
        let group = DispatchGroup()
        
        for (ind, set) in self.setIDs.enumerated() {
            for (i, id) in set.enumerated() {
                group.enter()
                var tmp = ""
                for json in self.picJSON.arrayValue {
                    if json["image_id"].intValue == id {
                        tmp = json["image"].stringValue
                    }
                }
                let url = URL(string: tmp)
                
                Alamofire.request(url!).responseData(completionHandler: { (response) in
                    if let data = response.result.value {
                        //print(url!)
                        self.images[4 * ind + i] = UIImage(data: data)!
                        group.leave()
                    }
                })
            }
        }
        
        group.notify(queue: DispatchQueue.main) {
            print("Images for sets downloaded")
            self.delegate?.updateWhenPicturesDownloaded()
        }
    }
    
    func getPlaces() {
        let parameters = ["images" : self.userAnswers]
        let headers = ["Content-Type" : "application/json"]
        Alamofire.request("https://inplace-api.herokuapp.com/api/recommend/byimageid/", method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).responseData(completionHandler: { (response) in
            if let data = response.result.value {
                self.placesData = data
                DispatchQueue.main.async {
                    self.parsePlaces()
                }
            }
        })
    }
    
    func parsePlaces() {
        do {
            try self.placesJSON = JSON(data: self.placesData)
        } catch {
            print("PLOHA")
        }
        self.getSpecificPlaces()
    }
    
    func getSpecificPlaces() {
        
        for placeID in self.placesJSON["events"].arrayValue {
            self.placesIDs.append(placeID.intValue)
        }
        
        let parameters = ["events" : self.placesIDs]
        let headers = ["Content-Type" : "application/json"]
        Alamofire.request("https://inplace-api.herokuapp.com/api/places/info/list/", method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).responseData(completionHandler: { (response) in
            if let data = response.result.value {
                self.specificPlacesData = data
                DispatchQueue.main.async {
                    self.parseSpecificPlaces()
                }
            }
        })
    }
    
    func parseSpecificPlaces() {
        do {
            try self.specificPlacesJSON = JSON(data: self.specificPlacesData)
        } catch {
            print("PLOHA")
        }
        self.delegate?.updateWhenPlacesDownloaded()
    }
    
    
}


protocol SmartStorageDelegate {
    
    func updateWhenPicturesDownloaded()
    func updateWhenPlacesDownloaded()
    
    weak var map: MKMapView! {get set}
    
}

extension SmartStorage : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let data = self.specificPlacesJSON {
            return data["places"].arrayValue.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "placeCell") as! PlaceTableViewCell
        
        cell.title.text = self.specificPlacesJSON["places"].arrayValue[indexPath.row]["title"].stringValue
        cell.descr.text = self.specificPlacesJSON["places"].arrayValue[indexPath.row]["description"].stringValue
        cell.time.text = self.specificPlacesJSON["places"].arrayValue[indexPath.row]["timetable"].stringValue
        
        return cell
    }
}

extension SmartStorage : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let point = CLLocationCoordinate2DMake(CLLocationDegrees(self.specificPlacesJSON["places"].arrayValue[indexPath.row]["location"]["latitude"].floatValue), CLLocationDegrees(self.specificPlacesJSON["places"].arrayValue[indexPath.row]["location"]["longitude"].floatValue))
        self.delegate?.map.setCenter(point, animated: true)
    }
    
}
