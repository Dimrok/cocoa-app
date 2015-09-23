//
//  InfinitUsageBar.h
//  InfinitApplication
//
//  Created by Christopher Crone on 18/08/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol InfinitUsageBarProtocol;

@interface InfinitUsageBar : NSProgressIndicator

@property (nonatomic, readwrite, unsafe_unretained) id<InfinitUsageBarProtocol> delegate;

@end

@protocol InfinitUsageBarProtocol <NSObject>

- (void)mouseEnteredUsageBar:(InfinitUsageBar*)sender;
- (void)mouseExitedUsageBar:(InfinitUsageBar*)sender;
- (void)clickedUsageBar:(InfinitUsageBar*)sender;

@end
