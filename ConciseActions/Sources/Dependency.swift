//  
//  DemoApp
//  Dependency
//
//  Created on 3/5/20
//  Copyright © 2020 productOps, Inc. All rights reserved. 
//
// Description: 
// 

import Foundation

import Concise
import RealmSwift

open class Dependency: ActionPersistableObject, CustomStringConvertible {
    public var ref: DependencyRef { return self.storage as! DependencyRef }
    
    /// create a new Dependency/DependencyRef pair
    convenience public init() {
        self.init(DependencyRef())
    }
    
    /// returns an existing dependency, linked to this dependencyRef
    required public init(_ storage: ActionPersistableStorageObject) {
        assert(storage is DependencyRef)
        super.init(storage)
    }
    
    /// should return true when this dependency is satisfied. Should be a Concise Observable value
    open var isSatisified: Bool { true }
    
    /// return false if a permanent error has ocurred and the dependency  can never be safisfied
    open var isSatisifiable: Bool { true }
    
    open var description: String {
        let className = "\(type(of: self))"
        let boringSuffix = "Dependency"
        
        if className.hasSuffix(boringSuffix) {
            return String(className.dropLast(boringSuffix.count))
        } else {
            return className
        }
    }
    
    open func onDelete(from realm: Realm) {
    }
}

