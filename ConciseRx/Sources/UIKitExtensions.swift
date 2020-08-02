//
//  UIKitExtensions.swift
//  ConciseRx
//
//  Created by Ethan Nagel on 7/31/20.
//  Copyright © 2020 Product Ops. All rights reserved.
//

import Foundation
import UIKit
import Concise
import RxSwift


public func *= <Element: ConciseBindableViewModelItem>(lhs: inout UITableViewDataSource?, rhs: ConciseArray<Element>) where Element.View: UITableViewCell {
    let dataSource = ConciseTableViewSingleSectionDataSource(rhs)
    DisposeBag.captureDisposable(dataSource.asDisposable()) // capture the subscription so it won't be dealloced right away
    lhs = dataSource
}

public func *= <Element: ConciseBindableViewModelItem>(lhs: inout UITableViewDataSource?, rhs: [Element]) where Element.View: UITableViewCell, Element: Equatable {
    let array = MutableConciseArray(rhs)
    let dataSource = ConciseTableViewSingleSectionDataSource(array)
    DisposeBag.captureDisposable(dataSource.asDisposable()) // capture the subscription so it won't be dealloced right away
    lhs = dataSource
}

public func *= (lhs: inout UITableViewDataSource?, rhs: [ConciseTableViewSectionDataSource]) {
    let dataSource = ConciseTableViewMultiSectionDataSource(rhs)

    DisposeBag.captureDisposable(dataSource.asDisposable())
    lhs = dataSource
}
