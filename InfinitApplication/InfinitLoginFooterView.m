//
//  InfinitLoginFooterView.m
//  InfinitApplication
//
//  Created by Christopher Crone on 19/03/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitLoginFooterView.h"

#import <Gap/InfinitColor.h>

@implementation InfinitLoginFooterView

- (void)drawRect:(NSRect)dirtyRect
{
  NSBezierPath* bg_path = [IAFunctions roundedBottomBezierWithRect:self.bounds cornerRadius:4.0f];
  [[InfinitColor colorWithGray:248] set];
  [bg_path fill];
}

@end
