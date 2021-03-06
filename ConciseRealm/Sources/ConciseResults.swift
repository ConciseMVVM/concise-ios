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

extension Results {
    private class ObservableResultsArray<Element: RealmCollectionValue>: ConciseArray<Element> {
        private var notificationToken: NotificationToken?
        
        private var _futureItems: [Element]?
        private var _futureChanges: [ConciseArrayChange]?
        
        init(_ results: Results<Element>, preload: Bool) {
            super.init(domain: Domain.current, items: (preload) ? Array(results) : [])
            notificationToken = results.observe { [weak self] (change) in
                self?._futureItems = Array(results)
                self?._futureChanges = {
                    switch(change) {
                    case .initial(let items):
                        // if we preloaded the "initial" call is redundant...
                        return (preload) ? [] : Array(0..<items.count).map { ConciseArrayChange.insert(offset: $0) }
                    case .update(_, let deletions, let insertions, _):
                        return insertions.map { ConciseArrayChange.insert(offset: $0) }
                            + deletions.map { ConciseArrayChange.remove(offset: $0) }
                    default:
                        return []
                    }
                }()
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
    
    private class ObservableResultsCount<Element: RealmCollectionValue>: Var<Int> {
        private var notificationToken: NotificationToken?
        
        private var _futureValue: Int = 0
        
        init(_ results: Results<Element>, preload: Bool) {
            super.init(Domain.current, (preload) ? results.count : 0)
            _futureValue = value
            
            notificationToken = results.observe { [weak self] (_) in
                guard let self = self else { return }
                
                self._futureValue = results.count
                if self._futureValue != self.value {
                    self.setNeedsUpdate()
                }
            }
        }
        
        override func updateValue() -> Bool {
            if _futureValue == value {
                return false
            }
            
            setValue(_futureValue)
            return true
        }
    }

    /// returns results as an observable concise array
    /// - Parameter preload: if true, the concise array  synchronously gets the inital value of the query. Otherwise the initial array will be empty and results will be queried on a background thread. (default: false)
    public func asConciseArray(preload: Bool = false) -> ConciseArray<Element> {
        guard DependencyGroup.current == nil else {
            fatalError("Perfoming Realm queries in an expression is not supported")
        }
        
        return ObservableResultsArray(self, preload: preload)
    }
    
    /// returns count of results as an observable concise array
    /// - Parameter preload: if true, the concise array  synchronously gets the inital value of the query. Otherwise the initial count will be 0 and results will be queried on a background thread. (default: false)
    public func asConciseCount(preload: Bool = false) -> Var<Int> {
        guard DependencyGroup.current == nil else {
            fatalError("Perfoming Realm queries in an expression is not supported")
        }
        
        return ObservableResultsCount(self, preload: preload)
    }
}
