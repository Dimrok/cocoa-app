//
//  InfinitInvitationMainView.m
//  InfinitApplication
//
//  Created by Christopher Crone on 23/03/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitInvitationMainView.h"

#import <Gap/InfinitColor.h>

@implementation InfinitInvitationMainView

- (void)drawRect:(NSRect)dirtyRect
{
  [[InfinitColor colorWithGray:248] set];
  NSRectFill(dirtyRect);
}

@end
