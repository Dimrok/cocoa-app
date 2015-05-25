//
//  InfinitSettingsBlackView.m
//  InfinitApplication
//
//  Created by Christopher Crone on 23/05/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitSettingsBlackView.h"

#import <Gap/InfinitColor.h>

@implementation InfinitSettingsBlackView

- (void)drawRect:(NSRect)dirtyRect
{
  [[InfinitColor colorWithGray:151] set];
  NSRectFill(dirtyRect);
}

@end
