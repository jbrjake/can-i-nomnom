//
//  CINScatterViewController.m
//  trendView
//
//  Created by Jonathon Rubin on 1/19/13.
//  Copyright (c) 2013 Jonathon Rubin. All rights reserved.
//

#import "CINScatterViewController.h"

#define kMaxXAxisLabels 7
#define kMaxYAxisLabels 4

@interface CINScatterViewController ()

@end

@implementation CINScatterViewController

#pragma mark - UIViewController lifecycle methods
-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    _weightList = [[CINWeightList alloc] initWith:@"weightbot_data"];
    [self initPlot];
}

#pragma mark - Chart behavior
-(void)initPlot {
    [self configureHost];
    [self configureGraph];
    [self configurePlots];
    [self configureAxes];
}

-(void)configureHost {
    self.hostView = [(CPTGraphHostingView *) [CPTGraphHostingView alloc] initWithFrame:self.view.bounds];
    self.hostView.allowPinchScaling = YES;
    [self.view addSubview:self.hostView];
}

-(void)configureGraph {
    // 1 - Create the graph
    CPTGraph *graph = [[CPTXYGraph alloc] initWithFrame:self.hostView.bounds];
    [graph applyTheme:[CPTTheme themeNamed:kCPTDarkGradientTheme]];
    self.hostView.hostedGraph = graph;
    // 2 - Set graph title
    NSString *title = @"Weight";
    graph.title = title;
    // 3 - Create and set text style
    CPTMutableTextStyle *titleStyle = [CPTMutableTextStyle textStyle];
    titleStyle.color = [CPTColor whiteColor];
    titleStyle.fontName = @"Helvetica-Bold";
    titleStyle.fontSize = 16.0f;
    graph.titleTextStyle = titleStyle;
    graph.titlePlotAreaFrameAnchor = CPTRectAnchorTop;
    graph.titleDisplacement = CGPointMake(0.0f, 10.0f);
    // 4 - Set padding for plot area
    [graph.plotAreaFrame setPaddingLeft:30.0f];
    [graph.plotAreaFrame setPaddingBottom:30.0f];
    // 5 - Enable user interactions for plot space
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *) graph.defaultPlotSpace;
    plotSpace.allowsUserInteraction = YES;
    plotSpace.delegate = self;
}

-(void)configurePlots {
    // 1 - Get graph and plot space
    CPTGraph *graph = self.hostView.hostedGraph;
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *) graph.defaultPlotSpace;
    CPTScatterPlot *weightPlot = [[CPTScatterPlot alloc] init];
    weightPlot.dataSource = self;
    weightPlot.identifier = @"Weight";
    CPTColor *weightColor = [CPTColor redColor];
    [graph addPlot:weightPlot toPlotSpace:plotSpace];

    CPTScatterPlot *trendPlot = [[CPTScatterPlot alloc] init];
    trendPlot.dataSource = self;
    trendPlot.identifier = @"Trend";
    CPTColor *trendColor = [CPTColor blueColor];
    [graph addPlot:trendPlot toPlotSpace:plotSpace];

    // 3 - Set up plot space
    [plotSpace scaleToFitPlots:[NSArray arrayWithObjects:weightPlot, trendPlot, nil]];
    CPTMutablePlotRange *xRange = [plotSpace.xRange mutableCopy];
    [xRange expandRangeByFactor:CPTDecimalFromCGFloat(1.1f)];
    plotSpace.xRange = xRange;
    plotSpace.globalXRange = xRange;
    CPTMutablePlotRange *yRange = [plotSpace.yRange mutableCopy];
    float minWeight = self.weightList.minWeight.floatValue;
    float maxWeight = self.weightList.maxWeight.floatValue;
    yRange.location = CPTDecimalFromFloat(minWeight-5);
    yRange.length = CPTDecimalFromFloat(maxWeight-minWeight + 5);
    [yRange expandRangeByFactor:CPTDecimalFromCGFloat(1.2f)];
    plotSpace.yRange = yRange;
    plotSpace.globalYRange = yRange;
    // 4 - Create styles and symbols
    CPTMutableLineStyle *weightLineStyle = [weightPlot.dataLineStyle mutableCopy];
    weightLineStyle.lineWidth = 2.5;
    weightLineStyle.lineColor = weightColor;
    weightPlot.dataLineStyle = weightLineStyle;
    CPTMutableLineStyle *weightSymbolLineStyle = [CPTMutableLineStyle lineStyle];
    weightSymbolLineStyle.lineColor = weightColor;
    CPTPlotSymbol *weightSymbol = [CPTPlotSymbol ellipsePlotSymbol];
    weightSymbol.fill = [CPTFill fillWithColor:weightColor];
    weightSymbol.lineStyle = weightSymbolLineStyle;
    weightSymbol.size = CGSizeMake(6.0f, 6.0f);
    weightPlot.plotSymbol = weightSymbol;

    CPTMutableLineStyle *trendLineStyle = [trendPlot.dataLineStyle mutableCopy];
    trendLineStyle.lineWidth = 2.5;
    trendLineStyle.lineColor = trendColor;
    trendPlot.dataLineStyle = trendLineStyle;
    weightSymbolLineStyle.lineColor = trendColor;
    weightSymbol.fill = [CPTFill fillWithColor:trendColor];
    weightSymbol.lineStyle = weightSymbolLineStyle;
    weightSymbol.size = CGSizeMake(6.0f, 6.0f);
    trendPlot.plotSymbol = weightSymbol;
    trendPlot.interpolation = CPTScatterPlotInterpolationCurved;

}

-(void)configureAxes {
    // 1 - Create styles
    CPTMutableTextStyle *axisTitleStyle = [CPTMutableTextStyle textStyle];
    axisTitleStyle.color = [CPTColor whiteColor];
    axisTitleStyle.fontName = @"Helvetica-Bold";
    axisTitleStyle.fontSize = 12.0f;
    CPTMutableLineStyle *axisLineStyle = [CPTMutableLineStyle lineStyle];
    axisLineStyle.lineWidth = 2.0f;
    axisLineStyle.lineColor = [CPTColor whiteColor];
    CPTMutableTextStyle *axisTextStyle = [[CPTMutableTextStyle alloc] init];
    axisTextStyle.color = [CPTColor whiteColor];
    axisTextStyle.fontName = @"Helvetica-Bold";
    axisTextStyle.fontSize = 11.0f;
    CPTMutableLineStyle *tickLineStyle = [CPTMutableLineStyle lineStyle];
    tickLineStyle.lineColor = [CPTColor whiteColor];
    tickLineStyle.lineWidth = 2.0f;
    CPTMutableLineStyle *gridLineStyle = [CPTMutableLineStyle lineStyle];
    tickLineStyle.lineColor = [CPTColor blackColor];
    tickLineStyle.lineWidth = 1.0f;
    // 2 - Get axis set
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *) self.hostView.hostedGraph.axisSet;
    // 3 - Configure x-axis
    CPTXYAxis *x = axisSet.xAxis;
    x.title = @"Date";
    x.titleTextStyle = axisTitleStyle;
    x.titleOffset = 15.0f;
    x.axisLineStyle = axisLineStyle;
    x.labelingPolicy = CPTAxisLabelingPolicyNone;
    x.labelTextStyle = axisTextStyle;
    x.majorTickLineStyle = axisLineStyle;
    x.majorTickLength = 4.0f;
    x.tickDirection = CPTSignNegative;
    CGFloat dateCount = self.weightList.list.count;
    NSMutableSet *xLabels = [NSMutableSet setWithCapacity:dateCount];
    NSMutableSet *xLocations = [NSMutableSet setWithCapacity:dateCount];
    NSInteger i = 0;
    for (NSDictionary *entry in self.weightList.list) {
        NSDateFormatter * df = [[NSDateFormatter alloc] init];
        df.dateFormat = @"MM/dd/yy";
        NSString * date = [df stringFromDate:entry[@"Date"]];
        CPTAxisLabel *label = [[CPTAxisLabel alloc] initWithText:date  textStyle:x.labelTextStyle];
        CGFloat location = i++;
        if (fmodf(location, 2)) {
            continue;
        }
        
        label.tickLocation = CPTDecimalFromCGFloat(location);
        label.offset = x.majorTickLength;
        if (label) {
            [xLabels addObject:label];
            [xLocations addObject:[NSNumber numberWithFloat:location]];
        }
    }
    x.axisLabels = xLabels;
    x.majorTickLocations = xLocations;
    x.axisConstraints = [CPTConstraints constraintWithLowerOffset:10.0];

    // 4 - Configure y-axis
    CPTXYAxis *y = axisSet.yAxis;
    y.title = @"Weight";
    y.titleTextStyle = axisTitleStyle;
    y.titleOffset = -40.0f;
    y.axisLineStyle = axisLineStyle;
    y.majorGridLineStyle = gridLineStyle;
    y.labelingPolicy = CPTAxisLabelingPolicyNone;
    y.labelTextStyle = axisTextStyle;
    y.labelOffset = 16.0f;
    y.majorTickLineStyle = axisLineStyle;
    y.majorTickLength = 4.0f;
    y.minorTickLength = 2.0f;
    y.tickDirection = CPTSignPositive;
    NSInteger majorIncrement = 5;
    NSInteger minorIncrement = 1;
    CGFloat yMax = 220;  // should determine dynamically based on max price
    NSMutableSet *yLabels = [NSMutableSet set];
    NSMutableSet *yMajorLocations = [NSMutableSet set];
    NSMutableSet *yMinorLocations = [NSMutableSet set];
    for (NSInteger j = 100; j <= yMax; j += minorIncrement) {
        NSUInteger mod = j % majorIncrement;
        if (mod == 0) {
            CPTAxisLabel *label = [[CPTAxisLabel alloc] initWithText:[NSString stringWithFormat:@"%i", j] textStyle:y.labelTextStyle];
            NSDecimal location = CPTDecimalFromInteger(j);
            label.tickLocation = location;
            label.offset = -y.majorTickLength - y.labelOffset;
            if (label) {
                [yLabels addObject:label];
            }
            [yMajorLocations addObject:[NSDecimalNumber decimalNumberWithDecimal:location]];
        } else {
            [yMinorLocations addObject:[NSDecimalNumber decimalNumberWithDecimal:CPTDecimalFromInteger(j)]];
        }
    }
    y.axisLabels = yLabels;    
    y.majorTickLocations = yMajorLocations;
    y.minorTickLocations = yMinorLocations;
    y.axisConstraints = [CPTConstraints constraintWithLowerOffset:30.0];

    

}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationLandscapeLeft);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - CPTPlotDataSource methods
-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot {
    return self.weightList.list.count;
}

-(NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index {
    NSInteger valueCount = self.weightList.list.count;
    NSNumber * ret = [NSDecimalNumber zero];
    switch (fieldEnum) {
        case CPTScatterPlotFieldX:
            if (index < valueCount) {
                ret = [NSNumber numberWithUnsignedInteger:index];
            }
            break;
            
        case CPTScatterPlotFieldY:
            if ([plot.identifier isEqual:@"Weight"] == YES) {
                NSLog(@"%@", self.weightList.list[index][@"Weight"]);
                ret = self.weightList.list[index][@"Weight"];
            }
            else if ([plot.identifier isEqual:@"Trend"] == YES) {
                NSLog(@"%@", self.weightList.list[index][@"Trend"]);
                ret = self.weightList.list[index][@"Trend"];
            }
            break;
    }
    return ret;
}

#pragma mark Plot Space Delegate

- (CPTPlotRange *) plotSpace:   (CPTPlotSpace *) space
       willChangePlotRangeTo:   (CPTPlotRange *) newRange
               forCoordinate:   (CPTCoordinate)  coordinate {
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *) self.hostView.hostedGraph.axisSet;
    CPTXYAxis *x = axisSet.xAxis;
    CPTXYAxis *y = axisSet.yAxis;
    if (coordinate == CPTCoordinateX) {
        uint dateCount = 0;
        uint dateStartIndex = 0;
        NSMutableSet *xLabels = [NSMutableSet setWithCapacity:dateCount];
        NSMutableSet *xLocations = [NSMutableSet setWithCapacity:dateCount];
        double start = newRange.minLimitDouble;
        double end = newRange.maxLimitDouble;
        start = start < 0 ? 0 : start;
        end = end > self.weightList.list.count ? self.weightList.list.count : end;
        dateCount = end - start;
        dateStartIndex = start;
        NSInteger i = 0;
        NSDateFormatter * df = [[NSDateFormatter alloc] init];
        df.dateFormat = @"MM/dd/yy";
        
        
        for( i=dateStartIndex; i < end; i++){
            int entryIndex = i;
            NSDictionary * entry = self.weightList.list[entryIndex];
            NSString * date = [df stringFromDate:entry[@"Date"]];
            CPTAxisLabel *label = [[CPTAxisLabel alloc] initWithText:date  textStyle:x.labelTextStyle];
            CGFloat location = entryIndex;
            
            if (dateCount > kMaxXAxisLabels) {
                // Display up to 7 sequential dates
                if (fmodf(location, 2)) {
                    // Otherwise always advance 2
                    continue;
                }
            }
            label.tickLocation = CPTDecimalFromCGFloat(location);
            label.offset = x.majorTickLength;
            if (label) {
                [xLabels addObject:label];
                [xLocations addObject:[NSNumber numberWithFloat:location]];
            }
        }
        
        x.axisLabels = xLabels;
        x.majorTickLocations = xLocations;
    }
    else if (coordinate == CPTCoordinateY) {
        uint weightCount = 0;
        uint weightStartIndex = 0;
        NSMutableSet *yLabels = [NSMutableSet setWithCapacity:weightCount];
        NSMutableSet *yLocations = [NSMutableSet setWithCapacity:weightCount];
        double start = newRange.minLimitDouble;
        double end = newRange.maxLimitDouble;
        start = start < 0 ? 0 : start;
        weightCount = end - start;
        weightStartIndex = start;
        NSInteger i = 0;
        
        for( i=weightStartIndex; i < end; i++){
            int entryIndex = i;
            NSString * weight = [@(i) stringValue];
            CPTAxisLabel *label = [[CPTAxisLabel alloc] initWithText:weight  textStyle:x.labelTextStyle];
            CGFloat location = entryIndex;
            
            if (weightCount > kMaxYAxisLabels) {
                // Display up to 4 sequential weights
                if (fmodf(location, 2)) {
                    // Otherwise always advance 2
                    continue;
                }
            }

            label.tickLocation = CPTDecimalFromCGFloat(location);
            label.offset = x.majorTickLength;
            if (label) {
                [yLabels addObject:label];
                [yLocations addObject:[NSNumber numberWithFloat:location]];
            }
        }
        
        y.axisLabels = yLabels;
        y.majorTickLocations = yLocations;
    }
    
    return newRange;
}


@end
