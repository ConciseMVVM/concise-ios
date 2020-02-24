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
    }
    
    private let expr: () -> VarType
    private var dependencies: [Dependency] = []
    
    override public func updateValue() -> Bool {
        let dep = DependencyGroup()
        let newValue = dep.capture(self.expr)
        
        if newValue == self.value {
            return false // nothing to do
        }

        self.setValue(newValue)
        self.dependencies = dep.dependencies.map { return Dependency(expr: self, observable: $0) }
        
        return true
    }
    
    public init(_ expr: @escaping () -> VarType) {
        self.expr = expr
        let dep = DependencyGroup()
        let initialValue = dep.capture(expr)
        
        super.init(Domain.current, initialValue)
        self.dependencies = dep.dependencies.map { return Dependency(expr: self, observable: $0) }
    }
}

