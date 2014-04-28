//
//  InfinitSearchTokenField.m
//  InfinitApplication
//
//  Created by Christopher Crone on 24/04/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "InfinitSearchTokenField.h"

@implementation InfinitSearchTokenField

- (NSSize)intrinsicContentSize
{
  NSLog(@"xxx called");
  if ( ![self.cell wraps] ) {
    return [super intrinsicContentSize];
  }
  
  NSRect frame = [self frame];
  
  CGFloat width = frame.size.width;
  
  // Make the frame very high, while keeping the width
  frame.size.height = CGFLOAT_MAX;
  
  // Calculate new height within the frame
  // with practically infinite height.
  CGFloat height = [self.cell cellSizeForBounds: frame].height;
  
  return NSMakeSize(width, height);
}

@end
