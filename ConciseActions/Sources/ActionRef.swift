//  
//  DemoApp
//  ActionRef
//
//  Created on 3/2/20
//  Copyright © 2020 productOps, Inc. All rights reserved. 
//
// Description: 
// 

import Foundation

import Concise
import ConciseRealm
import RealmSwift

@objcMembers public final class ActionRef: ActionPersistableStorageObject {
    
    /// Active actions are loaded by the ActionManager and executed
    dynamic public var isActive: Bool = false
    
    /// Once an action completes (either successfully or failing) isCompletes is set to true
    dynamic public var isCompleted: Bool = false
    
    /// If an action complets with an error, this value will be set
    dynamic public var errorMessage: String?
    
    /// number of exteernal references to this action.  The ActionManager will
    /// remove the action when refCount == 0 and isCompleted == 0
    dynamic public var refCount: Int = 0
    
    public let dependencies = List<DependencyRef>()
    
    static override public func indexedProperties() -> [String] {
        ["isActive", "isCompleted"]
    }

    private weak var _action: Action?
    public var action: Action {
        if let action = _action {
            return action
        }
        
        let action = ActionPersistableObject.for(storage: self) as! Action
        _action = action
        
        return action
    }
}

