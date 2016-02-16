//
//  TrendCoreController.swift
//  TrendCore
//
//  Created by Jonathon Rubin on 7/11/15.
//  Copyright (c) 2015 Jonathon Rubin. All rights reserved.
//

import Foundation
import PromiseKit

public typealias Completion = ( (NSError?) -> () )
public typealias FetchWeightsCallback = ( ([DataSample]) -> () )

public class TrendCoreController {

    internal let dataStore   :DataStoreProtocol  = DataStore()
    internal let dataFilter  :DataFilterProtocol = TrendFilter()
    
    public init() {}
    
    public func importDataFrom (
        importerType: TrendCoreImporterType, 
        fromDate: NSDate, 
        toDate: NSDate ) -> Promise< () >
    {
        return Promise< () >( resolvers: { (fulfill, reject) -> Void in
            DataImporterFactory
            .importerForType(.Dummy)
            .samplesForRangeFromDate(fromDate, toDate: toDate) 
            { (importedSamples) -> () in
                
                firstly{
                    self.dataStore.add(importedSamples)
                }
                .then {    
                    fulfill()
                }
                .error { err in
                    reject(err)
                }
                
            }
        })
    }

    public func fetchWeightsFrom (
        fromDate: NSDate, 
        toDate: NSDate ) -> Promise< [DataSample] >
    {
        return Promise< [DataSample] >(resolvers: { (fulfill, reject) -> Void in
            firstly {
                self.dataStore.fetch(fromDate, toDate: toDate)
            }
            .then { results in
                self.dataFilter.filter(results, callback: { (filteredResults) -> () in
                    fulfill(filteredResults)
                })
            }
        })
    }
    
}