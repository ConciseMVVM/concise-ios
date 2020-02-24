//
//  DisposeBagExtensions.swift
//  ConciseRx
//
//  Created by Ethan Nagel on 2/18/20.
//  Copyright © 2020 Product Ops. All rights reserved.
//

import Foundation
import RxSwift
import Concise

extension DisposeBag {
    static private(set) var current: DisposeBag? = nil
    
    public func capture<T>(_ block: () -> T) -> T {
        let old = DisposeBag.current
        DisposeBag.current = self
        
        let result = block()
        
        DisposeBag.current = old
        
        return result
    }
    
    public static func capture(_ block: () -> Void) -> DisposeBag {
        let disposeBag = DisposeBag()
        
        disposeBag.capture(block)
        
        return disposeBag
    }
    
    public static func captureDisposable(_ disposable: Disposable) {
        guard let current = current else {
            fatalError("add(disposable:) may only be used when in a capture call")
        }
        
        current.insert(disposable)
    }
}
