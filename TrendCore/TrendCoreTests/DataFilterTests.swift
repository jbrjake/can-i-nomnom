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
        DataStoreTests().testPurge()
        TrendCoreController().importDataFrom(.Dummy, fromDate: NSDate.distantPast(), toDate: NSDate.distantFuture()) { (err) -> () in
            // Now we have data to work with
            filter?.filter(DataStore(), callback: { (err) -> () in
                // Now check the samples
            })
        }

    }
        
}
