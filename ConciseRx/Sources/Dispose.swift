//
//  Dispose.swift
//  ConciseRx
//
//  Created by Ethan Nagel on 2/27/20.
//  Copyright © 2020 Product Ops. All rights reserved.
//

import Foundation

import Concise
import RxSwift

extension Subscription {
    public func asDisposable() -> Disposable {
        return Disposables.create {
            self.dispose()
        }
    }
}
