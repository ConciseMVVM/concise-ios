//
//  ExternalVar.swift
//  Concise-iOS
//
//  Created by Ethan Nagel on 2/18/20.
//  Copyright © 2020 Product Ops. All rights reserved.
//

import Foundation

public class ExternalVar: AbstractVar {
    private let updateValueBlock: () -> Bool
    
    public init(_ domain: Domain, updateValue block: @escaping () -> Bool = { true }) {
        self.updateValueBlock = block
        
        super.init(domain)
    }
    
    override public func updateValue() -> Bool {
        return updateValueBlock()
    }
}
