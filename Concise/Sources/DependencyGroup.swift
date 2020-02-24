//
//  DependencyGroup.swift
//  Concise-iOS
//
//  Created by Ethan Nagel on 2/18/20.
//  Copyright © 2020 Product Ops. All rights reserved.
//

import Foundation

public class DependencyGroup {
    // todo: make threadsafe
    
    private(set) public static var current: DependencyGroup? = nil
    
    private(set) public var dependencies: [AbstractVar] = []
    
    public func addDependency(_ value: AbstractVar) {
        dependencies.append(value)
    }
    
    public func capture<T>(_ block: () -> T) -> T {
        let old = DependencyGroup.current
        DependencyGroup.current = self
        let result = block()
        DependencyGroup.current = old
        
        return result
    }
    
    public init() {
    }
}
