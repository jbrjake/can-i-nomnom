//
//  TrendCoreController.swift
//  TrendCore
//
//  Created by Jonathon Rubin on 7/11/15.
//  Copyright (c) 2015 Jonathon Rubin. All rights reserved.
//

import Foundation

public typealias Completion = ( (NSError?) -> () )
public typealias FetchWeightsCallback = ( ([DataSample]) -> () )

public class TrendCoreController :NSObject {

    public func importDataFrom (
        importerType: TrendCoreImporterType, 
            fromDate: NSDate, 
              toDate: NSDate, 
          completion: Completion ) 
    {
        DataImporterFactory
        .importerForType(.Dummy)
        .samplesForRangeFromDate(fromDate, toDate: toDate) 
        { 
            (importedSamples) -> () in
            
            // Do stuff here to import data
            completion(nil)
        }
    }
    
    public func fetchWeightsFrom (
        fromDate: NSDate, 
          toDate: NSDate, 
        callback: FetchWeightsCallback ) 
    {
        
        
    }
    
}