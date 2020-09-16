//
//  InfoViewController.swift
//  Trainspot.App
//
//  Created by Philipp Hentschel on 16.09.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import UIKit

class InfoViewController: UIViewController {

    @IBOutlet weak var backendLabel: UITextView!
    @IBOutlet weak var podsTextView: UITextView!
    @IBOutlet weak var githubLabel: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setLink("https://github.com/Daltron/NotificationBanner", "NotificationBannerSwift", self.podsTextView)
        
         self.setLink("https://cocoapods.org/pods/Log", "Log", self.podsTextView)
        
        self.setLink("https://cocoapods.org/pods/SwiftEventBus", "SwiftEventBus", self.podsTextView)
        
        self.setLink("https://cocoapods.org/pods/SwiftyJSON", "SwiftyJSON", self.podsTextView)
        
        self.setLink("https://cocoapods.org/pods/Alamofire", "Alamofire 5.2", self.podsTextView)
        
        
        self.setLink("https://transport.rest/", "Transport.rest", self.backendLabel)
        
         self.setLink("https://transport.f1ndus.de", "https://transport.f1ndus.de", self.backendLabel)
        
        self.setLink("https://github.com/findus/Trainspot.App", "Das Projekt auf Github", self.githubLabel)
        
        
        
    }
    
    private func setLink(_ url: String, _ placeholder: String, _ comp: UITextView) {
        let text = comp.attributedText
        let highLightedText = NSMutableAttributedString(attributedString: text!)
        highLightedText.addAttribute(NSMutableAttributedString.Key.foregroundColor, value: UIColor.label, range: NSRange(location: 0, length: highLightedText.length))
        highLightedText.setAsLink(textToFind: placeholder, linkURL: url)
        // Do any additional setup after loading the view.
        comp.attributedText = highLightedText
    }
    

   
}
