//
//  TrendViewController.swift
//  TrendViewController
//
//  Created by Jonathon Rubin on 4/2/16.
//  Copyright © 2016 Jonathon Rubin. All rights reserved.
//

import UIKit
import Charts
import TrendViewModel

public class TrendViewController: UIViewController {

    let viewModel = TrendViewModel()
    
    @IBOutlet weak var chartView :LineChartView?
    
    override public func viewDidLoad() {
        super.viewDidLoad()

        viewModel.modelDelegate = self
        
        self.configureChartView()
    }

    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    private func configureChartView() {
        self.chartView?.delegate = self
        self.chartView?.dragEnabled = true
        self.chartView?.setScaleEnabled(true)
        self.chartView?.pinchZoomEnabled = true
        self.chartView?.drawGridBackgroundEnabled = true
        
        self.chartView?.viewPortHandler.setMaximumScaleX(2)
        self.chartView?.viewPortHandler.setMaximumScaleY(2)
    }
    
}

extension TrendViewController :TrendViewModelDelegate {
    
    public func modelDidChange() {
        var xIndex = 0
        let yData = self.viewModel.yValues.map { (sample) -> ChartDataEntry in
            let entry = ChartDataEntry(value: sample, xIndex: xIndex)
            xIndex += 1
            return entry
            
        }
        let yDataSet = LineChartDataSet(yVals: yData, label:nil)
        let data = LineChartData(xVals: self.viewModel.xValues, dataSets: [yDataSet])
        
        chartView?.data = data
        
    }

}

extension TrendViewController :ChartViewDelegate {
    
}