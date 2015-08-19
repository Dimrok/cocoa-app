//
//  NSStatusBarButtonCell+ForciblyHighlighted.m
//  InfinitApplication
//
//  Created by Christopher Crone on 04/11/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "NSStatusBarButtonCell+ForciblyHighlighted.h"

#import <Gap/InfinitSwizzler.h>

static char InfinitForciblyHighlightedKey;

@implementation NSStatusBarButtonCell(ForciblyHighlighted)

+ (void)load
{
  swizzle_class_selector(self, @selector(isHighlighted), @selector(infinit_highlighted));
}


#pragma mark - Accessors

- (void)setForciblyHighlighted:(BOOL)forciblyHighlighted
{
  objc_setAssociatedObject(self, &InfinitForciblyHighlightedKey, @(forciblyHighlighted), OBJC_ASSOCIATION_ASSIGN);

  // Redraw control to apply highlight state
  [self.controlView setNeedsDisplay:YES];
}

- (BOOL)forciblyHighlighted
{
  return [objc_getAssociatedObject(self, &InfinitForciblyHighlightedKey) boolValue];
}


#pragma mark - Getting Highlight State

- (BOOL)infinit_highlighted
{
  return ([self forciblyHighlighted]) ? YES : [self infinit_highlighted];
}

@end
