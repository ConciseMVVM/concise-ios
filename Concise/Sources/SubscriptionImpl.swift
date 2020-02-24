//
//  SubscriptionImpl.swift
//  Concise-iOS
//
//  Created by Ethan Nagel on 2/18/20.
//  Copyright © 2020 Product Ops. All rights reserved.
//

import Foundation

internal class SubscriptionImpl: Subscription {
    private(set) var target: AbstractVar?
    private(set) var block: () -> Void
    
    init(target: AbstractVar, block: @escaping () -> Void) {
        self.target = target
        self.block = block
    }
    
    var isDisposed: Bool {
        return target == nil
    }
    
    func notify() {
        guard !isDisposed else {
            return
        }
            
        block()
    }
        
    func dispose() {
        guard target != nil else {
            return
        }
                
        target = nil
    }
    
    deinit {
        if !isDisposed {
            dispose()
        }
    }
}

internal struct WeakSubscription {
    weak var impl: SubscriptionImpl?
    
    var isDisposed: Bool {
        return impl?.isDisposed ?? true
    }
    
    func dispose() {
        impl?.dispose()
    }
    
    func notify() {
        impl?.notify()
    }
    
    init(_ impl: SubscriptionImpl) {
        self.impl = impl
    }
}

