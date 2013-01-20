//
//  CINScatterViewController.h
//  trendView
//
//  Created by Jonathon Rubin on 1/19/13.
//  Copyright (c) 2013 Jonathon Rubin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CorePlot-CocoaTouch.h"
#import "CINWeightList.h"

@interface CINScatterViewController : UIViewController <CPTPlotDataSource>

@property (nonatomic, strong) CPTGraphHostingView *hostView;
@property CINWeightList * weightList;

@end
