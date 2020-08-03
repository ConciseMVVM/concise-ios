//
//  BindOperator.swift
//  ConciseRx
//
//  Created by Ethan Nagel on 2/18/20.
//  Copyright © 2020 Product Ops. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import Concise

public func *= <Observer, Observable>(lhs: Observer, rhs: Observable) where Observer: ObserverType, Observable: ObservableType, Observable.Element == Observer.Element {
    DisposeBag.captureDisposable(rhs.bind(to: lhs))
}

public func *= <Observer, Type>(lhs: Observer, rhs: @escaping () -> Type) where Type: Equatable, Observer: ObserverType, Observer.Element == Type {
    let expr = Expr(rhs)
    DisposeBag.captureDisposable(expr.bind(to: lhs))
}

public func *= <Observer, Type>(lhs: Observer, rhs: Var<Type>) where Type: Equatable, Observer: ObserverType, Observer.Element == Type {
    DisposeBag.captureDisposable(rhs.bind(to: lhs))
}
