//
//  DataImporter.swift
//  TrendCore
//
//  Created by Jonathon Rubin on 7/17/15.
//  Copyright (c) 2015 Jonathon Rubin. All rights reserved.
//

import Foundation
import HealthKit

struct ImportedDataSample {
    var value :Double
    var dateSampled :NSDate
    var dateImported :NSDate
}

public enum TrendCoreImporterType {
    case Dummy
    case HealthKit
}

typealias ImporterCallback = (([ImportedDataSample]) -> ())
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
    let samples :[ImportedDataSample]
    
    init() {
        originDate = NSDate.distantPast() as! NSDate
        day1 = originDate.dateByAddingTimeInterval(24*60*60)
        day2 = originDate.dateByAddingTimeInterval(24*60*60*2)
        day3 = originDate.dateByAddingTimeInterval(24*60*60*3)
        day4 = originDate.dateByAddingTimeInterval(24*60*60*4)
        day5 = originDate.dateByAddingTimeInterval(24*60*60*5)
        samples = [
            ImportedDataSample(value: 195.0, dateSampled: originDate, dateImported: NSDate()),
            ImportedDataSample(value: 194.0, dateSampled: day1, dateImported: NSDate()),
            ImportedDataSample(value: 193.0, dateSampled: day2, dateImported: NSDate()),
            ImportedDataSample(value: 192.0, dateSampled: day3, dateImported: NSDate()),
            ImportedDataSample(value: 191.0, dateSampled: day4, dateImported: NSDate()),
            ImportedDataSample(value: 190.0, dateSampled: day5, dateImported: NSDate())
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
        let hkSamples :[HKQuantitySample] = healthKitSamplesFromDate(fromDate, toDate:toDate)
        
        var importedSamples = [ImportedDataSample]()
        for sample in hkSamples {
            let importedSample = ImportedDataSample(value: sample.quantity.doubleValueForUnit(HKUnit.poundUnit()), dateSampled: sample.startDate, dateImported: NSDate())
            importedSamples.append(importedSample)
        }
        
                
        callback(importedSamples)
    }
    
    func healthKitSamplesFromDate(fromDate :NSDate, toDate :NSDate) -> [HKQuantitySample] {
        var samples = [HKQuantitySample]()
        let dateRangePredicate = HKQuery.predicateForSamplesWithStartDate(fromDate, endDate: toDate, options: .None)
        let sampleQuery = HKSampleQuery(
            sampleType: HKSampleType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass), 
            predicate: dateRangePredicate, 
            limit: 1000000, 
            sortDescriptors: []
            ) { 
                (query, results, error) -> Void in
                if let quantitySamples = results as? [HKQuantitySample] {
                    samples = quantitySamples
                    
                }
                else {
                    println("error getting samples from healthkit: \(error)")
                }
        }
        return samples
    }
    
    func authorizeHealthKitAccess(callback:((success:Bool, error:NSError!) -> Void)) {
        
        if !HKHealthStore.isHealthDataAvailable() {
             let error = NSError(domain: "com.caninomnom.healthkit", code: 1, userInfo: [NSLocalizedDescriptionKey:"HealthKit data is not available"])
            callback(success: false, error: nil)
            return
        }
        
        let healthKitTypesToReadAndWrite = Set([HKQuantityTypeIdentifierBodyMass])
        healthKitStore.requestAuthorizationToShareTypes(healthKitTypesToReadAndWrite, readTypes: healthKitTypesToReadAndWrite) { (success, error) -> Void in
            callback(success: success, error: error)
        }
    }
    
}