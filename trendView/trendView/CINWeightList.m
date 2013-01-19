//
//  CINWeightList.m
//  trendView
//
//  Created by Jonathon Rubin on 1/19/13.
//  Copyright (c) 2013 Jonathon Rubin. All rights reserved.
//

#import "CINWeightList.h"

@implementation CINWeightList

- (void) log:(NSNumber*)weight for:(NSDate*)date {

    NSNumber * trend = [self calculateTrendFor:weight];
    NSDictionary * weightEntry = @{
        kDate : date,
        kWeight : weight,
        kTrend : trend
    };
    [self addObject:weightEntry];
}

- (NSNumber*) calculateTrendFor:(NSNumber*)weight {
    float trend_today = 0;
    float weight_today = [weight floatValue];
    if (self.count == 0) {
        // Trend == weight for first date
        trend_today = weight_today;
    }
    else {
        /* Per http://www.fourmilab.ch/hackdiet/e4/pencilpaper.html
         Subtract yesterday's trend from today's weight. Write the result with a minus sign if it's negative.
         Shift the decimal place in the resulting number one place to the left. Round the number to one decimal place by dropping the second decimal and increasing the first decimal by one if the second decimal place is 5 or greater.
         Add this number to yesterday's trend number and enter in today's trend column.
         */
        
        NSDictionary * yesterday = self[self.count-1];
        float trend_yesterday = [yesterday[@"Trend"] floatValue];
        trend_today = ( (weight_today - trend_yesterday) * kScalingFactor ) + trend_yesterday;
    }
    return [NSNumber numberWithFloat:trend_today];
}

@end
