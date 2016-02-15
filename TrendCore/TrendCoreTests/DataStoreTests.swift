//
//  DataStoreTests.swift
//  TrendCore
//
//  Created by Jonathon Rubin on 8/29/15.
//  Copyright © 2015 Jonathon Rubin. All rights reserved.
//

import XCTest
@testable import TrendCore
import PromiseKit

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

        guard let dataStore = dataStore else {
            XCTAssertNotNil(self.dataStore)
            return
        }
        
        firstly {
            dataStore.fetch(NSDate.distantPast(), toDate: NSDate.distantFuture())
        }
        .then { records in
            dataStore.remove(records)
        }
        .then {
            dataStore.fetch(NSDate.distantPast(), toDate: NSDate.distantFuture())
        }
        .then { remainingRecords in
            XCTAssertTrue(remainingRecords.count == 0, "Purge left \(remainingRecords.count ) records behind")
            
        }
        .always {
            purgeExpectation.fulfill()                        
        }
        .error { err in
            XCTAssertNil(err, "Error purging records")
        }
        
        self.waitForExpectationsWithTimeout(10) { (err) -> Void in
            XCTAssertNil(err, "Purge never called back: \(err)")
        }
    }
    
    func testAddAndFetch() {
        self.testPurge()

        let addExpectation = self.expectationWithDescription("Add to data store calls back")
        self.dataStore?.add(samples).then {
            addExpectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(10) { (err) -> Void in
            print("No callback for add to data store: \(err)")
        }

        let fetchExpectation = self.expectationWithDescription("Fetch returns")
        
        guard let dataStore = self.dataStore else {
            XCTAssertNotNil(self.dataStore)
            return
        }
        
        dataStore.fetch(NSDate.distantPast(), toDate: NSDate.distantFuture())
        .then { fetchedSamples -> Void in
            XCTAssertTrue(fetchedSamples.count == self.samples.count, "Expected \(self.samples.count) samples, got \(fetchedSamples.count)")
            for (index, fetchedSample) in fetchedSamples.enumerate() {
                let addedSample = self.samples[index]
                XCTAssertTrue(addedSample == fetchedSample, "Samples did not match: (\(addedSample),\(fetchedSample))")
            }
        }
        .always {
            fetchExpectation.fulfill()                                
        }
            
        self.waitForExpectationsWithTimeout(10) { (err) -> Void in
            print("Fetch didn't return: \(err)")
        }

    }
    
    // Test to make sure if you add the same item multiple times it stores once
    func testNoDupes() {
        
        self.testPurge()
        
        guard let dataStore = self.dataStore else {
            XCTAssertNotNil(self.dataStore)
            return
        }

        let noDupesExpectation = self.expectationWithDescription("Dupes completed")

        firstly {
            dataStore.add(self.samples)
        }
        .then {
            dataStore.add(self.samples)
        }
        .then {
            dataStore.fetch(NSDate.distantPast(), toDate: NSDate.distantFuture())
        }
        .then { samples in
            XCTAssertEqual(self.samples.count, samples.count, "Dupes entered multiple times")
        } 
        .always {
            noDupesExpectation.fulfill()            
        }
        self.waitForExpectationsWithTimeout(10) { (err) -> Void in
            XCTAssertNil(err, "Error waiting for dupes")
        }
    }
    
}
