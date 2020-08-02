//
//  ViewModel.swift
//  Concise
//
//  Created by Ethan Nagel on 2/28/20.
//  Copyright © 2020 Product Ops. All rights reserved.
//

import Foundation
import Combine

/// a View that supports data binding with the bind(to:) call, such as a UITableViewCell
public protocol ConciseBindableView {
    associatedtype Element
    
    func bind(to element: Element)
}

/// a ViewModelItem that has an associated ConciseBindableView, such as a view model item for a UITableViewCell
public protocol ConciseBindableViewModelItem {
    /// The View type (or base type) associated with this VIew Model Item
    associatedtype View: ConciseBindableView where View.Element == Self
    
    /// returns the view type to be used for a specific element. By default this will return the associated type's type.
    ///
    ///  override this when you need to associate multiple bindable views with a single list of ViewModelItems.
    ///
    /// - Parameter element: the element to return the
    ///
    static func bindableViewTypeFor(_ element: Self) -> View.Type
}

extension ConciseBindableViewModelItem {
    public static func bindableViewTypeFor(_ element: Self) -> View.Type {
        return View.self
    }
}

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
    
    public init() {
    }
}

open class ViewModelItem: ObservableObject {
    private var pub: ViewModelPublisher? = nil
    
    public var objectWillChange: ObservableObjectPublisher {
        if pub == nil {
            pub = ViewModelPublisher(self)
        }
        
        return pub!.publisher
    }
    
    public init() {
    }
}

