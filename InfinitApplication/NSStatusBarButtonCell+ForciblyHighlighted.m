//
//  NSStatusBarButtonCell+ForciblyHighlighted.m
//  InfinitApplication
//
//  Created by Christopher Crone on 04/11/14.
//  Copyright (c) 2014 Infinit. All rights reserved.
//

#import "NSStatusBarButtonCell+ForciblyHighlighted.h"

#import <objc/runtime.h>

static char InfinitForciblyHighlightedKey;

static
void
InfinitExchangeImplementations(Class cls, SEL srcSel, SEL dstSel)
{
  Method srcMethod = class_getInstanceMethod(cls, srcSel);
  Method dstMethod = class_getInstanceMethod(cls, dstSel);

  if (class_addMethod(cls, srcSel, method_getImplementation(dstMethod), method_getTypeEncoding(dstMethod)))
  {
    class_replaceMethod(cls, dstSel, method_getImplementation(srcMethod), method_getTypeEncoding(srcMethod));
  }
  else
  {
    method_exchangeImplementations(srcMethod, dstMethod);
  }
}

@implementation NSStatusBarButtonCell(ForciblyHighlighted)

+ (void)load
{
  InfinitExchangeImplementations(self, @selector(isHighlighted), @selector(infinit_highlighted));
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
