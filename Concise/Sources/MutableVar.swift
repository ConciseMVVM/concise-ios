//
//  MutableVar.swift
//  Concise-iOS
//
//  Created by Ethan Nagel on 2/18/20.
//  Copyright © 2020 Product Ops. All rights reserved.
//

import Foundation

public class MutableVar<VarType: Equatable>: Var<VarType> {
    private var _futureValue: VarType? = nil
    
    public var futureValue: VarType {
        get { return _futureValue ?? self.value }
        set {
            _futureValue = newValue
            setNeedsUpdate()
        }
    }

    override public  func updateValue() -> Bool {
        guard let futureValue = _futureValue else {
            return false // weird
        }
        _futureValue = nil
        
        guard futureValue != self.value else {
            return false
        }

        setValue(futureValue)
        return true
    }
    
    public init(_ initialValue: VarType) {
        super.init(Domain.current, initialValue)
    }
}

