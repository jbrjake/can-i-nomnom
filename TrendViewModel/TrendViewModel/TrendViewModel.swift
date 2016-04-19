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
    
    private(set) public var xValues = [String]()
    private(set) public var yValues = [Double]()
    
    private lazy var dateFormatter :NSDateFormatter =  { 
        var formatter = NSDateFormatter()
        formatter.dateStyle = .ShortStyle
        return formatter
    }()
    
    public init() {}
    
    public var modelDelegate :TrendViewModelDelegate?
    private func refreshData() {
        core.fetchWeightsFrom(startDate, toDate: endDate)
        .then { records -> Void in
            self.xValues = records.map({ (sample) -> String in
                return self.dateFormatter.stringFromDate(sample.dateSampled)
            })
            self.yValues = records.map({ (sample) -> Double in
                return sample.trend ?? Double(0)
            })
            
            self.modelDelegate?.modelDidChange()
        }
    }
}