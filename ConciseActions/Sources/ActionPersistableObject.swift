//  
//  DemoApp
//  ActionObject
//
//  Created on 3/6/20
//  Copyright © 2020 productOps, Inc. All rights reserved. 
//
// Description: 
// 

import Foundation

/// Common base class for Action and Dependency objects
open class ActionPersistableObject: Persistable {
    private(set) public var storage: ActionPersistableStorageObject!
    public var id: String { storage.id }
    
    static func `for`(storage: ActionPersistableStorageObject) -> ActionPersistableObject {
        guard let type = TypeMap.type(for: storage.className) as? ActionPersistableObject.Type else {
            fatalError("Unable to create instance '\(storage.className)', has it been registered with TypeMap?")
        }
        
        return type.init(storage)
    }
    
    /// Creates a Persistable object, bound to the underlying storage object.
    required public init(_ storage: ActionPersistableStorageObject) {
        self.storage = storage
        if storage.id.isEmpty { // if this is a newly created storage object, associate our instances.
            storage.associatePersistableObject(self)
        }
        bindPersistentProperties(to: storage)
    }
}

extension ActionPersistableObject: TypeMappable { }
