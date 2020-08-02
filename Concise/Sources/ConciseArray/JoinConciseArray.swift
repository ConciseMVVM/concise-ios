//
//  JoinConciseArray.swift
//  Concise
//
//  Created by Ethan Nagel on 8/1/20.
//  Copyright © 2020 Product Ops. All rights reserved.
//

// TODO: It should be possible to aggregate the change sets from each child array
// and avoid calculating the changes ourselves here.
// This is really simplistic for now. Whenever their are changes we build the new
// destination array and calculate the changes.

import Foundation

private class JoinConciseArray<Element>: ConciseArray<Element>, Subscription {
    private var _isEqual: (Element, Element) -> Bool

    private var array: ConciseArray<ConciseArray<Element>>
    private var subscription: Subscription?
    private var innerSubscriptions: ConciseArray<Subscription>?
        
    public init(_ array: ConciseArray<ConciseArray<Element>>, isEqual: @escaping (Element, Element) -> Bool) {
        self._isEqual = isEqual
        self.array = array
        
        super.init(domain: Domain.current, items: array.flatMap({ $0 }))
        
        self.subscription = array.subscribe { [weak self] in
            self?.setNeedsUpdate()
        }
        
        self.innerSubscriptions = array.map { (innerArray) in
            return innerArray.subscribe { [weak self] in
                self?.setNeedsUpdate()
            }
        }
    }
    
    func dispose() {
        self.subscription = nil
        self.innerSubscriptions = nil
    }
    
    public override func updateValue() -> Bool {
        let items = self.array.flatMap({ $0 })
        let changes = items.difference(from: self.items, by: _isEqual).asConciseArrayChange()
        
        if changes.count == 0 {
            return false
        }

        setItems(items, changes: changes)
                
        return true
    }
}

extension ConciseArray where Element: Identifiable {
    public static func join(conciseArray array: ConciseArray<ConciseArray<Element>>) -> ConciseArray<Element> {
        return JoinConciseArray(array, isEqual: { $0.id == $1.id })
    }
    
    public static func join(_ arrays: [ConciseArray<Element>]) -> ConciseArray<Element> {
        let array = ConciseArray<ConciseArray<Element>>(domain: Domain.current, items: arrays)
        
        return Self.join(conciseArray: array)
    }

    public static func join(_ array: ConciseArray<Element>...) -> ConciseArray<Element> {
        return Self.join(array)
    }

    func appending(_ array: ConciseArray<Element>...) -> ConciseArray<Element> {
        Self.join([[self], array].flatMap({ $0 }))
    }
}

extension ConciseArray where Element: Equatable {
    public static func join(conciseArray array: ConciseArray<ConciseArray<Element>>) -> ConciseArray<Element> {
        return JoinConciseArray(array, isEqual: { $0 == $1 })
    }
    
    public static func join(_ array: ConciseArray<ConciseArray<Element>>) -> ConciseArray<Element> {
        return JoinConciseArray(array, isEqual: { $0 == $1 })
    }
    
    public static func join(_ arrays: [ConciseArray<Element>]) -> ConciseArray<Element> {
        let array = ConciseArray<ConciseArray<Element>>(domain: Domain.current, items: arrays)
        
        return Self.join(conciseArray: array)
    }

    public static func join(_ array: ConciseArray<Element>...) -> ConciseArray<Element> {
        return Self.join(array)
    }

    public func appending(_ array: ConciseArray<Element>...) -> ConciseArray<Element> {
        Self.join([[self], array].flatMap({ $0 }))
    }
}


//extension Sequence {
//    @available(swift, deprecated: 4.1, renamed: "compactMap(_:)", message: "Please use compactMap(_:) for the case where closure returns an optional value")
//    public func flatMap<ElementOfResult>(_ transform: (Self.Element) throws -> ElementOfResult?) rethrows -> [ElementOfResult]
//}

extension ConciseArray {
    // I really think this should work, but what's the right syntax?
//    func flatten<InnerElement>() -> ConciseArray<InnerElement> where Element: ConciseArray<InnerElement>, InnerElement: Identifiable {
//        return JoinConciseArray(self, isEqual: { $0.id == $1.id })
//    }
//    
//    func flatten<InnerElement>() -> ConciseArray<InnerElement> where Element: ConciseArray<InnerElement>, InnerElement: Equatable {
//        return JoinConciseArray(self, isEqual: { $0 == $1 })
//    }
}
