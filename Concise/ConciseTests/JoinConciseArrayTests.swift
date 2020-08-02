//
//  JoinConciseArrayTests.swift
//  ConciseTests
//
//  Created by Ethan Nagel on 8/1/20.
//  Copyright © 2020 Product Ops. All rights reserved.
//

import Foundation
import XCTest
@testable import Concise

class JoinConciseArrayTests: XCTestCase {

    override func setUp() {
    }

    override func tearDown() {
    }
    
    func testStaticLists() {
        let a = MutableConciseArray([1, 2, 3])
        let b = MutableConciseArray([4, 5, 6])
        
        let c = ConciseArray.join(a, b)
        
        XCTAssertEqual(c.items, [1,2,3,4,5,6])
        
        a.futureItems = [7,8,9]
        XCTAssertEqual(a.futureItems, [7,8,9])
        
        let e0 = XCTestExpectation(description: "e0")
        a.subscribeOnce {
            XCTAssertEqual(a.items, [7,8,9])
            e0.fulfill()
        }

        let e1 = XCTestExpectation(description: "e1")
        c.subscribeOnce {
            XCTAssertEqual(c.items, [7,8,9,4,5,6])
            e1.fulfill()
        }
        
        wait(for: [e0, e1], timeout: 0.10)
    }
    
    func testDynamicLists() {
        let a = MutableConciseArray([1,2,3])
        let b = MutableConciseArray([4,5,6])
        let c = MutableConciseArray([7,8,9])
        
        let d: MutableConciseArray<ConciseArray<Int>> = MutableConciseArray([a, b, c])
        let joined = ConciseArray.join(d)
        
        XCTAssertEqual(joined.items, [1,2,3,4,5,6,7,8,9])
        
        let e0 = XCTestExpectation(description: "e0")
        joined.subscribeOnce {
            XCTAssertEqual(joined.items, [1,2,4,5,6,7,8,9])
            XCTAssertEqual(joined.changes, [.remove(offset: 2)])
            e0.fulfill()
        }
        
        a.futureItems = [1,2]
        wait(for: [e0], timeout: 0.10)
        
        let e1 = XCTestExpectation(description: "e1")
        joined.subscribeOnce {
            XCTAssertEqual(joined.items, [1,2,7,8,9])
            XCTAssertEqual(joined.changes, [.remove(offset: 4), .remove(offset: 3), .remove(offset: 2)])
            e1.fulfill()
        }
        
        d.futureItems = [a,c]
        wait(for: [e1], timeout: 0.10)
            
        let e2 = XCTestExpectation(description: "e2")
        joined.subscribeOnce {
            XCTAssertEqual(joined.items, [1,2,7,8,9,99])
            print("\(joined.changes)")
            XCTAssertEqual(joined.changes, [.insert(offset: 5)])
            e2.fulfill()
        }
        
        let e = MutableConciseArray([99])
        d.futureItems = [a,c,e]
        wait(for: [e2], timeout: 0.10)
    }
}
