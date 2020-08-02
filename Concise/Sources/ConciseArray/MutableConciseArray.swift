//
//  MutableConciseArray.swift
//  Concise
//
//  Created by Ethan Nagel on 2/27/20.
//  Copyright © 2020 Product Ops. All rights reserved.
//

import Foundation

public class MutableConciseArray<Element>: ConciseArray<Element> {
    private var _isEqual: (Element, Element) -> Bool
    
    private var _futureItems: [Element]?
    public var futureItems: [Element] {
        get { _futureItems ?? items }
        set {
            _futureItems = newValue
            setNeedsUpdate()
        }
    }
    
    public init(_ items: [Element], isEqual: @escaping (Element, Element) -> Bool) {
        self._isEqual = isEqual
        super.init(domain: Domain.current, items: items)
    }
    
    public override func updateValue() -> Bool {
        guard let futureItems = _futureItems else {
            return false
        }
        
        _futureItems = nil
        
        let changes = futureItems.difference(from: self.oldItems, by: _isEqual).asConciseArrayChange()
        
        if changes.count == 0 {
            return false
        }

        setItems(futureItems, changes: changes)
                
        return true
    }
}

extension MutableConciseArray where Element: Identifiable {
    public convenience init(_ items: [Element]) {
        self.init(items, isEqual: { $0.id == $1.id })
    }
}

extension MutableConciseArray where Element: Equatable {
    public convenience init(_ items: [Element]) {
        self.init(items, isEqual: { $0 == $1 })
    }
}

