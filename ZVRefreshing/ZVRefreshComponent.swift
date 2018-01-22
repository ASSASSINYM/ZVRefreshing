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

    private struct OnceToken {
        static var tableView = "com.zevwings.once.table.excute"
        static var collectionView = "com.zevwings.once.collection.excute"
    }
    
    public private(set) var isRefreshing: Bool = false

    /// callback target object
    private var _target: Any?
    
    /// callback target selector
    private var _action: Selector?
    
    /// callback closure
    
    private var _refreshHandler: ZVRefreshHandler?
    
    public var beginRefreshingCompletionHandler: ZVBeginRefreshingCompletionHandler?
    public var endRefreshingCompletionHandler: ZVEndRefreshingCompletionHandler?

    /// superview
    internal var scrollView: UIScrollView?
    
    internal var scrollViewOriginalInset: UIEdgeInsets = UIEdgeInsets.zero
    
    /// ScrollView.UIPanGestureRecognizer
    private var _panGestureRecognizer: UIPanGestureRecognizer?
    
    /// 刷新状态
    private var _refreshState: State = .idle
    
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
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        prepare()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        prepare()
    }
    
    // MARK: Subviews
    
    /// Add SubViews
    open func prepare() {
        autoresizingMask = .flexibleWidth
        backgroundColor = .clear
    }
    
    /// Place SubViews
    open func placeSubViews() {}
    
    // MARK: Superview Observers
    /// Call this selector when UIScrollView.contentOffset value changed
    open func scrollView(_ scrollView: UIScrollView, contentOffsetDidChanged value: [NSKeyValueChangeKey: Any]?) {}
    
    /// Call this selector when UIScrollView.contentSize value changed
    open func scrollView(_ scrollView: UIScrollView, contentSizeDidChanged value: [NSKeyValueChangeKey: Any]?) {}
    
    /// Call this selector when UIScrollView.panGestureRecognizer.state value changed
    open func panGestureRecognizer(_ panGestureRecognizer: UIPanGestureRecognizer, stateValueChanged value: [NSKeyValueChangeKey: Any]?) {}
    
    
    // MARK: Getter & Setter
    open var refreshState: State {
        get {
            return _refreshState
        }
        set {
            set(refreshState: newValue)
        }
    }
    
    public var isAutomaticallyChangeAlpha: Bool = true {
        didSet {
            didSet(isAutomaticallyChangeAlpha: isAutomaticallyChangeAlpha)
        }
    }
    
    open var pullingPercent: CGFloat = 0.0 {
        didSet {
            didSet(pullingPercent: pullingPercent)
        }
    }
    
    public var refreshHandler: ZVRefreshHandler? {
        get {
            return _refreshHandler
        }
        set {
            _refreshHandler = newValue
        }
    }
}

// MARK: - Override

extension ZVRefreshComponent {
    
    open override var tintColor: UIColor! {
        get {
            return super.tintColor
        }
        set {
            super.tintColor = newValue
        }
    }
    
    open override func layoutSubviews() {
        placeSubViews()
        super.layoutSubviews()
    }
    
    open override func draw(_ rect: CGRect) {
        super.draw(rect)
        if refreshState == .willRefresh { refreshState = .refreshing }
    }
    
    open override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        
        guard let superview = newSuperview as? UIScrollView else { return }
        
        if superview.isKind(of: UITableView.self) {
            DispatchQueue.once(token: OnceToken.collectionView, block: {
                UITableView.once
            })
        } else if superview.isKind(of: UICollectionView.self) {
            DispatchQueue.once(token: OnceToken.collectionView, block: {
                UICollectionView.once
            })
        }
        
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

// MARK: - Update Refresh State

extension ZVRefreshComponent {
    
    // MARK: Begin Refresh
    public func beginRefreshing() {
        
        UIView.animate(withDuration: Config.AnimationDuration.fast, animations: {
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
    
    // MARK: End Refresh
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
    
    private func _addObservers() {
        
        let options: NSKeyValueObservingOptions = [.new, .old]
        
        scrollView?.addObserver(self,
                                     forKeyPath: Config.KeyPath.contentOffset,
                                     options: options, context: nil)
        scrollView?.addObserver(self,
                                     forKeyPath: Config.KeyPath.contentSize,
                                     options: options, context: nil)
        _panGestureRecognizer = scrollView?.panGestureRecognizer
        _panGestureRecognizer?.addObserver(self,
                                                forKeyPath: Config.KeyPath.panState,
                                                options: options, context: nil)
    }
    
    private func _removeObservers() {
        
        scrollView?.removeObserver(self, forKeyPath: Config.KeyPath.contentOffset)
        scrollView?.removeObserver(self, forKeyPath: Config.KeyPath.contentSize)
        scrollView?.removeObserver(self, forKeyPath: Config.KeyPath.panState)
        _panGestureRecognizer = nil
    }
    
    open override func observeValue(forKeyPath keyPath: String?,
                                    of object: Any?,
                                    change: [NSKeyValueChangeKey : Any]?,
                                    context: UnsafeMutableRawPointer?) {

        guard isUserInteractionEnabled else { return }

        guard let superScrollView = scrollView else { return }
        
        if keyPath == Config.KeyPath.contentSize {
            scrollView(superScrollView, contentSizeDidChanged: change)
        }

        guard isHidden == false else { return }

        if keyPath == Config.KeyPath.contentOffset {
            scrollView(superScrollView, contentOffsetDidChanged: change)
        } else if keyPath == Config.KeyPath.panState {
            panGestureRecognizer(superScrollView.panGestureRecognizer, stateValueChanged: change)
        }
    }
}

// MARK: - Public

public extension ZVRefreshComponent {
    
    /// check RefreshState.newValue is equal to RefreshState.oldState
    /// if the two value is not equal, update state label value.
    public func checkState(_ state: State) -> (result: Bool, oldState: State) {
        let oldState = refreshState
        if oldState == state { return (true, oldState) }
        return (false, oldState)
    }
    
    /// Add callback target and selector
    public func addTarget(_ target: Any?, action: Selector) {
        _target = target
        _action = action
    }
}

// MARK: - Internal

extension ZVRefreshComponent {
    
    internal func executeRefreshCallback() {
        DispatchQueue.main.async {
            
            self._refreshHandler?()
            
            if let target = self._target, let action = self._action {
                if (target as AnyObject).responds(to: action) {
                    DispatchQueue.main.async(execute: {
                        Thread.detachNewThreadSelector(action, toTarget: target, with: self)
                    })
                }
            }
            
            self.beginRefreshingCompletionHandler?()
        }
    }
}

// MARK: - Private

private extension ZVRefreshComponent {
    
    func set(refreshState newValue: State) {
        
        if checkState(newValue).result { return }
        
        willChangeValue(forKey: "isRefreshing")
        isRefreshing = newValue == .refreshing
        didChangeValue(forKey: "isRefreshing")
        sendActions(for: .valueChanged)
        
        _refreshState = newValue
    }
    
    func didSet(pullingPercent newValue: CGFloat) {
        guard isRefreshing == false else { return }
        if isAutomaticallyChangeAlpha {
            alpha = newValue
        }
    }
    
    func didSet(isAutomaticallyChangeAlpha newValue: Bool) {
        
        guard isRefreshing == false else { return }
        
        if isAutomaticallyChangeAlpha {
            alpha = pullingPercent
        } else {
            alpha = 1.0
        }
    }
}
