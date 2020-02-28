//
//  PropertyWrappers.swift
//  Concise-iOS
//
//  Created by Ethan Nagel on 2/18/20.
//  Copyright © 2020 Product Ops. All rights reserved.
//

import Foundation

public func *= <VarType>(lhs: inout ExprProp<VarType>, rhs: @escaping () -> VarType) where VarType: Equatable {
    lhs.expr = Expr(rhs)
}

public func *= <VarType>(lhs: inout ExprProp<VarType?>, rhs: @escaping () -> VarType) where VarType: Equatable {
    lhs.expr = Expr(rhs)
}

public protocol AbstractVarPropertyWrapper {
    var abstractVar: AbstractVar? { get }
}

@propertyWrapper
public struct ExprProp<VarType> where VarType: Equatable {
    public var expr: Expr<VarType>?
    
    public var wrappedValue: VarType {
        guard let expr = self.expr else {
            fatalError("attempt to use ExprProp that has not been initialized")
        }
        
        return expr.value
    }
    
    public var projectedValue: Expr<VarType> {
        guard let expr = self.expr else {
            fatalError("attempt to call ExprProp that has not been initialized")
        }
        
        return expr
    }

    public init() {
    }
}

extension ExprProp: AbstractVarPropertyWrapper {
    public var abstractVar: AbstractVar? { return self.expr }
}

@propertyWrapper
public struct MutableProp<VarType: Equatable> {
    public let mutable: MutableVar<VarType>
    
    public var wrappedValue: VarType {
        get { return mutable.value }
        set { mutable.futureValue = newValue }
    }
    
    public var projectedValue: MutableVar<VarType> { mutable }

    public init(wrappedValue: VarType) {
        mutable = MutableVar(wrappedValue)
    }
}

extension MutableProp: AbstractVarPropertyWrapper {
    public var abstractVar: AbstractVar? { return self.mutable }
}

@propertyWrapper
public struct ArrayProp<Element> {
    public var array: ConciseArray<Element>!
    
    public var wrappedValue: [Element] { array.items }
    public var projectedValue: ConciseArray<Element> { array }
    
    public init() {
    }
}

extension ArrayProp: AbstractVarPropertyWrapper {
    public var abstractVar: AbstractVar? { return self.array }
}

public func *= <Element>(lhs: inout ArrayProp<Element>, rhs: ConciseArray<Element>) {
    lhs.array = rhs
}

@propertyWrapper
public struct MutableArrayProp<Element: Equatable> {
    private var array: MutableConciseArray<Element>
    
    public var wrappedValue: [Element] {
        get { return array.items }
        set { array.futureItems = newValue }
    }
    
    public var projectedValue: MutableConciseArray<Element> { array }
    
    public init(_ items: [Element] = []) {
        self.array = MutableConciseArray(items)
    }
}

extension MutableArrayProp: AbstractVarPropertyWrapper {
    public var abstractVar: AbstractVar? { return self.array }
}

