//
//  InfinitHandButton.m
//  InfinitApplication
//
//  Created by Christopher Crone on 19/08/15.
//  Copyright (c) 2015 Infinit. All rights reserved.
//

#import "InfinitHandButton.h"

@implementation InfinitHandButton

- (void)awakeFromNib
{
  [super awakeFromNib];
  [self.cell setHighlightsBy:NSContentsCellMask];
}

- (void)resetCursorRects
{
  [super resetCursorRects];
  [self addCursorRect:self.bounds cursor:[NSCursor pointingHandCursor]];
}

@end
