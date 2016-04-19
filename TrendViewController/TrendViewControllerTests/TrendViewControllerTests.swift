//
//  TrendViewControllerTests.swift
//  TrendViewControllerTests
//
//  Created by Jonathon Rubin on 7/11/15.
//  Copyright (c) 2015 Jonathon Rubin. All rights reserved.
//

import UIKit
import XCTest
import Charts
@testable import TrendViewController
@testable import TrendViewModel

class TrendViewControllerTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testLoadingTrendView() {
        let storyboard = UIStoryboard(
            name: "TrendViewStoryboard",
            bundle: NSBundle(forClass: TrendViewController.self))
        let viewController = storyboard.instantiateInitialViewController() as! TrendViewController
        
        XCTAssertNotNil(
            viewController.view, 
            "The view controller should instantiate its main view.")      
        XCTAssertNotNil(
            viewController.chartView, 
            "The storyboard should load the chartView LineChartView")
        
        XCTAssertNotNil(
            viewController.viewModel.modelDelegate, 
            "The view controller should reach viewDidLoad(), which is when it should set the view model delegate.")
        XCTAssertTrue(
            viewController.viewModel.modelDelegate as? AnyObject === viewController, 
            "The delegate for the view model should be the view controller.")
    }
    
}
