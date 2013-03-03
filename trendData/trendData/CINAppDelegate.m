//
//  CINAppDelegate.m
//  trendData
//
//  Created by Jonathon Rubin on 3/2/13.
//  Copyright (c) 2013 Jonathon Rubin. All rights reserved.
//

#import "CINAppDelegate.h"

#import "CINMasterViewController.h"

@implementation CINAppDelegate

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
        UINavigationController *navigationController = [splitViewController.viewControllers lastObject];
        splitViewController.delegate = (id)navigationController.topViewController;
        
        UINavigationController *masterNavigationController = splitViewController.viewControllers[0];
        CINMasterViewController *controller = (CINMasterViewController *)masterNavigationController.topViewController;
        controller.managedObjectContext = self.managedObjectContext;
    } else {
        UINavigationController *navigationController = (UINavigationController *)self.window.rootViewController;
        CINMasterViewController *controller = (CINMasterViewController *)navigationController.topViewController;
        controller.managedObjectContext = self.managedObjectContext;
    }
    
    // See if we need to restore test data
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:@"Weight" inManagedObjectContext:self.managedObjectContext]];
    [request setIncludesSubentities:NO]; //Omit subentities. Default is YES (i.e. include subentities)
    
    NSError *err;
    NSUInteger count = [self.managedObjectContext countForFetchRequest:request error:&err];
    if(count == 0) {
        // We need to restore test data
        [self loadWeightsFrom:@"weightbot_data"];
    }
    
    return YES;
}

-(void) loadWeightsFrom:(NSString*)csvPath {
    NSString *path = [[NSBundle mainBundle] pathForResource:csvPath ofType:@"csv"];
    
    NSArray *rows = [NSArray arrayWithContentsOfCSVFile:path];
    
    if (rows == nil) {
        return;
    }
    
    // For now limit to this year's dates
    NSMutableArray * mutableRows = [rows mutableCopy];
    [mutableRows removeObjectsInRange:NSRangeFromString(@"0, 159")];
    rows = mutableRows;
    
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"yyyy-MM-dd"];
    BOOL headerRow = TRUE;
    for (NSArray * row in rows) {
        if (headerRow == TRUE) {
            headerRow = FALSE;
            continue;
        }
        
        if (row.count != 3) {
            continue;
        }
        
        NSDate * date = [df dateFromString:row[0]];
        float weight = [row[2] floatValue];
        NSNumber * theWeight = [NSNumber numberWithFloat:weight];
        
        [self log:theWeight for:date];
    }

}

- (void) log:(NSNumber*)weight for:(NSDate*)date {

    NSNumber * trend = [self calculateTrendFor:weight];
    NSManagedObject *newWeight = [NSEntityDescription insertNewObjectForEntityForName:@"Weight"
                                                               inManagedObjectContext:self.managedObjectContext];
    [newWeight setValue:weight forKey:@"actual"];
    [newWeight setValue:trend forKey:@"trend"];
    [newWeight setValue:date forKey:@"date"];
    // Save the context
    if (![self.managedObjectContext save:nil])
    {
        // error checking
    }
}

- (NSNumber*) calculateTrendFor:(NSNumber*)weight {
    float trend_today = 0;
    float weight_today = [weight floatValue];
    // See if we need to restore test data
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    request.fetchLimit = 1;
    [request setEntity:[NSEntityDescription entityForName:@"Weight" inManagedObjectContext:self.managedObjectContext]];
    [request setIncludesSubentities:NO]; //Omit subentities. Default is YES (i.e. include subentities)
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO]; // ascending YES = start with earliest date
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    [request setSortDescriptors:sortDescriptors];
    NSError *err;
    NSArray *results = [self.managedObjectContext executeFetchRequest:request error:&err];

    if (results.count == 0) {
        // Trend == weight for first date
        trend_today = weight_today;
    }
    else {
        /* Per http://www.fourmilab.ch/hackdiet/e4/pencilpaper.html
         Subtract yesterday's trend from today's weight. Write the result with a minus sign if it's negative.
         Shift the decimal place in the resulting number one place to the left. Round the number to one decimal place by dropping the second decimal and increasing the first decimal by one if the second decimal place is 5 or greater.
         Add this number to yesterday's trend number and enter in today's trend column.
         */
        
        NSManagedObject * result = results[0];
        float trend_yesterday = [[result valueForKey:@"trend"] floatValue];
        
        trend_today = ( (weight_today - trend_yesterday) * 0.10 ) + trend_yesterday;
        
        // Correct for gaps in measurement....if today's weight is more than 10 lbs +/ the prev reading, reset the trend
        float weight_delta = (fabs(trend_yesterday - weight_today));
        if (weight_delta > 10) {
            trend_today = weight_today;
        }
    }
    return [NSNumber numberWithFloat:trend_today];
}


- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
             // Replace this implementation with code to handle the error appropriately.
             // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        } 
    }
}

#pragma mark - Core Data stack

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"trendData" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"trendData.sqlite"];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }    
    
    return _persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
