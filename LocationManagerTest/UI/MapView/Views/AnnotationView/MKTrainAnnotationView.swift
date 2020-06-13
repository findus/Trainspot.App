//
//  MKTrainAnnotationView.swift
//  LocationManagerTest
//
//  Created by Philipp Hentschel on 12.06.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import UIKit
import MapKit

class MKTrainAnnotationView: MKAnnotationView {

    @IBOutlet weak var icon: UIImageView!
    @IBOutlet var positionDot: MKTrainAnnotationView!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private func setupUI() {
        backgroundColor = .red
    }
    

}
