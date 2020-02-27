//
//  ConciseArray.swift
//  Concise
//
//  Created by Ethan Nagel on 2/27/20.
//  Copyright © 2020 Product Ops. All rights reserved.
//

import Foundation

public class ConciseArray<Element>: AbstractVar {
    private(set) var items: [Element]

    private var _oldItems: [Element]?
    private var _changes: [ConciseArrayChange]?
    
    public var oldItems: [Element] { _oldItems ?? items }
    public var changes: [ConciseArrayChange] { _changes ?? [] }
    
    public init(domain: Domain, items: [Element]) {
        self.items = items
        
        super.init(domain)
    }
    
    public func setItems(_ newItems: [Element], changes: [ConciseArrayChange]?) {
        guard self.updatingValue else {
            fatalError("ConciseArray.setValues may only be called inside updateValue()")
        }
        
        self._oldItems = self.items
        self.items = newItems
        self._changes = changes // if nil, will be calculated the first time they are requested.
        
        // Once we are done with this update, we clear _oldItems and _changes...
        // These values are only available while subscriptions are firing...
        
        domain.afterUpdate { [weak self] in
            self?._oldItems = nil
            self?._changes = nil
        }
    }
}

extension ConciseArray: RandomAccessCollection {
    public typealias Index = Int

    public subscript(position: Int) -> Element { items[position] }
    
    public var startIndex: Int { items.startIndex }
    
    public var endIndex: Int { items.endIndex }
}

