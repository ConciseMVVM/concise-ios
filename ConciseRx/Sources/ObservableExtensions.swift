//
//  ConciseRx.swift
//  SimpleMethod
//
//  Created by Ethan Nagel on 2/7/20.
//  Copyright © 2020 Product Ops. All rights reserved.
//

import Foundation
import RxSwift
import Concise

extension Var: ObservableType {
    public func asObservable() -> Observable<VarType> {
        return Observable.create { (observer) -> Disposable in
            observer.onNext(self.value)
            var subscription: Subscription? = self.subscribe {
                observer.onNext(self.value)
            }
            
            return Disposables.create {
                subscription?.dispose()
                subscription = nil
            }
        }
    }
    
    public func subscribe<Observer: ObserverType>(_ observer: Observer) -> Disposable where Observer.Element == VarType {
        return asObservable().subscribe(observer)
    }
}

extension ExternalVar: ObservableType {
    public func asObservable() -> Observable<Void> {
        return Observable.create { (observer) -> Disposable in
            observer.onNext(Void())
            var subscription: Subscription? = self.subscribe {
                observer.onNext(Void())
            }
            
            return Disposables.create {
                subscription?.dispose()
                subscription = nil
            }
        }
    }
    
    public func subscribe<Observer: ObserverType>(_ observer: Observer) -> Disposable where Observer.Element == Void {
        return asObservable().subscribe(observer)
    }
}

extension MutableVar: ObserverType {
    public func on(_ event: Event<VarType>) {
        if case Event.next(let value) = event {
            self.futureValue = value
        }
    }
}


