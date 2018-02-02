//
//  ZRefreshHeader.swift
//
//  Created by ZhangZZZZ on 16/3/30.
//  Copyright © 2016年 ZhangZZZZ. All rights reserved.
//

import UIKit

open class ZVRefreshHeader: ZVRefreshComponent {
    
    // MARK: - Property
    
    public var ignoredScrollViewContentInsetTop: CGFloat = 0.0

    private var insetTop: CGFloat = 0.0
    
    // MARK: - Subviews
    
    override open func prepare() {
        super.prepare()
    }
    
    override open func placeSubViews() {
        super.placeSubViews()
        
        frame.size.height = ComponentHeader.height
        frame.origin.y = -frame.height - ignoredScrollViewContentInsetTop
    }

    // MARK: - Observers
    
    override open func scrollView(_ scrollView: UIScrollView, contentOffsetDidChanged value: [NSKeyValueChangeKey : Any]?) {
        
        guard refreshState != .refreshing else {
            
            guard window != nil else { return }
            
            var insetT = -scrollView.contentOffset.y > scrollViewOriginalInset.top ? -scrollView.contentOffset.y : scrollViewOriginalInset.top
            insetT = insetT > frame.height + scrollViewOriginalInset.top ? frame.height + scrollViewOriginalInset.top : insetT
            
            scrollView.contentInset.top = insetT
            insetTop = scrollViewOriginalInset.top - insetT
            
            return
        }
        
        scrollViewOriginalInset = scrollView.contentInset
        
        let offsetY = scrollView.contentOffset.y
        let happenOffsetY = -scrollViewOriginalInset.top
        
        guard offsetY <= happenOffsetY else { return }
        
        let normal2pullingOffsetY = happenOffsetY - frame.height
        let pullingPercent = (happenOffsetY - offsetY) / frame.height
        
        if scrollView.isDragging {
            self.pullingPercent = pullingPercent
            if refreshState == .idle && offsetY < normal2pullingOffsetY {
                refreshState = .pulling
            } else if refreshState == .pulling && offsetY >= normal2pullingOffsetY {
                refreshState = .idle
            }
        } else if refreshState == .pulling {
            beginRefreshing()
        }else if pullingPercent < 1 {
            self.pullingPercent = pullingPercent
        }
    }
    
    // MARK: - Do On State
    
    open override func doOnIdle(with oldState: ZVRefreshComponent.State) {
        super.doOnIdle(with: oldState)
        
        guard oldState == .refreshing else { return }
        
        UIView.animate(withDuration: AnimationDuration.slow, animations: {
            self.scrollView?.contentInset.top += self.insetTop
            if self.isAutomaticallyChangeAlpha { self.alpha = 0.0 }
        }, completion: { _  in
            self.pullingPercent = 0.0
            self.endRefreshingCompletionHandler?()
        })
    }
    
    open override func doOnRefreshing(with oldState: ZVRefreshComponent.State) {
        super.doOnRefreshing(with: oldState)
        
        DispatchQueue.main.async {
            UIView.animate(withDuration: AnimationDuration.fast, animations: {
                let top = self.scrollViewOriginalInset.top + self.frame.height
                self.scrollView?.contentInset.top = top
                var offset = self.scrollView!.contentOffset
                offset.y = -top
                self.scrollView?.setContentOffset(offset, animated: false)
            }, completion: { _ in
                self.executeRefreshCallback()
            })
        }
    }
}

