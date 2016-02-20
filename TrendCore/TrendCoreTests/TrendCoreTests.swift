//
//  TrendCoreTests.swift
//  TrendCoreTests
//
//  Created by Jonathon Rubin on 7/11/15.
//  Copyright (c) 2015 Jonathon Rubin. All rights reserved.
//

import UIKit
import XCTest
import PromiseKit

@testable import TrendCore

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
        XCTAssertNotNil(trendCore?.dataStore, "Data store init failed")
        XCTAssertNotNil(trendCore?.dataFilter, "Data filter init failed")
    }

    func testImport() {
        
        guard let trendCore = trendCore else {
            XCTAssertNotNil(self.trendCore)
            return
        }
        
        let callbackFired = self.expectationWithDescription("Callback for trend core import triggered")

        firstly {
            trendCore.importDataFrom(
                TrendCoreImporterType.Dummy, 
                fromDate: NSDate.distantPast(), 
                toDate: NSDate.distantFuture()
            )
        }
        .then {
            callbackFired.fulfill()
        }

        self.waitForExpectationsWithTimeout(1, handler: { (err) -> Void in
            XCTAssertNil(err, "TrendCore did not callback from import")
        })
        
    }
    
    func testFetch() {
        
        // The DataStore tests can run in parallel with the TrendCore tests, leaving the DB purged between calls
        testImport()
        
        guard let trendCore = trendCore else { 
            XCTAssertNotNil(self.trendCore)
            return
        }
        
        let hasSamples = self.expectationWithDescription("Samples exist")
        
        firstly {
            trendCore.fetchWeightsFrom( NSDate.distantPast(), toDate:NSDate.distantFuture() )
        }
        .then { samples -> Void in
            XCTAssertEqual(samples.count, 6, "The dummy importer gives 6 samples, not \(samples.count)")
            hasSamples.fulfill()            
        }
        
        self.waitForExpectationsWithTimeout(1, handler: { (err) -> Void in
            XCTAssertNil(err, "TrendCore did not return samples")
        })
    }

}
