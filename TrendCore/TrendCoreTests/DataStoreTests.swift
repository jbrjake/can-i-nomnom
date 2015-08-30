//
//  DataStoreTests.swift
//  TrendCore
//
//  Created by Jonathon Rubin on 8/29/15.
//  Copyright © 2015 Jonathon Rubin. All rights reserved.
//

import XCTest

class DataStoreTests: XCTestCase {
    
    var dataStore :DataStore?
    let samples = [
        DataSample(value: 195.0, trend: nil, dateSampled: NSDate(), dateImported: NSDate(), source: .Dummy),
        DataSample(value: 196.0, trend: nil, dateSampled: NSDate(), dateImported: NSDate(), source: .Dummy)
    ]
    
    override func setUp() {
        super.setUp()
        self.dataStore = DataStore()        
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
        self.dataStore = nil
    }
    
    func testInit() {
        XCTAssertNotNil(self.dataStore, "Data store could not be inited")
    }
    
    func testPurge() {
        // Purge the data store
        let purgeExpectation = self.expectationWithDescription("Purge calls back")
        self.dataStore?.fetch(NSDate.distantPast(), toDate: NSDate.distantFuture(), callback: { (records) -> () in
            self.dataStore?.remove(records, completion: { (err) -> () in
                XCTAssertNil(err, "Error removing all records")
                
                let fetchExpectation = self.expectationWithDescription("Fetch returns")
                self.dataStore?.fetch(NSDate.distantPast(), toDate: NSDate.distantFuture(), callback: { (remainingRecords) -> () in
                    XCTAssertTrue(remainingRecords.count == 0, "Purge left \(remainingRecords.count ) records behind")
                    fetchExpectation.fulfill()
                })
                
                self.waitForExpectationsWithTimeout(10, handler: { (err) -> Void in
                    print("Fetch never returned: \(err)")
                })
                
                
                purgeExpectation.fulfill()
            })
        })
        
        self.waitForExpectationsWithTimeout(10) { (err) -> Void in
            print("Purge never called back: \(err)")
        }
    }
    
    func testAddAndFetch() {
        self.testPurge()

        let addExpectation = self.expectationWithDescription("Add to data store calls back")
        self.dataStore?.add(samples, completion: { (err) -> () in
            addExpectation.fulfill()
        })
        self.waitForExpectationsWithTimeout(10) { (err) -> Void in
            print("No callback for add to data store: \(err)")
        }

        let fetchExpectation = self.expectationWithDescription("Fetch returns")
        self.dataStore?.fetch(NSDate.distantPast(), toDate: NSDate.distantFuture(), callback: { (fetchedSamples) -> () in
            
            XCTAssertTrue(fetchedSamples.count == self.samples.count, "Expected \(self.samples.count) samples, got \(fetchedSamples.count)")
            for (index, fetchedSample) in fetchedSamples.enumerate() {
                let addedSample = self.samples[index]
                XCTAssertTrue(addedSample == fetchedSample, "Samples did not match: (\(addedSample),\(fetchedSample))")
            }
            
            fetchExpectation.fulfill()
        })
        
        self.waitForExpectationsWithTimeout(10) { (err) -> Void in
            print("Fetch didn't return: \(err)")
        }

    }
    
}
