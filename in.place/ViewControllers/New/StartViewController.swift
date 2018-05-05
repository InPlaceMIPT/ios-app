//
//  StartViewController.swift
//  in.place
//
//  Created by Дмитрий Ткаченко on 04/04/2018.
//  Copyright © 2018 in.place. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import MapKit

class StartViewController: UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet weak var placesTable: UITableView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var image1: UIImageView!
    @IBOutlet weak var image2: UIImageView!
    @IBOutlet weak var image3: UIImageView!
    @IBOutlet weak var image4: UIImageView!
    
    @IBOutlet weak var map: MKMapView!
    
    @IBOutlet weak var stackView: UIStackView!
    
    let answers = ["Один",
                   "С парой",
                   "С друзьями",
                   "Семьей"]
    var mainImages = [UIImageView]()
    var storage = SmartStorage()
    var locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.storage.delegate = self
        
        self.activityIndicator.hidesWhenStopped = true
        self.activityIndicator.color = color4
        self.activityIndicator.stopAnimating()
        
        self.mainImages.append(self.image1)
        self.mainImages.append(self.image2)
        self.mainImages.append(self.image3)
        self.mainImages.append(self.image4)
        
        self.hideButtons()
        
        self.placesTable.dataSource = self.storage
        self.placesTable.delegate = self.storage
        
        self.fetchPictures()
        
        // Adding UITapGestureRecognisers for images
        for imageView in self.mainImages {
            imageView.addGestureRecognizer(UITapGestureRecognizer(target:self, action: #selector(self.tappedImage(sender:))))
        }
        
        //Check for Location Services
        if (CLLocationManager.locationServicesEnabled()) {
            locationManager = CLLocationManager()
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.requestAlwaysAuthorization()
            locationManager.requestWhenInUseAuthorization()
        }
        locationManager.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            locationManager.startUpdatingLocation()
        }
        //Zoom to user location
        let userLocation = locationManager.location?.coordinate
        //let viewRegion = MKCoordinateRegionMakeWithDistance(userLocation!, 20000, 20000)
        //map.setRegion(viewRegion, animated: false)
        
        DispatchQueue.main.async {
            self.locationManager.startUpdatingLocation()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func fetchPictures() {
        self.label.text = "Загружаем данные..."
        self.activityIndicator.frame = CGRect(x: UIScreen.main.bounds.midX - self.activityIndicator.frame.width / 2,
                                              y: self.label.frame.maxY + 8,
                                              width: self.activityIndicator.frame.width,
                                              height: self.activityIndicator.frame.height)
        self.storage.fetchPictures()
        self.activityIndicator.startAnimating()
        
    }
    
    func hideButtons() {
        for button in self.mainImages {
            button.isHidden = true
            button.isUserInteractionEnabled = false
        }
    }
    
    func showButtons() {
        for button in self.mainImages {
            button.isHidden = false
            button.isUserInteractionEnabled = true
        }
    }
    
    @objc func tappedImage(sender: UITapGestureRecognizer) {
        let imageView = sender.view as! UIImageView
        switch imageView {
        case self.image1:
            self.storage.userAnswers.append(self.storage.setIDs[storage.currentSet][0])
            break
        case self.image2:
            self.storage.userAnswers.append(self.storage.setIDs[storage.currentSet][1])
            break
        case self.image3:
            self.storage.userAnswers.append(self.storage.setIDs[storage.currentSet][2])
            break
        case self.image4:
            self.storage.userAnswers.append(self.storage.setIDs[storage.currentSet][3])
            break
        default:
            break
        }
        
        if self.storage.currentSet == 4 {
            self.hideButtons()
            self.label.alpha = 1
            self.view.backgroundColor = color2
            self.label.text = "Находим лучшие места и события для вас..."
            self.activityIndicator.startAnimating()
            self.storage.getPlaces()
            return
        }
        
        storage.currentSet += 1
        fitButtonsWithImages(set: storage.currentSet)
    }
    
    func fitButtonsWithImages(set: Int) {
        for (ind, imageView) in self.mainImages.enumerated() {
            UIView.transition(with: imageView,
                              duration: 0.4,
                              options: (ind % 2 == 1) ? UIViewAnimationOptions.transitionFlipFromRight : UIViewAnimationOptions.transitionFlipFromLeft,
                              animations: { imageView.image = self.storage.images[set * 4 + ind] },
                              completion: nil)
        }
    }
    
    func changeLabel() {
        self.label.alpha = 0
        self.fitButtonsWithImages(set: self.storage.currentSet)
    }
}

extension StartViewController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.answers.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "answerCell")
        
        cell?.textLabel?.text = self.answers[indexPath.row]
        cell?.textLabel?.textColor = color4
        cell?.textLabel?.textAlignment = NSTextAlignment.center
        
        return cell!
    }
}

extension StartViewController : SmartStorageDelegate {
    
    func updateWhenPicturesDownloaded() {
        self.activityIndicator.stopAnimating()
        self.changeLabel()
        self.view.backgroundColor = UIColor.black
        
        self.showButtons()
    }
    
    func updateWhenPlacesDownloaded() {
        self.label.alpha = 0
        //self.label.text = "Лучшие события для тебя:"
        self.label.textColor = color2
        self.activityIndicator.stopAnimating()
        
        for place in self.storage.specificPlacesJSON["places"].arrayValue {
            let annotation = MKPointAnnotation()
            annotation.title = place["title"].stringValue
            annotation.coordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(place["location"]["latitude"].floatValue),
                                                           longitude: CLLocationDegrees(place["location"]["longitude"].floatValue))
            self.map.addAnnotation(annotation)
        }
        
        self.placesTable.reloadData()
        self.placesTable.isHidden = false
        self.placesTable.isUserInteractionEnabled = true
        self.map.showsUserLocation = true
        self.map.isHidden = false
    }
}
