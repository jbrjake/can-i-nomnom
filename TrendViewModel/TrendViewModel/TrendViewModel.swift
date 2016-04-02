//
//  TrendViewModel.swift
//  TrendViewModel
//
//  Created by Jonathon Rubin on 2/20/16.
//  Copyright © 2016 Jonathon Rubin. All rights reserved.
//

import Foundation
import TrendCore

public protocol TrendViewModelDelegate {
    func modelDidChange()
}

public class TrendViewModel {
    
    private let core = TrendCoreController()
        
    public var startDate = NSDate.distantPast() {
        didSet { refreshData() }
    }
    public var endDate = NSDate.distantFuture() {
        didSet { refreshData() }
    }
    
    private(set) public var xValues = [NSDate]()
    private(set) public var yValues = [Double]()
    
    
    public var modelDelegate :TrendViewModelDelegate?
    private func refreshData() {
        core.fetchWeightsFrom(startDate, toDate: endDate)
        .then { records -> Void in
            self.xValues = records.map({ (sample) -> NSDate in
                return sample.dateSampled
            })
            self.yValues = records.map({ (sample) -> Double in
                return sample.trend ?? Double(0)
            })
            
            self.modelDelegate?.modelDidChange()
        }
    }
}