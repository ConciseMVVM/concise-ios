//
//  MutableVarTests.swift
//  ConciseTests
//
//  Created by Ethan Nagel on 2/21/20.
//  Copyright © 2020 Product Ops. All rights reserved.
//

import Foundation

import XCTest
@testable import Concise

class MutableVarTests: XCTestCase {

    override func setUp() {
    }

    override func tearDown() {
    }
    
    func testSetValue() {
        let initialValue = 1
        let newValue = 2
        
        let mutable = MutableVar(initialValue)
        
        // make sure initial conditions are set correctly...
        
        XCTAssertTrue(mutable.value == initialValue)
        XCTAssertTrue(mutable.futureValue == initialValue)
        
        // change a value which should only be reflected in the future...
        
        mutable.futureValue = newValue
        
        XCTAssertTrue(mutable.value == initialValue)
        XCTAssertTrue(mutable.futureValue == newValue)
        
        // wait for the next change, which should have the new value propogated...

        let e = XCTestExpectation(description: "set mutable value")
        mutable.subscribeOnce  {
            XCTAssertTrue(mutable.value == newValue)
            XCTAssertTrue(mutable.futureValue == newValue)
            e.fulfill()
        }
        
        wait(for: [e], timeout: 1.0)
    }
}
