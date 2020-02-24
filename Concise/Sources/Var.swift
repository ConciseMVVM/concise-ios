//
//  Var.swift
//  Concise-iOS
//
//  Created by Ethan Nagel on 2/18/20.
//  Copyright © 2020 Product Ops. All rights reserved.
//

import Foundation

open class Var<VarType: Equatable>: AbstractVar {
    private var _value: VarType
    
    public var value: VarType {
        domain.willRead(self)
        return _value
    }
    
    public func setValue(_ newValue: VarType) {
        guard updatingValue else {
            fatalError("you may only call setValue from inside udpateValue()!")
        }
            
        _value = newValue
    }

    public init(_ domain: Domain, _ initialValue: VarType) {
        self._value = initialValue
        super.init(domain)
    }
}

