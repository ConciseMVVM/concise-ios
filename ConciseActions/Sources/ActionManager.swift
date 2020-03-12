//  
//  DemoApp
//  ActionManager
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

public class ActionManager {
    public static let shared = ActionManager()
    
    private init() {
        
        // register our built-in dependencies
        
        ConnectedDependency.registerType()
        ActionDependency.registerType()
    }
    
    //MARK: Action Processor
    
    @ArrayProp private(set) public var actionRefs: [ActionRef]
    private var _actions: [String:Action] = [:]
    
    private var _subscription: Subscription? = nil
    
    public func start() {
        
        // cleanup any actions that are laying around and should be deleted.
        // normally these would be deleted when they become inactive,
        // this is just an added step.
        
        DispatchQueue.main.async {
            try! withRealm { (realm) in
                let actionRefs = realm.objects(ActionRef.self).filter("isCompleted == TRUE && refCount == 0")
                
                for actionRef in actionRefs {
                    actionRef.action.delete()
                }
            }
        }
        
        // geour active actions...
        
        _actionRefs *= try! withRealm {
            $0.objects(ActionRef.self)
            .filter("(isActive == TRUE && isCompleted == FALSE) || refCount > 0")
            .asConciseArray()
        }
        
        // any time there is a change we go ahead and sync our map of actions with the refs...

        _subscription = $actionRefs.subscribe { [weak self] in
            self?.actionsRefsChanged()
        }
    }
    
    private func actionsRefsChanged() {
        // Process adds first...
        
        for actionRef in self.actionRefs {
            if self._actions[actionRef.id] == nil {
                // add a new action...
                let action = actionRef.action
                self._actions[actionRef.id] = action
                self.actionAdded(action)
            }
        }
        
        // Now process removes...
        
        let newIds = Set(self.actionRefs.map { $0.id })
        
        for (id, action) in self._actions {
            if !newIds.contains(id) {
                self._actions.removeValue(forKey: id)
                self.actionRemoved(action)
            }
        }
    }
    
    private func actionAdded(_ action: Action) {
        // this will start start the action is appropriate...
        // (if it's completed nothing will happen.)
        action.run()
    }
    
    private func actionRemoved(_ action: Action) {
        // the action is completed and there are no references to it, it can be deleted...
        action.delete()
    }
    
    //MARK: Storage management
    
    private(set) public var needsSave: Bool = false
    private var _pendingStorageObjects: [ActionPersistableStorageObject] = [] // objects that need to be saved
    private var _pendingWriteBlocks: [(Realm) -> Void] = []
    
    private func save() {
        // this is currently done on the main thread. We will need to be a littls more nuanced if we want to
        // do the changes on a background thread...
        
        guard needsSave else {
            return
        }
    
        try! writeRealm { realm in
            // First, handle our write blocks. They may cause more storage blocks to be scheduled...
            
            while !_pendingWriteBlocks.isEmpty {
                let pendingWriteBlocks = _pendingWriteBlocks
                _pendingWriteBlocks = []

                for writeBlock in pendingWriteBlocks {
                    writeBlock(realm)
                }
            }
            
            // now, persist modified storage objects...
            
            let pendingStorageObjects = _pendingStorageObjects
            _pendingStorageObjects = []
            
            for storageObject in pendingStorageObjects {
                storageObject.save(to: realm)
            }
            
            needsSave = false
        }
    }
    
    private func setNeedsSave() {
        if !needsSave {
            needsSave = true
            
            // batch changes until next run loop...
            
            DispatchQueue.main.async {
                self.save()
            }
        }
    }
    
    public func saveAsync(_ storageObject: ActionPersistableStorageObject) {
        _pendingStorageObjects.append(storageObject)
        setNeedsSave()
    }
    
    public func writeAsync(_ block: @escaping (Realm) -> Void) {
        _pendingWriteBlocks.append(block)
        setNeedsSave()
    }
    
    public func action(for actionId: String) -> Action? {
        if let action = _actions[actionId] {
            return action
        }
         
        return try? withRealm { (realm) in
            realm.object(ofType: ActionRef.self, forPrimaryKey: actionId)?.action
        }
    }
}
