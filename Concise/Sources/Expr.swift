//
//  Expr.swift
//  Concise-iOS
//
//  Created by Ethan Nagel on 2/18/20.
//  Copyright © 2020 Product Ops. All rights reserved.
//

import Foundation

public class Expr<VarType: Equatable>: Var<VarType> {
    class Dependency {
        unowned let observable: AbstractVar
        let subscription: Subscription
        
        init(expr: AbstractVar, observable: AbstractVar) {
            self.observable = observable
            self.subscription = observable.subscribe {
                expr.setNeedsUpdate()
            }
        }
        
        deinit {
            subscription.dispose()
        }
        
        static func asDictionary(_ dependencies: [Dependency]) -> [Int64: Dependency] {
            var dict: [Int64: Dependency] = [:]
            
            for dep in dependencies {
                dict[dep.observable.id] = dep
            }
            
            return dict
        }
    }
    
    private let expr: () -> VarType
    private var dependencies: [Int64: Dependency] = [:]
    
    private func updateDependencies(_ vars: [AbstractVar]) {
        var newVars: [Int64: AbstractVar] = [:]
        
        for v in vars {
            newVars[v.id] = v
        }
        
        // first add any new Dependencies...
        
        for v in newVars.values {
            if dependencies[v.id] == nil {
                dependencies[v.id] = Dependency(expr: self, observable: v)
            }
        }
        
        // now remove deleted dependencies...
        
        for d in dependencies.values {
            if newVars[d.observable.id] == nil {
                dependencies.removeValue(forKey: d.observable.id)
            }
        }
    }
    
    override public func updateValue() -> Bool {
        let dep = DependencyGroup()
        let newValue = dep.capture(self.expr)
        
        // update dependencies even if expression result doesn't change!
        
        updateDependencies(dep.dependencies)

        if newValue == self.value {
            return false // nothing to do
        }

        self.setValue(newValue)
        
        return true
    }
    
    public init(_ expr: @escaping () -> VarType) {
        self.expr = expr
        let dep = DependencyGroup()
        let initialValue = dep.capture(expr)
        
        super.init(Domain.current, initialValue)
        
        self.dependencies = Dependency.asDictionary(dep.dependencies.map { return Dependency(expr: self, observable: $0) })
    }
}

