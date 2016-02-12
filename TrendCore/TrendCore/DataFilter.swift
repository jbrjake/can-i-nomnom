//
//  DataFilter.swift
//  TrendCore
//
//  Created by Jonathon Rubin on 9/2/15.
//  Copyright © 2015 Jonathon Rubin. All rights reserved.
//

import Foundation

internal protocol DataFilterProtocol {
    func filter(dataStore :DataStore, callback :FilterCallback)
}

internal typealias FilterCallback = ([DataSample]) -> ()
internal class FilterController :DataFilterProtocol {
    
    internal func filter(dataStore :DataStore, callback :FilterCallback) {
        
        dataStore.fetch(NSDate.distantPast(), toDate: NSDate.distantFuture(), callback: { (records) -> () in
            var newRecords :[DataSample]? = nil
            for filterLayer in self.filters {
                self.pipeline.addOperationWithBlock({ () -> Void in
                    newRecords = filterLayer(newRecords ?? records)
                })
            }
            self.pipeline.waitUntilAllOperationsAreFinished()
            callback(newRecords ?? [DataSample]() )
        })

    }

    private let pipeline :NSOperationQueue = {
        let pipeline = NSOperationQueue()
        pipeline.name = "TrendCore.DataFilter Pipeline"
        pipeline.maxConcurrentOperationCount = 1
        return pipeline
    }()
    
    private typealias FilterLayer = (([DataSample]) -> [DataSample])
    private var filters = [FilterLayer]()
    
}

internal class TrendFilter :FilterController {

    override init() {
        super.init()
        self.filters.append(self.dateInterpolator)
        self.filters.append(self.weightTrender)
    }

    private let dateInterpolator :FilterLayer = {
        records in

        var lastSample :DataSample? = nil
        var currentSample :DataSample? = nil
        var newRecords = [DataSample]()
        
        for record in records {
            currentSample = record
            
            // Get calendar days since last sample
            var calendarDays = 0
            if let lastSample = lastSample, currentSample = currentSample {
                calendarDays = lastSample.dateSampled.numberOfDaysUntilDateTime(currentSample.dateSampled)
                if calendarDays > 1 {
                    
                    var diff = currentSample.value - lastSample.value
                    diff = diff / Double(calendarDays)
                    var newWeight = lastSample.value + diff
                    
                    // for each day, we need to make a new day adding on a spread between dates
                    let components = NSDateComponents()
                    components.day = 1
                    
                    for day in 1...calendarDays-1 {
                        components.day = day
                        if let 
                            newDate = NSCalendar.currentCalendar().dateByAddingComponents(components, toDate: lastSample.dateSampled, options: [])
                        {

                            let newSample = DataSample (
                                value: newWeight, 
                                trend: nil, 
                                dateSampled: newDate, 
                                dateImported: NSDate(), 
                                source:.Dummy )
                            newRecords.append(newSample)
                        }
                        newWeight += diff
                    }                    
                }
            }
            
            if let currentSample = currentSample {
                newRecords.append(currentSample)
            }
            
            lastSample = currentSample
        }
        
        return newRecords
    }
    
    private let weightTrender :FilterLayer = {
        records in
        
        var lastSample :DataSample? = nil
        var currentSample :DataSample? = nil
        var isFirst = true
        var newRecords = [DataSample]()
        
        for sample in records {
            currentSample = sample
            
            if isFirst == true {
                currentSample?.trend = currentSample?.value
                lastSample = currentSample
                if let currentSample = currentSample {
                    newRecords.append(currentSample)
                }
                isFirst = false
                continue
            }
            else {
                var newTrend = currentSample?.value
                if let lastSample = lastSample, currentSample = currentSample, lastTrend = lastSample.trend {
                    var diff = currentSample.value - lastTrend
                    diff = diff / Double(10)
                    newTrend = lastTrend + diff                    
                }
                currentSample?.trend = newTrend
            }
            
            if let currentSample = currentSample {
                newRecords.append(currentSample)
            }
            lastSample = currentSample
        }

        return newRecords
    }
    
}

// http://stackoverflow.com/a/4739650
extension NSDate {
    func numberOfDaysUntilDateTime(toDateTime: NSDate, inTimeZone timeZone: NSTimeZone? = nil) -> Int {
        let calendar = NSCalendar.currentCalendar()
        if let timeZone = timeZone {
            calendar.timeZone = timeZone
        }
        
        var fromDate: NSDate?, toDate: NSDate?
        
        calendar.rangeOfUnit(.Day, startDate: &fromDate, interval: nil, forDate: self)
        calendar.rangeOfUnit(.Day, startDate: &toDate, interval: nil, forDate: toDateTime)
        
        let difference = calendar.components(.Day, fromDate: fromDate!, toDate: toDate!, options: [])
        return difference.day
    }
}