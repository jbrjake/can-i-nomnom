//
//  CINMasterViewController.h
//  trendData
//
//  Created by Jonathon Rubin on 3/2/13.
//  Copyright (c) 2013 Jonathon Rubin. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CINDetailViewController;

#import <CoreData/CoreData.h>

@interface CINMasterViewController : UITableViewController <NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) CINDetailViewController *detailViewController;

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@end
