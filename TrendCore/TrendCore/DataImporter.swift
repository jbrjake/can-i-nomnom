//
//  DataImporter.swift
//  TrendCore
//
//  Created by Jonathon Rubin on 7/17/15.
//  Copyright (c) 2015 Jonathon Rubin. All rights reserved.
//

import Foundation
import HealthKit


public enum TrendCoreImporterType :String {
    case Dummy      = "Dummy"
    case HealthKit  = "HealthKit"
}

typealias ImporterCallback = (([DataSample]) -> ())
protocol DataImporterProtocol : class {
    func samplesForRangeFromDate(fromDate :NSDate, toDate :NSDate, callback :ImporterCallback)
}

class DataImporterFactory {
    class func importerForType(importerType :TrendCoreImporterType) -> DataImporterProtocol {
        switch importerType {
        case .Dummy:
            return DummyDataImporter()
        case .HealthKit:
            return HealthKitDataImporter()
        }
    }
}

class DummyDataImporter :DataImporterProtocol {

    let originDate :NSDate
    let day1 :NSDate
    let day2 :NSDate
    let day3 :NSDate
    let day4 :NSDate
    let day5 :NSDate
    let samples :[DataSample]
    
    init() {
        originDate = NSDate.distantPast() 
        day1 = originDate.dateByAddingTimeInterval(24*60*60)
        day2 = originDate.dateByAddingTimeInterval(24*60*60*2)
        day3 = originDate.dateByAddingTimeInterval(24*60*60*3)
        day4 = originDate.dateByAddingTimeInterval(24*60*60*4)
        day5 = originDate.dateByAddingTimeInterval(24*60*60*5)
        samples = [
            DataSample(value: 195.0, dateSampled: originDate, dateImported: NSDate(), source: .Dummy),
            DataSample(value: 194.0, dateSampled: day1, dateImported: NSDate(), source: .Dummy),
            DataSample(value: 193.0, dateSampled: day2, dateImported: NSDate(), source: .Dummy),
            DataSample(value: 192.0, dateSampled: day3, dateImported: NSDate(), source: .Dummy),
            DataSample(value: 191.0, dateSampled: day4, dateImported: NSDate(), source: .Dummy),
            DataSample(value: 190.0, dateSampled: day5, dateImported: NSDate(), source: .Dummy)
        ]
        
    }
    
    func samplesForRangeFromDate(fromDate :NSDate, toDate :NSDate, callback :ImporterCallback) {
        let filteredSamples = samples.filter() {
            let sample = $0
            let fromComparison = sample.dateSampled.compare(fromDate)
            let toComparison = sample.dateSampled.compare(toDate)
            
            if (fromComparison == .OrderedDescending || fromComparison == .OrderedSame) &&
               (  toComparison == .OrderedAscending  ||   toComparison == .OrderedSame)
            {
                return true
            }
            else {
                return false
            }
        }
        callback(filteredSamples)
    }
}

class HealthKitDataImporter :DataImporterProtocol {
    
    let healthKitStore = HKHealthStore()
    
    func samplesForRangeFromDate(fromDate :NSDate, toDate :NSDate, callback :ImporterCallback) {
        // Authorization can't happen in the framework, it gets all messed up when it tries to use HealthKit
/*        authorizeHealthKitAccess { (success, error) -> Void in
            if success == true && error == nil {                
                callback([ImportedDataSample]())
            }
            else {
                println("HK authorization error: \(error)")
                callback([ImportedDataSample]())
            }
        }     
*/
        
        healthKitSamplesFromDate(fromDate, toDate: toDate) { (hkSamples) -> () in
            var importedSamples = [DataSample]()
            for sample in hkSamples {
                let importedSample = DataSample(value: sample.quantity.doubleValueForUnit(HKUnit.poundUnit()), dateSampled: sample.startDate, dateImported: NSDate(), source: .Dummy)
                importedSamples.append(importedSample)
            }
            
            callback(importedSamples)
        }

    }
    
    func healthKitSamplesFromDate(fromDate :NSDate, toDate :NSDate, completion:([HKQuantitySample]) -> () ) {
        if let sampleType = HKSampleType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass) {
            let dateRangePredicate = HKQuery.predicateForSamplesWithStartDate(fromDate, endDate: toDate, options: .None)
        
           let healthKitQuery = HKSampleQuery(
                sampleType: sampleType, 
                predicate: dateRangePredicate, 
                limit: 1000000, 
                sortDescriptors: []
                ) { 
                    (query, results, error) -> Void in
                    if let quantitySamples = results as? [HKQuantitySample] {
                        completion(quantitySamples)                        
                    }
                    else {
                        print("error getting samples from healthkit: \(error)")
                    }
            }
            healthKitStore.executeQuery(healthKitQuery)
        }
        
    }
    
    func authorizeHealthKitAccess(callback:((success:Bool, error:NSError!) -> Void)) {
        
        if !HKHealthStore.isHealthDataAvailable() {
             let error = NSError(domain: "com.caninomnom.healthkit", code: 1, userInfo: [NSLocalizedDescriptionKey:"HealthKit data is not available"])
            callback(success: false, error: error)
            return
        }
        
        if let bodyMassQuantity = HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass) {
            let healthKitTypesToReadAndWrite = Set(arrayLiteral: bodyMassQuantity)
            healthKitStore.requestAuthorizationToShareTypes(healthKitTypesToReadAndWrite, readTypes: healthKitTypesToReadAndWrite) { (success, error) -> Void in
                callback(success: success, error: error)
            }
        }
    }
    
}