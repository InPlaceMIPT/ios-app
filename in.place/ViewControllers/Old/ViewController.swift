//
//  ViewController.swift
//  in.place
//
//  Created by Дмитрий Ткаченко on 23/03/2018.
//  Copyright © 2018 in.place. All rights reserved.
//

import UIKit
import Koloda

class ViewController: UIViewController {

    @IBOutlet weak var hiLabel: UILabel!
    @IBOutlet weak var kolodaView: KolodaView!
    
    var images = [#imageLiteral(resourceName: "Beach"), #imageLiteral(resourceName: "Space")]
    let animationTime = 1.5
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        kolodaView.delegate = self
        kolodaView.dataSource = self
        
        UIView.animate(withDuration: animationTime, animations: {
            self.hiLabel.alpha = 1
        }) { (boolka) in
            UIView.animate(withDuration: self.animationTime, animations: {
                self.hiLabel.alpha = 0
            }, completion: { (boolka) in
                self.hiLabel.text = "Загружаем данные"
                UIView.animate(withDuration: self.animationTime, animations: {
                    self.hiLabel.alpha = 1
                }, completion: { (boolka) in
                    UIView.animate(withDuration: self.animationTime, animations: {
                        self.hiLabel.alpha = 0
                    }, completion: { (boolka) in
                        self.hiLabel.text = "Теперь мы поможем тебе выбрать подходящие мероприятия!"
                        UIView.animate(withDuration: self.animationTime, animations: {
                            self.hiLabel.alpha = 1
                        }, completion: { (boolka) in
                            UIView.animate(withDuration: self.animationTime, animations: {
                                self.hiLabel.alpha = 0
                            }, completion: { (boolka) in
                                UIView.animate(withDuration: self.animationTime, animations: {
                                    self.kolodaView.alpha = 1
                                })
                            })
                        })
                    })
                })
            })
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

extension ViewController: KolodaViewDelegate {
    func kolodaDidRunOutOfCards(_ koloda: KolodaView) {
        koloda.reloadData()
        UIView.animate(withDuration: self.animationTime / 2, animations: {
            self.kolodaView.alpha = 0
        }) { (boolka) in
            self.hiLabel.text = "Подбираем события"
            UIView.animate(withDuration: self.animationTime, animations: {
                self.hiLabel.alpha = 1
            }, completion: { (boolka) in
                UIView.animate(withDuration: self.animationTime, animations: {
                    self.hiLabel.alpha = 0
                }, completion: { (boolka) in
                    self.present(UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ListViewController"), animated: true, completion: nil)
                })
            })
        }
    }
    
    func koloda(_ koloda: KolodaView, didSelectCardAt index: Int) {
        return
    }
}

extension ViewController: KolodaViewDataSource {
    func kolodaNumberOfCards(_ koloda: KolodaView) -> Int {
        return self.images.count
    }
    
    func kolodaSpeedThatCardShouldDrag(_ koloda: KolodaView) -> DragSpeed {
        return .fast
    }
    
    func koloda(_ koloda: KolodaView, viewForCardAt index: Int) -> UIView {
        return UIImageView(image: self.images[index])
    }
    
    func koloda(_ koloda: KolodaView, viewForCardOverlayAt index: Int) -> OverlayView? {
        return Bundle.main.loadNibNamed("OverlayView", owner: self, options: nil)![0] as? OverlayView
    }
}
