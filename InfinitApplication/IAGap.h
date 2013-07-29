//
//  IAGap.h
//  InfinitApplication
//
//  Created by infinit on 3/6/13.
//  Copyright (c) 2013 infinit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Gap/IAGapProtocol.h>

@interface IAGap : NSObject <IAGapProtocol>

- (gap_State*)state;

@end
