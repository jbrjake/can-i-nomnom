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
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock() {
            // Put the code you want to measure the time of here.
        }
    }
    
    func testInit() {
        XCTAssertNotNil(trendCore, "Init failed")
    }

    func testImport() {
        let callbackFired = self.expectationWithDescription("Callback for trend core import triggered")
        trendCore?.importDataFrom(
            TrendCoreImporterType.Dummy, 
            fromDate: NSDate.distantPast(), 
            toDate: NSDate.distantFuture(), 
            completion: { 
                err in
                callbackFired.fulfill()
            }
        )
        
        self.waitForExpectationsWithTimeout(1, handler: { (err) -> Void in
            XCTAssertNil(err, "TrendCore did not callback from import")
        })
        
    }
    
    func testFetch() {
        
        let hasSamples = self.expectationWithDescription("Samples exist")
        
        trendCore?.fetchWeightsFrom(
            NSDate.distantPast() , 
            toDate:NSDate.distantFuture(), 
            callback: { 
                (samples) -> () in
                hasSamples.fulfill()
                
            }
        )
        
        self.waitForExpectationsWithTimeout(1, handler: { (err) -> Void in
            XCTAssertNil(err, "TrendCore did not return samples")
        })
    }

}
