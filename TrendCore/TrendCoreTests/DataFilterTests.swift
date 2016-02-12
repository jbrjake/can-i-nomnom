//
//  DataFilterTests.swift
//  TrendCore
//
//  Created by Jonathon Rubin on 9/2/15.
//  Copyright © 2015 Jonathon Rubin. All rights reserved.
//

import XCTest

@testable import TrendCore

class DataFilterTests: XCTestCase {
    
    var filter :TrendFilter?
    var samples  = [DataSample]()

    override func setUp() {
        super.setUp()
        filter = TrendFilter()
    }
    
    override func tearDown() {
        filter = nil
        super.tearDown()
    }
    
    func testInit() {
        XCTAssertNotNil(filter, "Filter is nil")
    }
    
    func testFilter() {
        
        let testExpectation = self.expectationWithDescription("Waiting for filtered data")
        //Purge
        let dataStore = DataStore()
        dataStore.fetch(NSDate.distantPast(), toDate: NSDate.distantFuture(), callback: { (records) -> () in
            dataStore.remove(records, completion: { (err) -> () in
                TrendCoreController().importDataFrom(.Dummy, fromDate: NSDate.distantPast(), toDate: NSDate.distantFuture()) { (err) -> () in
                    // Now we have data to work with
                    filter?.filter(dataStore, callback: { (records) -> () in
                        // Now check the samples
                        let record = records[5]
                        XCTAssertNotNil(record.trend)
                        XCTAssert(String(format: "%.1f", record.trend!) == "193.7")
                        testExpectation.fulfill()
                    })
                }
            })
        })
        self.waitForExpectationsWithTimeout(10) { (err) -> Void in
            XCTAssertNil(err, "There was an error: \(err)")
        }
    }
    
        
}
