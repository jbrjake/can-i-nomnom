//
//  DataFilter.swift
//  TrendCore
//
//  Created by Jonathon Rubin on 9/2/15.
//  Copyright © 2015 Jonathon Rubin. All rights reserved.
//

import Foundation

internal protocol DataFilterProtocol {
    func filter(dataStore :DataStore, callback :Completion)
}

internal class FilterController :DataFilterProtocol {
    
    internal func filter(dataStore :DataStore, callback :Completion) {
        for filter in self.filters {
            self.pipeline.addOperationWithBlock({ () -> Void in
                let semaphore = dispatch_semaphore_create(0)
                filter(dataStore) {
                    err in 
                    dispatch_semaphore_signal(semaphore)
                }
                dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
            })
        }
        pipeline.waitUntilAllOperationsAreFinished()
        callback(nil)
    }

    private let pipeline :NSOperationQueue = {
        let pipeline = NSOperationQueue()
        pipeline.name = "TrendCore.DataFilter Pipeline"
        pipeline.maxConcurrentOperationCount = 1
        return pipeline
    }()
    
    private typealias FilterLayer = ( (DataStore, Completion) -> () )
    private var filters = [FilterLayer]()
    
}

internal class TrendFilter :FilterController {

    override init() {
        super.init()
        self.filters.append(self.dateInterpolator)
        self.filters.append(self.weightTrender)
    }

    private let dateInterpolator :FilterLayer = {
        dataStore, completion in
        
        
        completion(nil)
    }
    
    private let dummySweeper :FilterLayer = {
        dataStore, completion in
        
        completion(nil)
    }
    
    private let weightTrender :FilterLayer = {
        dataStore, completion in
        
        completion(nil)
    }

}