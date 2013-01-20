//
//  CINWeightList.m
//  trendView
//
//  Created by Jonathon Rubin on 1/19/13.
//  Copyright (c) 2013 Jonathon Rubin. All rights reserved.
//

#import "CINWeightList.h"
#import "CHCSVParser.h"

@implementation CINWeightList

- (CINWeightList*) initWith:(NSString *)csvPath {
    self = [super init];
    if (self) {
        self.minWeight = @(1000);
        self.maxWeight = @(0);
        self.minDate = [NSDate dateWithTimeIntervalSinceNow:0];
        self.maxDate = [NSDate dateWithTimeIntervalSince1970:0];
        [self loadWeightsFrom:csvPath];
        NSLog(@"%@", self.list);

    }
    return self;
}

- (void) loadWeightsFrom:(NSString*)csvPath {
    NSString *path = [[NSBundle mainBundle] pathForResource:csvPath ofType:@"csv"];
    
    NSArray *rows = [NSArray arrayWithContentsOfCSVFile:path];
    
    if (rows == nil) {
        return;
    }
    
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
    NSDictionary * weightEntry = @{
        kDate : date,
        kWeight : weight,
        kTrend : trend
    };
    
    if (self.list == nil) {
        _list = [[NSMutableArray alloc] init];
    }
    [self.list addObject:weightEntry];
    
    // Update counters
    // minWeight > weightEntry[kWeight]
    // maxWeight < weightEntry[kWeight]
    // minDate > weightEntry[kDate]
    // maxDate < weightEntry[kdate]
    
    if ([self.minWeight floatValue] > [weightEntry[kWeight] floatValue]) {
        self.minWeight = weightEntry[kWeight];
    }
    if ([self.maxWeight floatValue] < [weightEntry[kWeight] floatValue]) {
        self.maxWeight = weightEntry[kWeight];
    }
    
    self.minDate = [self.minDate earlierDate:weightEntry[kDate]];
    self.maxDate = [self.maxDate laterDate:weightEntry[kDate]];
}

- (NSNumber*) calculateTrendFor:(NSNumber*)weight {
    float trend_today = 0;
    float weight_today = [weight floatValue];
    if (self.list.count == 0) {
        // Trend == weight for first date
        trend_today = weight_today;
    }
    else {
        /* Per http://www.fourmilab.ch/hackdiet/e4/pencilpaper.html
         Subtract yesterday's trend from today's weight. Write the result with a minus sign if it's negative.
         Shift the decimal place in the resulting number one place to the left. Round the number to one decimal place by dropping the second decimal and increasing the first decimal by one if the second decimal place is 5 or greater.
         Add this number to yesterday's trend number and enter in today's trend column.
         */
        
        NSDictionary * yesterday = self.list[self.list.count-1];
        float trend_yesterday = [yesterday[@"Trend"] floatValue];
        trend_today = ( (weight_today - trend_yesterday) * kScalingFactor ) + trend_yesterday;
        
        // Correct for gaps in measurement....if today's weight is more than 10 lbs +/ the prev reading, reset the trend
        float weight_delta = (fabs(trend_yesterday - weight_today));
        if (weight_delta > 10) {
            trend_today = weight_today;
        }
    }
    return [NSNumber numberWithFloat:trend_today];
}

@end
