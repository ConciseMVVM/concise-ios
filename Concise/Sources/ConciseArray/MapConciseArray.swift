//
//  MapConciseArray.swift
//  Concise
//
//  Created by Ethan Nagel on 2/27/20.
//  Copyright © 2020 Product Ops. All rights reserved.
//

import Foundation

private class MapConciseArray<SourceElement, Element>: ConciseArray<Element> {
    private let mapBlock:(_ item: SourceElement) -> Element
    private var subscription: Subscription?
    
    private var _futureSourceItems: [SourceElement]?
    private var _futureChanges: [ConciseArrayChange]?
    
    public init(_ source: ConciseArray<SourceElement>, mapBlock: @escaping (_ item: SourceElement) -> Element) {
        self.mapBlock = mapBlock
        let initialItems = source.items.map { mapBlock($0) }
        super.init(domain: source.domain, items: initialItems)
        
        self.subscription = source.subscribe { [weak self] in
            self?._futureSourceItems = source.items
            self?._futureChanges = source.changes
            self?.setNeedsUpdate()
        }
    }
    
    public override func updateValue() -> Bool {
        guard let sourceItems = _futureSourceItems,
            let changes = _futureChanges else {
            return false // a little strange
        }
    
        _futureSourceItems = nil
        _futureChanges = nil
        
        if changes.isEmpty {
            return false // nothing actually changed
        }
        
        var newItems = self.items
        
        // first, handle deletions in descending order...
        
        for index in changes.removals.sorted().reversed() {
            newItems.remove(at: index)
        }
        
        // now, do insertions in ascending order...
        
        for index in changes.insertions.sorted() {
            newItems.insert(self.mapBlock(sourceItems[index]), at: index)
        }
        
        // set our new items. We also propagate changes here so we don't have to calculate them
        // this means the our elements don't need to conform to Equatable
        
        setItems(newItems, changes: changes)

        return true
    }
}

extension ConciseArray {
    public func map<TargetElement>(_ mapBlock: @escaping (Element) -> TargetElement) -> ConciseArray<TargetElement> {
        return MapConciseArray(self, mapBlock: mapBlock)
    }
}
