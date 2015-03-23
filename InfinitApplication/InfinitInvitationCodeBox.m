//
//  InfinitInvitationCodeBox.m
//  InfinitApplication
//
//  Created by Christopher Crone on 23/03/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitInvitationCodeBox.h"

#import <Gap/InfinitColor.h>

@implementation InfinitInvitationCodeBox

- (void)drawRect:(NSRect)dirtyRect
{
  NSBezierPath* path = [NSBezierPath bezierPathWithRoundedRect:self.bounds
                                                       xRadius:5.0f
                                                       yRadius:5.0f];
  [[InfinitColor colorWithGray:255] set];
  [path fill];
  [[InfinitColor colorWithGray:224] set];
  path.lineWidth = 2.0f;
  [path stroke];
}

@end
