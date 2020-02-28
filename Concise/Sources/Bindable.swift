//
//  Bindable.swift
//  Concise
//
//  Created by Ethan Nagel on 2/28/20.
//  Copyright © 2020 Product Ops. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

// adds a bindable property to Var types that can receive values from SwiftUI controls

public protocol Bindable {
    associatedtype VarType: Equatable
    
    var binding: Binding<VarType> { get }
}

extension Expr: Bindable {
    public var binding: Binding<VarType> {
        return Binding(get: { self.value }, set: { (_) in fatalError("Expr properties can only have read-only bindings") } )
    }
}

extension MutableVar: Bindable {
    public var binding: Binding<VarType> {
        return Binding(get: { self.value }, set: { self.futureValue = $0})
    }
}

extension ConciseArray: Bindable where Element: Equatable {
    public typealias VarType = [Element]
    
    public var binding: Binding<[Element]> {
        return Binding(get: { self.items }, set: { (_) in fatalError("ConciseArray properties can only have read-only bindings") })
    }
}
