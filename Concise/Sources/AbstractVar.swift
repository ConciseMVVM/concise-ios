//
//  AbstractVar.swift
//  Concise-iOS
//
//  Created by Ethan Nagel on 2/18/20.
//  Copyright © 2020 Product Ops. All rights reserved.
//

import Foundation

open class AbstractVar {
    private static var nextId: Int64 = 1

    public let domain: Domain
    internal(set) public var varId: Int64
    internal(set) public var needsUpdate: Bool = false
    internal(set) public var updatingValue: Bool = false
    private var subscriptions: [WeakSubscription] = []

    open func updateValue() -> Bool {
        return false
    }
    
    public func setNeedsUpdate() {
        guard !needsUpdate else {
            return
        }
        
        domain.addPendingVar(self)
    }
    
    public init(_ domain: Domain) {
        self.domain = domain
        self.varId = OSAtomicIncrement64(&Self.nextId)
    }
    
    internal func notifyChanged() {
        var index = 0
        
        while index < subscriptions.count {
            let item = subscriptions[index]
            
            if item.impl == nil {
                subscriptions.remove(at: index)
                continue
            }

            item.notify() // only has an effect if not disposed
            
            index += 1
        }
    }
    
    
    /// subscribes to change notifications for th underlying value
    /// - Parameter block: block to execute on each change.
    /// - Returns: a subscription that must be referenced for the subscription to remain active.
    /// release the value or call dispose() to cancel notifications.
    public func subscribe(_ block: @escaping () -> Void) -> Subscription {
        let sub = SubscriptionImpl(target: self, block: block)
        subscriptions.append(WeakSubscription(sub))
        
        return sub
        
    }
}

extension AbstractVar {
    /// executes block the next time the underlying value is changed.
    /// - Parameter block: block to execute
    func subscribeOnce(_ block: @escaping () -> Void) {
        var sub: Subscription? = nil
         
         sub = self.subscribe {
             if sub != nil {
                 block()
                 sub = nil
             }
         }
    }
}



