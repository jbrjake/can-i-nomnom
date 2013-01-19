//
//  CINWeightList.h
//  trendView
//
//  Created by Jonathon Rubin on 1/19/13.
//  Copyright (c) 2013 Jonathon Rubin. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kTrend @"Trend"
#define kWeight @"Weight"
#define kDate @"Date"

#define kScalingFactor 0.10

@interface CINWeightList : NSObject

@property NSMutableArray* list;

- (void) log:(NSNumber*)weight for:(NSDate*)date;

@end
