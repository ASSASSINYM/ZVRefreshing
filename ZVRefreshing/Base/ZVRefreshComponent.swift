//
//  ZRefreshComponent.swift
//
//  Created by ZhangZZZZ on 16/3/29.
//  Copyright © 2016年 ZhangZZZZ. All rights reserved.
//

import UIKit

open class ZVRefreshComponent: UIControl {
    
    public enum State {
        case idle
        case pulling
        case willRefresh
        case refreshing
        case noMoreData
    }
    
    // MARK: - Property
    
    public private(set) var isRefreshing: Bool = false

    private var _target: Any?
    private var _action: Selector?
    
    public var beginRefreshingCompletionHandler: ZVBeginRefreshingCompletionHandler?
    public var endRefreshingCompletionHandler: ZVEndRefreshingCompletionHandler?

    internal var scrollViewOriginalInset: UIEdgeInsets = UIEdgeInsets.zero

    internal var scrollView: UIScrollView?
    private var _panGestureRecognizer: UIPanGestureRecognizer?
    
    // MARK: getter & setter
    
    private var _refreshHandler: ZVRefreshHandler?
    public var refreshHandler: ZVRefreshHandler? {
        get {
            return _refreshHandler
        }
        set {
            _refreshHandler = newValue
        }
    }
    
    private var _refreshState: State = .idle
    open var refreshState: State {
        get {
            return _refreshState
        }
        set {
            let oldState = refreshState
            guard oldState != newValue else { return }
            
            willChangeValue(forKey: "isRefreshing")
            isRefreshing = newValue == .refreshing
            didChangeValue(forKey: "isRefreshing")
            
            willChangeValue(forKey: "refreshState")
            _refreshState = newValue
            didChangeValue(forKey: "refreshState")
            
            sendActions(for: .valueChanged)
            
            doOnAnyState(with: oldState)
            
            switch newValue {
            case .idle:
                doOnIdle(with: oldState)
                break
            case .noMoreData:
                doOnNoMoreData(with: oldState)
                break
            case .pulling:
                doOnPulling(with: oldState)
                break
            case .willRefresh:
                doOnWillRefresh(with: oldState)
                break
            case .refreshing:
                doOnRefreshing(with: oldState)
                break
            }
        }
    }
    
    // MARK: didSet
    
    public var isAutomaticallyChangeAlpha: Bool = true {
        didSet {
            guard isRefreshing == false else { return }
            if isAutomaticallyChangeAlpha {
                alpha = pullingPercent
            } else {
                alpha = 1.0
            }
        }
    }
    
    open var pullingPercent: CGFloat = 0.0 {
        didSet {
            guard isRefreshing == false else { return }
            if isAutomaticallyChangeAlpha { alpha = pullingPercent }
        }
    }
    
    // MARK: - Init
    
    /// Init
    public convenience init() {
        self.init(frame: .zero)
    }
    
    /// Init with callback closure
    ///
    /// - Parameter refreshHandler: callback closure
    public convenience init(refreshHandler: @escaping ZVRefreshHandler) {
        self.init(frame: .zero)
        _refreshHandler = refreshHandler
    }
    
    /// Init with callback target and selector
    ///
    /// - Parameters:
    ///   - target: callback target
    ///   - action: callback selector
    public convenience init(target: Any, action: Selector) {
        self.init(frame: .zero)
        _target = target
        _action = action
    }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        prepare()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        prepare()
    }
    
    // MARK: - Subviews
    
    open func prepare() {
        autoresizingMask = .flexibleWidth
        backgroundColor = .clear
    }
    
    open func placeSubViews() {}
    
    // MARK: - doOn

    open func doOnAnyState(with oldState: State) {}
    
    open func doOnIdle(with oldState: State) {}
    
    open func doOnNoMoreData(with oldState: State) {}

    open func doOnPulling(with oldState: State) {}
    
    open func doOnWillRefresh(with oldState: State) {}
    
    open func doOnRefreshing(with oldState: State) {}
    
    // MARK: - Observers
    
    open func scrollView(_ scrollView: UIScrollView, contentOffsetDidChanged value: [NSKeyValueChangeKey: Any]?) {}
    
    open func scrollView(_ scrollView: UIScrollView, contentSizeDidChanged value: [NSKeyValueChangeKey: Any]?) {}
    
    open func panGestureRecognizer(_ panGestureRecognizer: UIPanGestureRecognizer, stateValueChanged value: [NSKeyValueChangeKey: Any]?, for scrollView: UIScrollView) {}

}

// MARK: - System Override

extension ZVRefreshComponent {
    
    override open func layoutSubviews() {
        placeSubViews()
        super.layoutSubviews()
    }
    
    override open func draw(_ rect: CGRect) {
        super.draw(rect)
        if refreshState == .willRefresh { refreshState = .refreshing }
    }
    
    override open func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        
        guard let superview = newSuperview as? UIScrollView else { return }
        
//        if superview.isKind(of: UITableView.self) {
//            UITableView.once
//        } else if superview.isKind(of: UICollectionView.self) {
//            UICollectionView.once
//        }
        
        _removeObservers()
        
        frame.origin.x = 0
        frame.size.width = superview.frame.size.width
        backgroundColor = superview.backgroundColor
        
        scrollView = superview
        scrollView?.alwaysBounceVertical = true
        scrollViewOriginalInset = superview.contentInset
        
        _addObservers()
    }
}

// MARK: - State Control

extension ZVRefreshComponent {
    
    public func beginRefreshing() {
        
        UIView.animate(withDuration: AnimationDuration.fast, animations: {
            self.alpha = 1.0
        })
        
        pullingPercent = 1.0
        
        if window != nil {
            refreshState = .refreshing
        } else {
            if refreshState != .refreshing {
                refreshState = .willRefresh
                setNeedsDisplay()
            }
        }
    }
    
    public func beginRefreshing(with completionHandler: @escaping () -> ()) {
        beginRefreshingCompletionHandler = completionHandler
        beginRefreshing()
    }
    
    public func endRefreshing() {
        refreshState = .idle
    }
    
    public func endRefreshing(with completionHandler: @escaping () -> ()) {
        endRefreshingCompletionHandler = completionHandler
        endRefreshing()
    }
}

// MARK: - Observers

extension ZVRefreshComponent {
    
    private struct ObserversKeyPath {
        static let contentOffset = "contentOffset"
        static let contentInset  = "contentInset"
        static let contentSize   = "contentSize"
        static let panState      = "state"
    }

    private func _addObservers() {
        
        let options: NSKeyValueObservingOptions = [.new, .old]
        
        _panGestureRecognizer = scrollView?.panGestureRecognizer
        _panGestureRecognizer?.addObserver(self, forKeyPath: ObserversKeyPath.panState, options: options, context: nil)
        scrollView?.addObserver(self, forKeyPath: ObserversKeyPath.contentOffset, options: options, context: nil)
        scrollView?.addObserver(self, forKeyPath: ObserversKeyPath.contentSize, options: options, context: nil)
    }
    
    private func _removeObservers() {
        
        scrollView?.removeObserver(self, forKeyPath: ObserversKeyPath.contentOffset)
        scrollView?.removeObserver(self, forKeyPath: ObserversKeyPath.contentSize)
        scrollView?.removeObserver(self, forKeyPath: ObserversKeyPath.panState)
        _panGestureRecognizer = nil
    }
    
    override open func observeValue(forKeyPath keyPath: String?,
                                    of object: Any?,
                                    change: [NSKeyValueChangeKey : Any]?,
                                    context: UnsafeMutableRawPointer?) {

        guard isUserInteractionEnabled else { return }

        guard let superScrollView = scrollView else { return }
        
        if keyPath == ObserversKeyPath.contentSize {
            scrollView(superScrollView, contentSizeDidChanged: change)
        }

        guard isHidden == false else { return }

        if keyPath == ObserversKeyPath.contentOffset {
            scrollView(superScrollView, contentOffsetDidChanged: change)
        } else if keyPath == ObserversKeyPath.panState {
            panGestureRecognizer(superScrollView.panGestureRecognizer, stateValueChanged: change, for: superScrollView)
        }
    }
}

// MARK: - Public

public extension ZVRefreshComponent {
    
    public func addTarget(_ target: Any?, action: Selector) {
        _target = target
        _action = action
    }
}

// MARK: - Internal

extension ZVRefreshComponent {
    
    func executeRefreshCallback() {
        
        DispatchQueue.main.async {
            self._refreshHandler?()
            if let target = self._target, let action = self._action {
                if (target as AnyObject).responds(to: action) {
                    Thread.detachNewThreadSelector(action, toTarget: target, with: self)
                }
            }
            self.beginRefreshingCompletionHandler?()
        }
    }
}

