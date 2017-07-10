//
//  ZRefreshAnimationHeader.swift
//
//  Created by ZhangZZZZ on 16/4/1.
//  Copyright © 2016年 ZhangZZZZ. All rights reserved.
//

import UIKit

open class ZVRefreshAnimationHeader: ZVRefreshStateHeader {

    public fileprivate(set) lazy var animationView: UIImageView = {
        let animationView = UIImageView()
        animationView.backgroundColor = UIColor.clear
        return animationView
    }()
    
    fileprivate var stateImages: [ZVRefreshState: [UIImage]] = [:]
    fileprivate var stateDurations: [ZVRefreshState: TimeInterval] = [:]

    override var pullingPercent: CGFloat {
        didSet {
            let imgs = self.stateImages[.idle] ?? []
            if self.state != .idle || imgs.count == 0 { return }
            self.animationView.stopAnimating()
            var index = Int(CGFloat(imgs.count) * pullingPercent)
            if index >= imgs.count {
                index = imgs.count - 1
            }
            self.animationView.image = imgs[index]
        }
    }
    
    override open var state: ZVRefreshState {
        get {
            return super.state
        }
        set {
            if self.checkState(newValue).result { return }
            super.state = newValue
            
            if newValue == .pulling || newValue == .refreshing {
                let images = self.stateImages[newValue]
                if images?.count == 0 { return }
                self.animationView.stopAnimating()
                if images?.count == 1{
                    self.animationView.image = images?.last
                } else {
                    self.animationView.animationImages = images
                    self.animationView.animationDuration = self.stateDurations[newValue] ?? 0.0
                    self.animationView.startAnimating()
                }
            } else if newValue == .idle {
                self.animationView.stopAnimating()
            }
        }
    }
}

public extension ZVRefreshAnimationHeader {
    
    public func setImages(_ images: [UIImage], forState state: ZVRefreshState){
        self.setImages(images, duration: Double(images.count) * 0.1, forState: state)
    }
    
    public func setImages(_ images: [UIImage], duration: TimeInterval, forState state: ZVRefreshState){
        if images.count == 0 { return }
        
        self.stateImages.updateValue(images, forKey: state)
        self.stateDurations.updateValue(duration, forKey: state)
        if let image = images.first {
            if image.size.height > self.height {
                self.size.height = image.size.height
            }
        }
    }
}

extension ZVRefreshAnimationHeader {
    
    override open func prepare() {
        super.prepare()
        if self.animationView.superview == nil {
            self.addSubview(self.animationView)
        }
    }
    
    override open func placeSubViews() {
        super.placeSubViews()
        if self.animationView.constraints.count > 0 { return }
        self.animationView.frame = self.bounds
        if self.stateLabel.isHidden && self.lastUpdatedTimeLabel.isHidden {
            self.animationView.contentMode = .center
        } else {
            self.animationView.contentMode = .right
            self.animationView.size.width = self.width * 0.5 - 90
        }
    }
}
