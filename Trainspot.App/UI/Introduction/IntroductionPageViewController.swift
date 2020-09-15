//
//  IntroductionPageViewController.swift
//  Trainspot.App
//
//  Created by Philipp Hentschel on 14.09.20.
//  Copyright © 2020 Philipp Hentschel. All rights reserved.
//

import Foundation
import UIKit

class IntroductionPageViewController : UIPageViewController {
    
    private var pageViewController: UIPageViewController?
    
    private(set) lazy var tutorialViewControllers: [UIViewController] = {
        return [self.getTutorialViewController(onPage: 1),
                self.getTutorialViewController(onPage: 2),
                self.getTutorialViewController(onPage: 3)]
    }()
    
    override func viewDidLoad() {
        self.dataSource = self
        
        setViewControllers([
            getTutorialViewController(onPage: 1)], direction: .forward, animated: true, completion: nil)
    }

    private func getTutorialViewController(onPage page: Int) -> UIViewController {
        return UIStoryboard(name: "Introduction", bundle: nil) .
            instantiateViewController(withIdentifier: "Page \(page)")
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.destination {
        case let vc1 as IntroductionPageViewController:
            self.pageViewController = vc1
        default:
            break
        }
    }
}

extension IntroductionPageViewController: UIPageViewControllerDataSource {
    
   
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        return nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        return nil
    }
    
    
    
}

extension IntroductionPageViewController: UIPageViewControllerDelegate {
    
}


