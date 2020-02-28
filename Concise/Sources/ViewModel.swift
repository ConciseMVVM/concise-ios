//
//  ViewModel.swift
//  Concise
//
//  Created by Ethan Nagel on 2/28/20.
//  Copyright © 2020 Product Ops. All rights reserved.
//

import Foundation
import Combine

// Most of this is related to SwiftUI support for view models...

/// Subscribes to all Vars in a class (including those wrapped in propertywrappers) and forwards any change to ObservableObject Publishers.
/// This is accomplished by inspecting the properties for the target class when it is constructed.
fileprivate class ViewModelPublisher {
    private(set) var publisher: ObservableObjectPublisher
    private var subscriptions: [Concise.Subscription]
    
    static func enumerateVars(mirror: Mirror, block: @escaping (_ v: AbstractVar) -> Void) {
        for prop in mirror.children {
            var value = prop.value
            
            if let wrapper = value as? AbstractVarPropertyWrapper, let v = wrapper.abstractVar {
                value = v
            }

            if let v = value as? AbstractVar {
                block(v)
            }
        }
        
        if let superclassMirror = mirror.superclassMirror {
            enumerateVars(mirror: superclassMirror, block: block)
        }
    }
    
    init(_ vm: AnyObject) {
        let publisher = ObservableObjectPublisher()
        var subscriptions: [Concise.Subscription] = []
        
        // find all Concise variables and subscribe to them, forwarding to the publisher
        
        ViewModelPublisher.enumerateVars(mirror: Mirror(reflecting: vm)) {
            subscriptions.append($0.subscribe({ publisher.send() }))
        }
        
        self.publisher = publisher
        self.subscriptions = subscriptions
    }
}

open class ViewModel: ObservableObject {
    private var pub: ViewModelPublisher? = nil
    
    public var objectWillChange: ObservableObjectPublisher {
        if pub == nil {
            pub = ViewModelPublisher(self)
        }
        
        return pub!.publisher
    }
}

open class ViewModelItem<Model>: ObservableObject {
    private var pub: ViewModelPublisher? = nil
    
    public var objectWillChange: ObservableObjectPublisher {
        if pub == nil {
            pub = ViewModelPublisher(self)
        }
        
        return pub!.publisher
    }
    
    public required init(_ model: Model) {
    }
}

