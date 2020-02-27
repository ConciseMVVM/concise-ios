//
//  ConciseResults.swift
//  ConciseRealm
//
//  Created by Ethan Nagel on 2/27/20.
//  Copyright © 2020 Product Ops. All rights reserved.
//

import Foundation

import Realm
import RealmSwift

import Concise

extension RealmCollectionChange where CollectionType: Collection  {
    func asConciseArrayChanges() -> [ConciseArrayChange] {
        switch self {
        case .initial(let items):
            return Array(0..<items.count).map { ConciseArrayChange.insert(offset: $0) }
            
        case .update(_, let deletions, let insertions, _):
            return insertions.map { ConciseArrayChange.insert(offset: $0) }
                + deletions.map { ConciseArrayChange.remove(offset: $0) }
        default:
            return []
        }
    }
}

extension Results {
    private class ObservableResultsArray<Element: RealmCollectionValue>: ConciseArray<Element> {
        private var notificationToken: NotificationToken?
        
        private var _futureItems: [Element]?
        private var _futureChanges: [ConciseArrayChange]?
        
        init(_ results: Results<Element>) {
            super.init(domain: Domain.current, items: [])
            notificationToken = results.observe { [weak self] (change) in
                self?._futureItems = Array(results)
                self?._futureChanges = change.asConciseArrayChanges()
                self?.setNeedsUpdate()
            }
        }
        
        override func updateValue() -> Bool {
            guard let futureItems = _futureItems,
                let futureChanges = _futureChanges else {
                return false
            }
            
            _futureItems = nil
            _futureChanges = nil
            
            if futureChanges.isEmpty {
                return false
            }
            
            setItems(futureItems, changes: futureChanges)
                    
            return true
        }
    }
    
    public func asConciseArray() -> ConciseArray<Element> {
        return ObservableResultsArray(self)
    }
}
