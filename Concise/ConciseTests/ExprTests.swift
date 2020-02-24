//
//  ExprTests.swift
//  ConciseTests
//
//  Created by Ethan Nagel on 2/21/20.
//  Copyright © 2020 Product Ops. All rights reserved.
//

import Foundation

import XCTest
@testable import Concise

class ExprTests: XCTestCase {

    override func setUp() {
    }

    override func tearDown() {
    }
    
    func testBasicEval() {
        let a = MutableVar(1)
        let b = MutableVar(2)
        
        let expr = Expr { a.value + b.value }
        
        // make sure initial conditions are set correctly...
        
        XCTAssertTrue(expr.value == 1 + 2)
        
        // Change a dependent value...
        
        a.futureValue = 2
        
        XCTAssertTrue(expr.value == 1 + 2)
        
        // wait for the next change, which should have the new value propagated...

        let e = XCTestExpectation(description: "evaluate expr")
        expr.subscribeOnce  {
            XCTAssertTrue(expr.value == 2 + 2)
            e.fulfill()
        }
        
        wait(for: [e], timeout: 1.0)
    }
}
