//
//  PropertyWrappers.swift
//  Concise-iOS
//
//  Created by Ethan Nagel on 2/18/20.
//  Copyright © 2020 Product Ops. All rights reserved.
//

import Foundation

public func *= <VarType>(lhs: inout VarProp<VarType>, rhs: @escaping () -> VarType) where VarType: Equatable {
    lhs.wrapped = Expr(rhs)
}

public func *= <VarType>(lhs: inout VarProp<VarType?>, rhs: @escaping () -> VarType) where VarType: Equatable {
    lhs.wrapped = Expr(rhs)
}

public func *= <VarType>(lhs: inout VarProp<VarType>, rhs: Var<VarType>) {
    // we should be able to do "lhs.var = rhs" but the compiler won't let us???
    lhs.wrapped = Expr({ rhs.value })
}

public func *= <VarType>(lhs: inout VarProp<VarType?>, rhs: Var<VarType>) {
    // we should be able to do "lhs.var = rhs" but the compiler won't let us???
    lhs.wrapped = Expr({ rhs.value })
}

public func *= <Element>(lhs: inout ArrayProp<Element>, rhs: ConciseArray<Element>) {
    lhs.wrapped = rhs
}

public protocol AbstractVarPropertyWrapper {
    var abstractVar: AbstractVar? { get }
}

@propertyWrapper
public struct VarProp<VarType> where VarType: Equatable {
    public var wrapped: Expr<VarType>?
    
    public var wrappedValue: VarType {
        guard let wrapped = self.wrapped else {
            fatalError("attempt to use VarProp that has not been initialized")
        }
        
        return wrapped.value
    }
    
    public var projectedValue: Var<VarType> {
        guard let wrapped = self.wrapped else {
            fatalError("attempt to call VarProp that has not been initialized")
        }
        
        return wrapped
    }

    public init() {
    }
}

extension VarProp: AbstractVarPropertyWrapper {
    public var abstractVar: AbstractVar? { return self.wrapped }
}

@propertyWrapper
public struct MutableProp<VarType: Equatable> {
    public let wrapped: MutableVar<VarType>
    
    public var wrappedValue: VarType {
        get { return wrapped.value }
        set { wrapped.futureValue = newValue }
    }
    
    public var projectedValue: MutableVar<VarType> { wrapped }

    public init(wrappedValue: VarType) {
        wrapped = MutableVar(wrappedValue)
    }
}

extension MutableProp: AbstractVarPropertyWrapper {
    public var abstractVar: AbstractVar? { return self.wrapped }
}

@propertyWrapper
public struct ArrayProp<Element> {
    public var wrapped: ConciseArray<Element>!
    
    public var wrappedValue: [Element] { wrapped.items }
    public var projectedValue: ConciseArray<Element> { wrapped }
    
    public init() {
    }
}

extension ArrayProp: AbstractVarPropertyWrapper {
    public var abstractVar: AbstractVar? { return self.wrapped }
}

@propertyWrapper
public struct MutableArrayProp<Element: Equatable> {
    private var wrapped: MutableConciseArray<Element>
    
    public var wrappedValue: [Element] {
        get { return wrapped.items }
        set { wrapped.futureItems = newValue }
    }
    
    public var projectedValue: MutableConciseArray<Element> { wrapped }
    
    public init(_ items: [Element] = []) {
        self.wrapped = MutableConciseArray(items)
    }
}

extension MutableArrayProp: AbstractVarPropertyWrapper {
    public var abstractVar: AbstractVar? { return self.wrapped }
}

