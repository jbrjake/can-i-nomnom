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

class TrendViewController: UIViewController {

    let viewModel = TrendViewModel()
    
    @IBOutlet weak var chartView :LineChartView?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel.modelDelegate = self
    }

    override func didReceiveMemoryWarning() {
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

    
}

extension TrendViewController :TrendViewModelDelegate {
    
    func modelDidChange() {

        
        
    }

}