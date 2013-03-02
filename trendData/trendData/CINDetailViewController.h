//
//  CINDetailViewController.h
//  trendData
//
//  Created by Jonathon Rubin on 3/2/13.
//  Copyright (c) 2013 Jonathon Rubin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CINDetailViewController : UIViewController <UISplitViewControllerDelegate>

@property (strong, nonatomic) id detailItem;

@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;
@end
