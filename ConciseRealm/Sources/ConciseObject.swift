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
        
        guard DependencyGroup.current != nil else {
            return // if we aren't capturing dependencies, there is no need to continue.
        }

        // let the system know we read something. This will also create our var and start observing (and publishing)
        // changes if needed.
        
        conciseVar.domain.willRead(conciseVar)
    }
}

