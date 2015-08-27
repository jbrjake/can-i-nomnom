//
//  DataImporter.swift
//  TrendCore
//
//  Created by Jonathon Rubin on 7/18/15.
//  Copyright (c) 2015 Jonathon Rubin. All rights reserved.
//

import UIKit
import XCTest

class DataImporterTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
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
    
    func testFactory() {
        let dummyImporter = DataImporterFactory.importerForType(TrendCoreImporterType.Dummy)
        XCTAssertNotNil(dummyImporter, "Factory did not provide a dummy data importer")
        
        let healthKitImporter = DataImporterFactory.importerForType(TrendCoreImporterType.HealthKit)
        XCTAssertNotNil(healthKitImporter, "Factory did not provide a Health Kit Data Importer")
    }
    
    func testDummyImporter() {
        let callbackFired = self.expectationWithDescription("Callback for data importer fires")
        var samples :[DataSample]? = nil
        DataImporterFactory.importerForType(.Dummy).samplesForRangeFromDate(NSDate.distantPast() , toDate: NSDate.distantFuture() ) { (importedSamples) -> () in
            samples = importedSamples
            callbackFired.fulfill()
        }
        self.waitForExpectationsWithTimeout(100, handler: { (err) -> Void in
            XCTAssertNil(err, "Dummy importer did not callback")
            XCTAssertTrue(samples?.count == 6, "Dummy importer did not provide all 6 dummy samples")
        })
    }
    
    func testDummyImporterRanges() {
        let callbackFired = self.expectationWithDescription("Callback for data importer fires")
        var samples :[DataSample]? = nil
        let originDate = NSDate.distantPast() 
        let day1 = originDate.dateByAddingTimeInterval(24*60*60)
        let day4 = originDate.dateByAddingTimeInterval(24*60*60*4)

        DataImporterFactory.importerForType(.Dummy).samplesForRangeFromDate(day1, toDate: day4) { (importedSamples) -> () in
            samples = importedSamples
            callbackFired.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(100, handler: { (err) -> Void in
            XCTAssertNil(err, "Dummy importer did not callback")
            XCTAssertTrue(samples?.count == 4, "Dummy importer did not provide all 4 dummy samples in range")
            XCTAssertTrue(samples?[0].value == 194, "Range should start with date where dummy weight was 194")
            XCTAssertTrue(samples?[3].value == 191, "Range should start with date where dummy weight was 191")
        })
        
    }
    
    func testHealthKitImporter() {
        let callbackFired = self.expectationWithDescription("Callback for data importer fires")
        var samples :[DataSample]? = nil
        DataImporterFactory.importerForType(.HealthKit).samplesForRangeFromDate(NSDate.distantPast() , toDate: NSDate.distantFuture() ) { (importedSamples) -> () in
            samples = importedSamples
            callbackFired.fulfill()
        }
        self.waitForExpectationsWithTimeout(100, handler: { (err) -> Void in
            XCTAssertNil(err, "HealthKit importer did not callback")
        })
    }

}
