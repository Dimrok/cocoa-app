//
//  IAGapMetrics.h
//  InfinitApplication
//
//  Created by Christopher Crone on 5/31/13.
//  Copyright (c) 2013 infinit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Gap/IAGapMetricsProtocol.h>

@interface IAGapMetrics : NSObject <IAGapMetricsProtocol>

- (id)initWithState:(gap_State*)state;

@end
