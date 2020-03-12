//  
//  DemoApp
//  TypeMap
//
//  Created on 3/4/20
//  Copyright © 2020 productOps, Inc. All rights reserved. 
//
// Description: 
// 

import Foundation

public protocol TypeMappable: AnyObject {
}

extension TypeMappable {
    public static func registerType() {
        TypeMap.register(self)
    }
}

public class TypeMap {
    static private var typeMap: [String:TypeMappable.Type] = [:]
    
    static public func register(_ type: TypeMappable.Type) {
        let name = String(describing: type)
        typeMap[name] = type
    }
    
    static public func type(for name: String) -> TypeMappable.Type? {
        return typeMap[name]
    }
}
