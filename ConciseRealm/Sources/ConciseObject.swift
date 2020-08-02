//
//  ConciseObject.swift
//  SimpleMethod
//
//  Created by Ethan Nagel on 2/12/20.
//  Copyright © 2020 Product Ops. All rights reserved.
//

import Foundation
import RealmSwift
import Realm
import Concise

open class ConciseObject: Object {
    private var _token: NotificationToken?
    
    public lazy var conciseVar: ExternalVar = {
        guard Thread.isMainThread else {
            fatalError("conciseVar may only be used from the main thread.")
        }
        
        let v = ExternalVar(Domain.current)

        _token = self.observe { (change) in
            guard !self.isInvalidated else {
                return // don't trigger an update, this object is now invalid!
            }
//            print("\(type(of: self)) changed")
            v.setNeedsUpdate() // a change of some kind has happened
        }
        
        return v
    }()
    
    override open class func ignoredProperties() -> [String] {
        return ["conciseVar", "_token"]
    }
    
    public func willReadProperty(_ property: String) {
        if !Thread.isMainThread {
            return // we only support the main thread for now.
        }
        
//        print("\(type(of: self)).willReadProperty(\(property))")
        guard DependencyGroup.current != nil else {
            return // if we aren't capturing dependencies, there is no need to continue.
        }

        // let the system know we read something. This will also create our var and start observing (and publishing)
        // changes if needed.
        
        conciseVar.domain.willRead(conciseVar)
    }
    
    public required init() {
        super.init()
        
        // So this is a bit tricky. Under the hood Realm subclasses each of our classes asn reutnrs those instances to us.
        // We need to intercept the prperty getters in these classes in order to do our notifications. This code
        // swizzles each of these classes the first time they're encountered...
        
        let className = object_getClassName(self) // this is the name of the real underlying class.
        
        if strncmp(className, "RLM:", 4) == 0 {// this is a Realm managed or unmanaged class instance (generated)
            let actualClass = objc_getClass(className)!  // we can't use type(of: self), because the instance will lie to us, we need the actual real class.

            if objc_getAssociatedObject(actualClass, className) == nil { // that we haven't yet swizzled...
                objc_setAssociatedObject(actualClass, className, true, .OBJC_ASSOCIATION_ASSIGN) // set a flag so we won't swizzle it again.
                ConciseObject.swizzleClass(actualClass as! ConciseObject.Type)
            }
        }
    }
}

// the obvious thing to do here would be to add this method directly to the ConciseObject class but
// due to the weirdness of how swifts deals with Self it needs to be in a protocol extension...

public protocol ConciseObjectQueryObjects {
}

extension ConciseObjectQueryObjects where Self: ConciseObject {
    
    /// performs the query q on all objects of the given type on the default realm, returning the results as a ConciseArray
    /// - Parameter q: the query to run. the parameter, objects, is all the objects realm has. the results will be wrapped in the concise array
    /// - Returns: a ConciseArray subscribed to the query
    public static func query(_ q: (_ objects: Results<Self>) -> Results<Self>) -> ConciseArray<Self> {
        return try! withRealm { (realm) -> Results<Self> in
            return q(realm.objects(Self.self))
        }.asConciseArray()
    }
}

extension ConciseObject: ConciseObjectQueryObjects {
}
