//  
//  DemoApp
//  ActionDependency
//
//  Created on 3/8/20
//  Copyright © 2020 productOps, Inc. All rights reserved. 
//
// Description: 
// 

import Foundation
import RealmSwift

public class ActionDependency: Dependency {
    @Persistent public private(set) var actionId: String = ""
    
    private var _action: Action?
    public var action: Action {
        if _action == nil {
            _action = ActionManager.shared.action(for: actionId)
        }
        
        return _action!
    }
    
    public convenience init(_ action: Action) {
        self.init(DependencyRef())
        _action = action
        self.actionId = action.id
        action.writeAsync {
            action.refCount += 1
        }
    }
    
    public required init(_ storage: ActionPersistableStorageObject) {
        super.init(storage)
    }

    override public var isSatisifiable: Bool { !action.didFail }
    override public var isSatisified: Bool { action.didSucceed }
    
    override public var description: String { action.description }
    
    override public func onDelete(from realm: Realm) {
        if let actionRef = realm.object(ofType: ActionRef.self, forPrimaryKey: actionId) {
            actionRef.refCount -= 1
        }
    }
}

extension Dependency {
    public func action(_ action: Action) -> ActionDependency { ActionDependency(action) }
}
