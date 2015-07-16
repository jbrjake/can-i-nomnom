//
//  TrendCoreTests.swift
//  TrendCoreTests
//
//  Created by Jonathon Rubin on 7/11/15.
//  Copyright (c) 2015 Jonathon Rubin. All rights reserved.
//

import UIKit
import XCTest
import TrendCore

class TrendCoreTests: XCTestCase {
    
    var trendCore :TrendCoreController?
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        trendCore = TrendCoreController()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        XCTAssert(true, "Pass")
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock() {
            // Put the code you want to measure the time of here.
        }
    }
    
    func testInit() {
        XCTAssertNotNil(trendCore, "Init failed")
    }
    
}
