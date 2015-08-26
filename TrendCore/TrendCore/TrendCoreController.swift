//
//  TrendCoreController.swift
//  TrendCore
//
//  Created by Jonathon Rubin on 7/11/15.
//  Copyright (c) 2015 Jonathon Rubin. All rights reserved.
//

import Foundation

public struct DataSample {
    var value :Double
    var dateSampled :NSDate
    var dateImported :NSDate
}

public typealias Completion = ( (NSError?) -> () )
public typealias FetchWeightsCallback = ( ([DataSample]) -> () )

public class TrendCoreController :NSObject {

    public func importDataFrom(importerType: TrendCoreImporterType, completion: Completion ) {
        
    }
    
    public func fetchWeights(fromDate :NSDate, toDate :NSDate, callback: FetchWeightsCallback) {
        
        
    }
    
}