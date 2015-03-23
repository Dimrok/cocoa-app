//
//  InfinitLineView.m
//  InfinitApplication
//
//  Created by Christopher Crone on 20/03/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitLineView.h"

#import <Gap/InfinitColor.h>

@implementation InfinitLineView

- (void)drawRect:(NSRect)dirtyRect
{
  [[InfinitColor colorWithGray:224] set];
  NSRectFill(dirtyRect);
}

@end
