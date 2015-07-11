//
//  CINLogViewController.h
//  trendData
//
//  Created by Jonathon Rubin on 3/3/13.
//  Copyright (c) 2013 Jonathon Rubin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CINLogViewController : UIViewController <NSFetchedResultsControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, weak) IBOutlet UICollectionView *collectionView;

@end
