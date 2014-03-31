//
//  IAGap.h
//  InfinitApplication
//
//  Created by infinit on 3/6/13.
//  Copyright (c) 2013 infinit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Gap/IAGapProtocol.h>

struct gap_State;
typedef struct gap_State gap_State;

@interface IAGap : NSObject <IAGapProtocol>

- (gap_State*)state;

@end
