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
    
    func testShortCircutEval() {
        let a = MutableVar(1)
        let b = MutableVar(1)
        let expr = Expr { a.value == 2 && b.value == 2 }
        var which = "none"
        
        XCTAssertTrue(expr.value == false) // initial value
        
        // Set up our expectation. It should be called after we set "b" to true

        let e1 = XCTestExpectation(description: "evaluate expr1")
         expr.subscribeOnce  {
            XCTAssertTrue(which == "b")
            XCTAssertTrue(expr.value == true)
            e1.fulfill()
         }

        // First set a to 2, this should cause b to become captured
        
        which = "a"
        a.futureValue = 2
        
        wait(for: [], timeout: 0.10) // just wait for a bit so we can go through a run loop
        
        // Now set b to 2, this should cause the expression to be re-evaluated to true...
        
        which = "b"
        b.futureValue = 2
        
        wait(for: [e1], timeout: 0.10)
    }
}
