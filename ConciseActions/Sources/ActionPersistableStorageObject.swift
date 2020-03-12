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

import ConciseRealm
import Concise
import RealmSwift

/// Common base class for ActionRef and DestinationRef objects
@objcMembers public class ActionPersistableStorageObject: ConciseObject, PersistableStorage {
    public dynamic var id: String = ""
    public dynamic var className: String = ""
    public dynamic var properties: String = "{}"
    
    private var _persistentValues: [String:String]?
    private(set) public var needsSave: Bool = false
    private let _externalVar = ExternalVar(Domain.current)
        
    override public class func primaryKey() -> String? {
        "id"
    }
    
    override public class func ignoredProperties() -> [String] {
        super.ignoredProperties() + ["needsSave", "_persistentValues", "_externalVar"]
    }
    
    public func associatePersistableObject(_ object: ActionPersistableObject) {
        guard self.realm == nil else {
            fatalError("can only call associatePersistableObject on new instances")
        }
        
        self.id =  UUID().uuidString
        self.className = String(describing: type(of: object))
        
        self.setNeedsSave() // we will persist this to the database in the background
    }
    
    func setNeedsSave() {
        guard !needsSave else {
            return
        }
        
        needsSave = true
        ActionManager.shared.saveAsync(self)
    }
    
    // saves any pending values to the realm object...
    
    public func save(to realm: Realm) {
        if self.isInvalidated {
            return // if the storage object has been deleted, we don't need to do anything
        }
        
        if let persistentValues = self._persistentValues { // really shouldn't be nil when we get here...
            let encoder = JSONEncoder()
            let data = try! encoder.encode(persistentValues)
            let string = String(bytes: data, encoding: .utf8)!

            self.properties = string
        }
        
        // save ourselves if new
        
        if self.realm == nil {
            realm.add(self)
        }
    }
    
    private func load() {
        let data = self.properties.data(using: .utf8)!
        let decoder = JSONDecoder()
        _persistentValues = try! decoder.decode([String:String].self, from: data)
    }
    
    private func ensureLoaded() {
        if _persistentValues == nil {
            load()
        }
    }
    
    public func setPersistentValue(_ key: String, _ value: String) {
        setNeedsSave()
        ensureLoaded()
        _persistentValues?[key] = value
        _externalVar.setNeedsUpdate()
    }
    
    public func getPersistentValue(_ key: String) -> String? {
        ensureLoaded()
        _externalVar.domain.willRead(_externalVar)
        return _persistentValues?[key]
    }
}


