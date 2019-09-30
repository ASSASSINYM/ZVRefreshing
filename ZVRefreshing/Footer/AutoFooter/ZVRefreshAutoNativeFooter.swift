//
//  ZVRefreshAutoDIYFooter.swift
//  ZVRefreshing
//
//  Created by zevwings on 2017/7/17.
//  Copyright © 2017年 zevwings. All rights reserved.
//

import UIKit

public class ZVRefreshAutoNativeFooter: ZVRefreshAutoStateFooter {
    
    // MARK: - Property
    
    private var activityIndicator: UIActivityIndicatorView?
    
    public var activityIndicatorViewStyle: UIActivityIndicatorView.Style = .gray {
        didSet {
            activityIndicator?.style = activityIndicatorViewStyle
            setNeedsLayout()
        }
    }
    
    // MARK: - Subviews
    
    override public func prepare() {
        super.prepare()
        
        self.labelInsetLeft = 24.0
        
        if activityIndicator == nil {
            activityIndicator = UIActivityIndicatorView()
            activityIndicator?.style = activityIndicatorViewStyle
            activityIndicator?.hidesWhenStopped = true
            activityIndicator?.color = .lightGray
            addSubview(activityIndicator!)
        }
    }
    
    override public func placeSubViews() {
        super.placeSubViews()
        
        if let activityIndicator = activityIndicator, activityIndicator.constraints.isEmpty {
            
            var activityIndicatorCenterX = frame.width * 0.5
            if let stateLabel = stateLabel, !stateLabel.isHidden {
                //swiftlint:disable:next line_length
                activityIndicatorCenterX -= (stateLabel.textWidth * 0.5 + labelInsetLeft + activityIndicator.frame.width * 0.5)
            }
            
            let activityIndicatorCenterY = frame.height * 0.5
            activityIndicator.center = CGPoint(x: activityIndicatorCenterX, y: activityIndicatorCenterY)
        }
    }

    // MARK: - Do On State
    
    override public func doOnIdle(with oldState: RefreshState) {
        super.doOnIdle(with: oldState)
        
        activityIndicator?.stopAnimating()
    }
    
    override public func doOnNoMoreData(with oldState: RefreshState) {
        super.doOnNoMoreData(with: oldState)
        
        activityIndicator?.stopAnimating()
    }
    
    override public func doOnRefreshing(with oldState: RefreshState) {
        super.doOnRefreshing(with: oldState)
        
        activityIndicator?.startAnimating()
    }
}
