//
//  StackCardViewController.swift
//  PKit
//
//  Created by Plumk on 2019/7/15.
//  Copyright © 2019 Plumk. All rights reserved.
//

import UIKit
import PKit

class StackCardViewController: UIViewController, PKUIStackCardViewDelegate {
    
    var stackCardView: PKUIStackCardView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        self.stackCardView = PKUIStackCardView.init(cardSize: .init(width: 330, height: 490), leakCount: 10)
        self.stackCardView.sizeToFit()
        self.stackCardView.frame.origin = .init(x: (view.bounds.width - 331) / 2, y: 100)
        self.stackCardView.delegate = self
        self.view.addSubview(self.stackCardView)
        
        self.reloadViews()
        
        self.navigationItem.rightBarButtonItems = [
            .init(title: "Reload", style: .plain, target: self, action: #selector(reloadItemClick)),
            .init(title: "Append", style: .plain, target: self, action: #selector(appendItemClick)),
            .init(title: "Next", style: .plain, target: self, action: #selector(nextItemClick))]
    }
    
    @objc func reloadItemClick() {
        self.reloadViews()
    }
    
    @objc func appendItemClick() {
        self.appendViews()
    }
    
    @objc func nextItemClick() {
        self.stackCardView.pop(.right)
    }
    
    func reloadViews() {
        var views = [UIView]()
        for _ in 0 ..< 10 {
            let view = UIView.init(frame: .init(x: 0, y: 0, width: 331, height: 490))
            view.backgroundColor = .init(red: CGFloat(arc4random_uniform(255)) / 255.0, green: CGFloat(arc4random_uniform(255)) / 255.0, blue: CGFloat(arc4random_uniform(255)) / 255.0, alpha: 1)
            views.append(view)
        }
        
        self.stackCardView.setCardViews(views)
    }
    
    func appendViews() {
        var views = [UIView]()
        for _ in 0 ..< 10 {
            let view = UIView.init(frame: .init(x: 0, y: 0, width: 331, height: 490))
            view.backgroundColor = .init(red: CGFloat(arc4random_uniform(255)) / 255.0, green: CGFloat(arc4random_uniform(255)) / 255.0, blue: CGFloat(arc4random_uniform(255)) / 255.0, alpha: 1)
            views.append(view)
        }
        
        self.stackCardView.appendCardViews(views)
    }
    
    
    // MARK: - PKUIStackCardViewDelegate
    func stackCardView(_ stackCardView: PKUIStackCardView, didDismiss card: PKUIStackCardView.CardView, direction: PKUIStackCardView.Direction) {
        print("didDismiss", card, direction.rawValue)
    }
    
    func stackCardView(_ stackCardView: PKUIStackCardView, didAppear card: PKUIStackCardView.CardView, nextCard: PKUIStackCardView.CardView?) {
        print("didAppear", card, nextCard)
    }
    
    func stackCardView(_ stackCardView: PKUIStackCardView, didChangeProgress progress: CGFloat) {
        print("didChangeProgress", progress)
    }
    
    func stackCardView(_ stackCardView: PKUIStackCardView, canPop card: PKUIStackCardView.CardView) -> Bool {
        return false
    }
}
