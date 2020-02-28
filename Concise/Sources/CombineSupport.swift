//
//  CombineSupport.swift
//  Concise
//
//  Created by Ethan Nagel on 2/28/20.
//  Copyright © 2020 Product Ops. All rights reserved.
//

import Foundation

import Combine

// Combine bindings for Concise

extension Var: Publisher {
    public typealias Output = VarType
    public typealias Failure = Never
    
    public func receive<S>(subscriber: S) where S : Subscriber, Var.Failure == S.Failure, Var.Output == S.Input {
        let subscription = VarSubscription(subscriber: subscriber, theVar: self)
        subscriber.receive(subscription: subscription)
    }
    
    private class VarSubscription<SubscriberType: Subscriber, VarType: Equatable>: Combine.Subscription where SubscriberType.Input == VarType {
        private var subscriber: SubscriberType?
        private var conciseSub: Concise.Subscription?

        init(subscriber: SubscriberType, theVar: Var<VarType>) {
            self.subscriber = subscriber
            self.conciseSub = theVar.subscribe { [weak self] in
                _ = self?.subscriber?.receive(theVar.value)
            }
            
            // send the current value on connect...
            
            _ = subscriber.receive(theVar.value)
        }

        func request(_ demand: Subscribers.Demand) {
            // We do nothing here as we only want to send events when they occur.
            // See, for more info: https://developer.apple.com/documentation/combine/subscribers/demand
        }

        func cancel() {
            subscriber = nil
            conciseSub = nil
        }
    }
}

