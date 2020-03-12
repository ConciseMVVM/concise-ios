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
import ConciseRealm

@objcMembers public final class DependencyRef: ActionPersistableStorageObject {
    private weak var _dependency: Dependency?
    public var dependency: Dependency {
        if let dependency = _dependency {
            return dependency
        }
        
        let dependency = ActionPersistableObject.for(storage: self) as! Dependency
        _dependency = dependency
        
        return dependency
    }
}

