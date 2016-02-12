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
    
    func testTrendFilter() {
        
        let testExpectation = self.expectationWithDescription("Waiting for filtered data")

        let dataStore = DataStore()
        dataStore.fetch(NSDate.distantPast(), toDate: NSDate.distantFuture(), callback: { (records) -> () in
        
            //Purge
            dataStore.remove(records, completion: { (err) -> () in
                
                // Load dummy data
                TrendCoreController().importDataFrom(.Dummy, fromDate: NSDate.distantPast(), toDate: NSDate.distantFuture()) { (err) -> () in
                    dataStore.fetch(NSDate.distantPast(), toDate: NSDate.distantFuture(), callback: { (records) -> () in

                        // Filter
                        filter?.filter(records, callback: { (records) -> () in
                            
                            // Now check the samples
                            let record = records[5]
                            XCTAssertNotNil(record.trend)
                            XCTAssert(String(format: "%.1f", record.trend!) == "193.7")
                            testExpectation.fulfill()
                        
                        })
                        
                    })
                }
                
            })
        })
        
        self.waitForExpectationsWithTimeout(10) { (err) -> Void in
            XCTAssertNil(err, "There was an error: \(err)")
        }
    }
    
    func testInterpolationFilter() {
        let testExpectation = self.expectationWithDescription("Waiting for filtered data")

        let dataStore = DataStore()
        dataStore.fetch(NSDate.distantPast(), toDate: NSDate.distantFuture(), callback: { (records) -> () in

            //Purge
            dataStore.remove(records, completion: { (err) -> () in
            
                // Load dummy data
                TrendCoreController().importDataFrom(.Dummy, fromDate: NSDate.distantPast(), toDate: NSDate.distantFuture()) { (err) -> () in

                    let recordC = records[2]
                    let recordD = records[3]

                    // Create a gap in the middle
                    dataStore.remove([recordC, recordD], completion: { (err) -> () in
                    
                        // Re-fetch
                        dataStore.fetch(NSDate.distantPast(), toDate: NSDate.distantFuture(), callback: { (records) -> () in
                            
                            // Filter
                            filter?.filter(records, callback: { (filteredRecords) -> () in
                                
                                // Now check samples 2 and 3
                                let filteredRecordC = filteredRecords[2]
                                let filteredRecordD = filteredRecords[3]

                                XCTAssertEqual(filteredRecordC.value, recordC.value)
                                XCTAssertEqual(filteredRecordC.dateSampled, recordC.dateSampled)
                                
                                XCTAssertEqual(filteredRecordD.value, recordD.value)
                                XCTAssertEqual(filteredRecordD.dateSampled, recordD.dateSampled)
                                
                                testExpectation.fulfill()
                            })
                        })
                        
                    })
                }
                
            })
        })
        
        self.waitForExpectationsWithTimeout(10) { (err) -> Void in
            XCTAssertNil(err, "There was an error: \(err)")
        }
    }
    
        
}
