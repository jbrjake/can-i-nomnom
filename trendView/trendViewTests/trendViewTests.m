//
//  trendViewTests.m
//  trendViewTests
//
//  Created by Jonathon Rubin on 1/16/13.
//  Copyright (c) 2013 Jonathon Rubin. All rights reserved.
//

#import "trendViewTests.h"
#import "CHCSVParser.h"
#import "CINWeightList.h"

@implementation trendViewTests

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

/* Tests that a sample .csv file can successfully be read */
- (void)testCSVParser
{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"weightbot_data" ofType:@"csv"];
    
    NSArray *rows = [NSArray arrayWithContentsOfCSVFile:path];
    
    STAssertNotNil(rows, @"Error parsing file.");
    
    // For thoroughness, let's check 3 dates -- the first, the middle, and the last.

    // 2012-01-01, 87.3, 192.5
    NSArray * firstRow = rows[1]; // Index 0 is the column headers
    STAssertTrue([firstRow[0] isEqualToString:@"2012-01-01"], @"Row 1's date is %@, not 2012-01-01", firstRow[0]);
    STAssertTrue([firstRow[1] isEqualToString:@"87.3"], @"Row 1's kilos is %@, not 87.3", firstRow[1]);
    STAssertTrue([firstRow[2] isEqualToString:@"192.5"], @"Row 1's pounds is %@, not 192.5", firstRow[2]);
    
    // 2012-03-28, 78.0, 172.0
    NSArray * middleRow = rows[88];
    STAssertTrue([middleRow[0] isEqualToString:@"2012-03-28"], @"Row 89's date is %@, not 2012-03-28", middleRow[0]);
    STAssertTrue([middleRow[1] isEqualToString:@"78.0"], @"Row 2's kilos is %@, not 78.0", middleRow[1]);
    STAssertTrue([middleRow[2] isEqualToString:@"172.0"], @"Row 2's pounds is %@, not 172.0", middleRow[2]);
    
    // 2013-01-19, 94.1, 207.4
    NSArray * lastRow = rows[178];
    STAssertTrue([lastRow[0] isEqualToString:@"2013-01-19"], @"Row 178's date is %@, not 2013-01-19", lastRow[0]);
    STAssertTrue([lastRow[1] isEqualToString:@"94.1"], @"Row 178's kilos is %@, not 94.1", lastRow[1]);
    STAssertTrue([lastRow[2] isEqualToString:@"207.4"], @"Row 178's pounds is %@, not 207.4", lastRow[2]);
}

-(void)testWeightList {
    CINWeightList * list = [[CINWeightList alloc] initWith:@"weightbot_data"];
    
    NSLog(@"%@", list.list);
    STAssertTrue(list.list.count == 178, @"The list only has %i rows while the file has %i", list.list.count, 178);
}

@end
