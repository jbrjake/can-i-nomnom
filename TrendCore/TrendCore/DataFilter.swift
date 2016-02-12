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

        
        return records
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
}